# Direct Upload Setup Guide

This guide covers infrastructure requirements for using the DirectUpload component in your Rails application.

---

## Prerequisites

### 1. Active Storage Installation

Run Active Storage migrations if you haven't already:

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

This creates the required tables: `active_storage_blobs`, `active_storage_attachments`, and `active_storage_variant_records`.

---

### 2. Storage Configuration

Configure your storage service in `config/storage.yml`:

```yaml
# Local disk storage (development/test)
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

# Amazon S3 (production)
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: your_bucket_name

# Google Cloud Storage (alternative)
google:
  service: GCS
  project: your_project_name
  credentials: <%= Rails.root.join("path/to/keyfile.json") %>
  bucket: your_bucket_name
```

Set the active service in each environment:

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :amazon  # or :google
```

---

### 3. CORS Configuration (CRITICAL for S3/GCS)

Direct uploads send files directly from the browser to cloud storage. Without proper CORS configuration, uploads will fail silently.

#### AWS S3

Navigate to your S3 bucket → Permissions → Cross-origin resource sharing (CORS), and add:

```json
[
  {
    "AllowedHeaders": [
      "Content-Type",
      "Content-MD5",
      "Content-Disposition",
      "x-amz-acl",
      "x-amz-meta-*"
    ],
    "AllowedMethods": ["PUT", "POST", "GET"],
    "AllowedOrigins": [
      "https://yourdomain.com",
      "http://localhost:3000"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

**Important:** Replace `yourdomain.com` with your actual production domain. Add `localhost:3000` for development if needed.

#### Google Cloud Storage

Using gsutil, set CORS on your bucket:

```bash
cat > cors.json << 'EOF'
[
  {
    "origin": ["https://yourdomain.com", "http://localhost:3000"],
    "method": ["PUT", "POST", "GET"],
    "responseHeader": ["Content-Type", "Content-MD5", "Content-Disposition"],
    "maxAgeSeconds": 3600
  }
]
EOF

gsutil cors set cors.json gs://your-bucket-name
```

---

### 4. JavaScript Setup

Ensure Active Storage JavaScript is loaded in your application:

```javascript
// app/javascript/application.js (or your entry point)
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

If using importmaps:

```ruby
# config/importmap.rb
pin "@rails/activestorage", to: "activestorage.esm.js"
```

The Bali DirectUpload controller is automatically registered when you import Bali components.

---

### 5. Background Job Processor

Active Storage uses background jobs for blob analysis and cleanup. Configure a queue adapter:

```ruby
# config/application.rb (or environment-specific)
config.active_job.queue_adapter = :sidekiq  # or :resque, :delayed_job, :solid_queue
```

Required queues:
- `active_storage_analysis` - Extracting metadata from uploads
- `active_storage_purge` - Cleaning up deleted blobs

---

## Model Configuration

### Defining Attachments

```ruby
class Document < ApplicationRecord
  # Single file attachment
  has_one_attached :file

  # Multiple file attachments
  has_many_attached :images
end
```

### Server-Side Validation (REQUIRED)

**Client-side validation is for UX only.** Always validate on the server for security.

Using the `active_storage_validations` gem (recommended):

```ruby
# Gemfile
gem 'active_storage_validations'
```

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  # Validate content type (REQUIRED for security)
  validates :file, content_type: [
    'application/pdf',
    'image/png',
    'image/jpeg'
  ]

  # Validate file size
  validates :file, size: { less_than: 10.megabytes }

  # Validate image dimensions (optional)
  validates :cover_image, dimension: {
    width: { min: 800, max: 2400 },
    height: { min: 600, max: 1800 }
  }
end
```

Without the gem, use custom validation:

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    # Validate content type
    acceptable_types = ['application/pdf', 'image/png', 'image/jpeg']
    unless acceptable_types.include?(file.content_type)
      errors.add(:file, 'must be a PDF, PNG, or JPEG')
    end

    # Validate file size
    if file.byte_size > 10.megabytes
      errors.add(:file, 'is too large (max 10MB)')
    end
  end
end
```

---

## Using the Component

### Basic Usage

```erb
<%= form_with model: @document do |f| %>
  <%= render Bali::DirectUpload::Component.new(
    form: f,
    method: :file
  ) %>

  <%= f.submit 'Upload', class: 'btn btn-primary' %>
<% end %>
```

### Multiple Files

```erb
<%= render Bali::DirectUpload::Component.new(
  form: f,
  method: :images,
  multiple: true,
  max_files: 5,
  max_file_size: 10  # MB
) %>
```

### With File Type Restrictions

```erb
<%= render Bali::DirectUpload::Component.new(
  form: f,
  method: :document,
  accept: 'application/pdf,image/*'
) %>
```

### Without Drop Zone (Simple Button)

```erb
<%= render Bali::DirectUpload::Component.new(
  form: f,
  method: :file,
  drop_zone: false
) %>
```

### Component Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `form` | FormBuilder | **required** | Rails form builder object |
| `method` | Symbol | **required** | Attachment attribute name |
| `multiple` | Boolean | `false` | Allow multiple files |
| `max_files` | Integer | `10` | Maximum files (when multiple) |
| `max_file_size` | Integer | `10` | Max file size in MB |
| `accept` | String | `*` | Accepted MIME types or extensions |
| `drop_zone` | Boolean | `true` | Show drag & drop area |
| `auto_upload` | Boolean | `true` | Upload immediately on selection |

---

## Built-in Features

### Existing Attachments Display

When editing a record with existing attachments, the component automatically displays them with a remove button. Users can mark files for removal without immediately deleting them.

To process removals in your controller:

```ruby
class DocumentsController < ApplicationController
  def update
    @document = Document.find(params[:id])

    # Handle file removals
    if params[:document][:remove_file].present?
      params[:document][:remove_file].each do |attachment_id|
        attachment = @document.file.find { |a| a.id.to_s == attachment_id }
        attachment&.purge_later
      end
    end

    if @document.update(document_params)
      redirect_to @document
    else
      render :edit
    end
  end

  private

  def document_params
    params.require(:document).permit(:title, :file, images: [], remove_file: [], remove_images: [])
  end
end
```

### Form Submission Guard

The component automatically prevents form submission while uploads are in progress. Users see an error message if they try to submit before uploads complete.

This is built-in - no configuration needed.

### Error Display

Validation errors (file too large, wrong type, too many files) are shown in a visible alert at the top of the component. Errors auto-dismiss after 5 seconds or can be manually closed.

### Events

The component dispatches custom events you can listen to:

| Event | Detail | Description |
|-------|--------|-------------|
| `direct-upload:error` | `{ message }` | Validation or upload error |
| `direct-upload:complete` | `{ id, filename, signedId }` | Single file upload completed |
| `direct-upload:all-complete` | `{ count }` | All pending uploads finished |

```javascript
// Listen for completion in your own controller
element.addEventListener('direct-upload:all-complete', (event) => {
  console.log(`All ${event.detail.count} files uploaded`)
})
```

---

## Orphan Blob Cleanup

### The Problem

When users upload files but don't save the form (navigation, validation failure, browser close), blobs are created in storage but never attached to a model. These "orphan blobs" accumulate over time.

### Solution: Scheduled Cleanup Task

Create a rake task in your application:

```ruby
# lib/tasks/active_storage.rake
namespace :active_storage do
  desc "Purge unattached blobs older than 2 days"
  task purge_unattached: :environment do
    # Find blobs that were never attached and are older than 2 days
    # The 2-day grace period ensures we don't delete blobs for forms
    # that are still being filled out or pending submission
    ActiveStorage::Blob.unattached
      .where(created_at: ..2.days.ago)
      .find_each do |blob|
        puts "Purging blob: #{blob.filename} (#{blob.byte_size} bytes)"
        blob.purge_later
      end
  end
end
```

### Schedule with Cron

Run daily during off-peak hours:

```bash
# crontab -e
0 3 * * * cd /path/to/app && bin/rails active_storage:purge_unattached
```

Or with whenever gem:

```ruby
# config/schedule.rb
every 1.day, at: '3:00 am' do
  rake 'active_storage:purge_unattached'
end
```

### Monitoring

Track orphan blob count:

```ruby
# In a monitoring rake task or dashboard
orphan_count = ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).count
puts "Orphan blobs pending cleanup: #{orphan_count}"
```

---

## Security Considerations

### 1. Authenticate Direct Upload Endpoint

By default, anyone can upload files. Add authentication:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Authenticate direct uploads
  constraints ->(request) { request.session[:user_id].present? } do
    scope "/rails/active_storage" do
      post "/direct_uploads", to: "active_storage/direct_uploads#create"
    end
  end
end
```

Or with Devise:

```ruby
# app/controllers/concerns/authenticated_direct_uploads.rb
module AuthenticatedDirectUploads
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: :create
  end
end

# config/initializers/active_storage_authentication.rb
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.include(AuthenticatedDirectUploads)
end
```

### 2. Server-Side Validation

**Never trust client-side validation alone.** The `accept` parameter only filters the file picker UI—attackers can bypass it easily.

Always validate:
- Content type (MIME type)
- File size
- Image dimensions (if applicable)

### 3. Content-Type Sniffing

Consider using a gem like `marcel` (included with Active Storage) to detect actual file types:

```ruby
# Marcel detects content type from file contents, not extension
detected_type = Marcel::MimeType.for(file.download, name: file.filename.to_s)
```

### 4. Filename Sanitization

Active Storage sanitizes filenames automatically, but be careful when displaying them:

```erb
<%# Safe - escapes HTML %>
<%= @document.file.filename %>

<%# Dangerous - raw output %>
<%== @document.file.filename %>
```

---

## Related Documentation

- [Troubleshooting Guide](./direct-upload-troubleshooting.md) - Common issues and solutions
- [External Services Guide](./external-services.md) - General cloud storage setup
- [Active Storage Guide](https://edgeguides.rubyonrails.org/active_storage_overview.html) - Official Rails documentation
