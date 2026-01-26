# Direct Upload Troubleshooting Guide

Common issues and solutions for the DirectUpload component.

---

## CORS Errors

### Symptoms

- Uploads fail silently (no progress, immediate error)
- Browser console shows: `Access to XMLHttpRequest has been blocked by CORS policy`
- Network tab shows failed PUT/POST requests to storage URL

### Diagnosis

1. Open browser DevTools → Network tab
2. Attempt an upload
3. Look for requests to your storage URL (S3/GCS) with status `0` or `CORS error`

### Solutions

#### AWS S3

1. Go to S3 Console → Your Bucket → Permissions → CORS configuration
2. Add or update the CORS rules:

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
      "https://yourdomain.com"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

3. **Wait 5-10 minutes** for CORS changes to propagate
4. Clear browser cache or test in incognito mode

#### Google Cloud Storage

```bash
# Create cors.json
cat > cors.json << 'EOF'
[
  {
    "origin": ["https://yourdomain.com"],
    "method": ["PUT", "POST", "GET"],
    "responseHeader": ["Content-Type", "Content-MD5", "Content-Disposition"],
    "maxAgeSeconds": 3600
  }
]
EOF

# Apply to bucket
gsutil cors set cors.json gs://your-bucket-name

# Verify
gsutil cors get gs://your-bucket-name
```

#### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing trailing slash in origin | Don't include trailing slash: `https://example.com` not `https://example.com/` |
| Wrong protocol | Include both `http://` and `https://` if needed |
| Missing development origin | Add `http://localhost:3000` for local testing |
| Not waiting for propagation | Wait 5-10 minutes after CORS changes |

---

## Upload Failures

### "Upload failed" Error

**Possible causes:**

1. **Network interruption** - User's connection dropped
2. **URL expiration** - Signed URL expired before upload completed
3. **File too large** - Exceeds server or storage limits
4. **Authentication failure** - Direct upload endpoint not authenticated

**Solutions:**

For network issues:
- User can click the retry button
- Consider informing users about stable connections for large files

For URL expiration (signed URLs expire in ~1 hour by default):
```ruby
# config/environments/production.rb
# Increase expiration for large file uploads
config.active_storage.service_urls_expire_in = 2.hours
```

For file size limits:
```ruby
# Check Nginx config (if applicable)
client_max_body_size 100M;

# Check Rails config
Rails.application.config.active_storage.web_container_max_size = 100.megabytes
```

### Progress Stuck at 0%

**Causes:**
- CORS error (see above)
- JavaScript not loaded properly
- Stimulus controller not registered

**Diagnosis:**
```javascript
// In browser console
Stimulus.debug = true
// Then attempt upload and look for controller connection messages
```

**Solutions:**

Check that Active Storage JS is loaded:
```javascript
// Should not throw error
console.log(typeof ActiveStorage !== 'undefined')
```

Check that the controller is registered:
```javascript
// Should show 'direct-upload' controller
console.log(Stimulus.application.controllers.map(c => c.identifier))
```

### File Type Not Accepted

**Symptom:** Error message "File type not accepted" even for valid files

**Causes:**
- Browser reports different MIME type than expected
- Extension doesn't match MIME type

**Solution:** Use multiple accept patterns:

```erb
<%# Accept both MIME types and extensions %>
<%= render Bali::DirectUpload::Component.new(
  form: f,
  method: :document,
  accept: 'application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png'
) %>
```

---

## Files Not Attaching to Model

### Hidden Field Empty

**Symptom:** Form submits but attachment is nil

**Diagnosis:**
1. Open DevTools → Elements
2. Find the `hiddenFields` container in the component
3. Check if it contains `<input type="hidden">` elements with signed IDs

**If hidden fields are empty:**
- Upload didn't complete successfully
- Check browser console for errors

**If hidden fields exist but attachment is nil:**
- Check controller params
- Verify the attribute is permitted

```ruby
# Controller
def document_params
  params.require(:document).permit(:title, :file)  # :file for single
  # or
  params.require(:document).permit(:title, images: [])  # images: [] for multiple
end
```

### Validation Errors Not Showing

**Symptom:** Form appears to fail but no errors displayed

The upload is client-side, so validation errors only appear after form submission:

```erb
<%= form_with model: @document do |f| %>
  <%# Show validation errors %>
  <% if @document.errors[:file].any? %>
    <div class="alert alert-error mb-4">
      <%= @document.errors[:file].to_sentence %>
    </div>
  <% end %>

  <%= render Bali::DirectUpload::Component.new(form: f, method: :file) %>
  <%= f.submit %>
<% end %>
```

### Form Submitted During Upload

**Symptom:** Random behavior - sometimes attachment saves, sometimes nil

**Cause:** User clicks submit before upload completes

