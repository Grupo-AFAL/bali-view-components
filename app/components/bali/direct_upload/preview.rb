# frozen_string_literal: true

module Bali
  module DirectUpload
    # Direct upload component for uploading files directly to cloud storage (S3/GCS)
    # using Active Storage's DirectUpload API.
    #
    # ## Setup Required
    #
    # Before using this component, your application needs:
    # 1. Active Storage installed (`bin/rails active_storage:install`)
    # 2. Storage service configured in `config/storage.yml`
    # 3. **CORS configured on your storage bucket** (required for S3/GCS)
    # 4. Background job processor (Sidekiq, etc.) for blob cleanup
    #
    # See `docs/guides/direct-upload-setup.md` for complete setup instructions.
    #
    # ## Security
    #
    # **Client-side validation is for UX only.** Always validate on the server:
    # ```ruby
    # validates :file, content_type: ['image/png', 'application/pdf'],
    #                  size: { less_than: 10.megabytes }
    # ```
    #
    # ## Orphan Cleanup
    #
    # Files uploaded but not attached (user navigates away, validation fails)
    # become "orphan blobs". Set up a scheduled task to clean them.
    # See `docs/guides/direct-upload-setup.md#orphan-blob-cleanup`.
    class Preview < ApplicationViewComponentPreview
      # @!group Basic Usage

      # Default direct upload with drag & drop zone.
      # Files are uploaded immediately on selection.
      #
      # The hidden field is populated with the blob's `signed_id` after upload,
      # which Rails uses to attach the file when the form is submitted.
      def default
        render_with_template
      end

      # Multiple file upload with configurable limits.
      # Allows up to 5 files, each max 10MB.
      #
      # For multiple attachments, use `has_many_attached` in your model
      # and permit an array in your controller: `params.permit(images: [])`.
      def multiple
        render_with_template
      end

      # @!endgroup

      # @!group Configuration

      # Without drag & drop zone.
      # Shows only a browse button for simpler UIs.
      #
      # Use `drop_zone: false` when:
      # - Space is limited
      # - Drag & drop doesn't fit the UX
      # - Mobile-first design (drag & drop is less useful)
      def without_dropzone
        render_with_template
      end

      # With file type restrictions.
      # Only accepts images and PDFs.
      #
      # The `accept` parameter filters the file picker UI.
      # **This is not security** - always validate content type server-side.
      #
      # Accepts both MIME types and extensions:
      # - `image/*` - All images
      # - `application/pdf` - PDFs only
      # - `.doc,.docx` - Word documents by extension
      def with_accept_filter
        render_with_template
      end

      # @!endgroup
    end
  end
end