**Solutions:**

1. Disable submit button until uploads complete:

```erb
<%= f.submit 'Save', data: { direct_upload_target: 'submitButton' } %>
```

```javascript
// In a custom controller that extends or listens to direct-upload
handleUploadStart() {
  this.submitButtonTarget.disabled = true
  this.submitButtonTarget.textContent = 'Uploading...'
}

handleUploadComplete() {
  this.submitButtonTarget.disabled = false
  this.submitButtonTarget.textContent = 'Save'
}
```

2. Or prevent form submission while uploads are pending (add to your form controller):

```javascript
submitForm(event) {
  const pendingUploads = this.element.querySelectorAll('[data-file-id]').length
  const completedUploads = this.element.querySelectorAll('.file-success:not(.hidden)').length

  if (pendingUploads > completedUploads) {
    event.preventDefault()
    alert('Please wait for uploads to complete')
  }
}
```

---

## Orphaned Files

### Identifying Orphan Blobs

```ruby
# Rails console
orphans = ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago)
puts "Found #{orphans.count} orphan blobs"
puts "Total size: #{orphans.sum(:byte_size) / 1.megabyte} MB"
```

### Manual Cleanup

```ruby
# Purge specific blobs
ActiveStorage::Blob.unattached
  .where(created_at: ..2.days.ago)
  .find_each(&:purge_later)
```

### Automated Cleanup

See [Direct Upload Setup Guide](./direct-upload-setup.md#orphan-blob-cleanup) for setting up scheduled cleanup.

---

## Storage-Specific Issues

### AWS S3

#### "Access Denied" on Upload

1. Check IAM permissions for the user/role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

2. Check bucket policy doesn't explicitly deny

3. Verify credentials in Rails:
```ruby
Rails.application.credentials.dig(:aws, :access_key_id)
# Should return your key
```

#### "SignatureDoesNotMatch"

- Check that server time is synchronized (NTP)
- Verify secret key is correct and has no trailing whitespace

### Google Cloud Storage

#### "Invalid Credentials"

1. Verify service account key file exists and is valid JSON
2. Check service account has `Storage Object Admin` role
3. Ensure key file path is correct in `storage.yml`

### Local Development

#### Files Disappearing

**Cause:** `tmp/storage` or `storage/` directory deleted

**Prevention:**
```bash
# Add to .gitignore but not delete
storage/
tmp/storage/
```

---

## Performance Issues

### Large File Uploads Slow

Direct uploads go from browser → storage, bypassing your server. Slowness is usually:

1. **User's upload bandwidth** - Not much you can do
2. **Geographic distance** - Use CDN or regional buckets
3. **File size** - Consider chunked uploads for very large files

### Memory Issues with Many Files

**Symptom:** Browser becomes sluggish with many simultaneous uploads

**Solution:** Limit concurrent uploads (the component handles this via `max_files`):

```erb
<%= render Bali::DirectUpload::Component.new(
  form: f,
  method: :images,
  multiple: true,
  max_files: 5  # Reduce if needed
) %>
```

---

## Debugging Tips

### Enable Verbose Logging

```javascript
// In browser console before uploading
localStorage.setItem('debug', 'direct-upload:*')
// Reload page
```

### Check Network Requests

1. DevTools → Network tab
2. Filter by "XHR" or "Fetch"
3. Look for:
   - `POST /rails/active_storage/direct_uploads` - Creates signed URL
   - `PUT https://storage.../` - Actual file upload

### Inspect Component State

```javascript
// Get the controller instance
const element = document.querySelector('[data-controller="direct-upload"]')
const controller = Stimulus.getControllerForElementAndIdentifier(element, 'direct-upload')

// Inspect files map
console.log(controller.files)
```

### Server-Side Debugging

```ruby
# config/environments/development.rb
config.active_storage.logger = Logger.new(STDOUT)
```

---

## Known Limitations

| Limitation | Description | Workaround |
|------------|-------------|------------|
| No resumable uploads | If upload fails, it restarts from 0% | Use smaller files or improve connection |
| No chunked uploads | Single PUT request for entire file | Consider separate chunking solution for files >1GB |
| Client validation is UX only | Attackers can bypass `accept` parameter | Always validate server-side |
| No offline queuing | Uploads require active connection | Inform users to maintain connection |
| URL expiration | Signed URLs expire (~1 hour default) | Increase expiration for large files |

---

## Related Documentation

- [Direct Upload Setup Guide](./direct-upload-setup.md) - Infrastructure configuration
- [Active Storage Guide](https://edgeguides.rubyonrails.org/active_storage_overview.html) - Official Rails documentation
- [AWS S3 CORS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html) - AWS documentation
- [GCS CORS](https://cloud.google.com/storage/docs/cross-origin) - Google Cloud documentation
