# frozen_string_literal: true

module Bali
  class BlockEditorUploadsController < ApplicationController
    ALLOWED_CONTENT_TYPES = [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'application/pdf',
      'text/plain', 'text/markdown', 'text/csv',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/zip'
    ].freeze

    BLOCKED_EXTENSIONS = %w[
      .exe .bat .cmd .com .msi .scr .pif .vbs .vbe .js .jse .wsf .wsh .ps1 .sh .rb .py .pl
    ].freeze

    MAX_FILE_SIZE = 10.megabytes

    def create
      authorize_upload!
      file = params.require(:file)
      validate_file!(file)

      if Bali.block_editor_upload_handler
        url = Bali.block_editor_upload_handler.call(file, self)
        raise UploadError, 'Upload handler returned no URL' if url.blank?
        unless url.is_a?(String) && (url.start_with?('/') || url.match?(%r{\Ahttps?://}i))
          raise UploadError, 'Upload handler returned an invalid URL'
        end

        render json: { url: url }
      elsif defined?(ActiveStorage)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file.open,
          filename: ActiveStorage::Filename.new(file.original_filename).sanitized,
          content_type: file.content_type,
          identify: true
        )
        url = main_app.rails_blob_path(blob, disposition: :inline)
        render json: { url: url }
      else
        render json: { error: 'File uploads are not available' },
               status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render json: { error: 'No file provided' }, status: :unprocessable_entity
    rescue UploadError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue NotAuthorizedError
      render json: { error: 'Not authorized' }, status: :forbidden
    end

    private

    class UploadError < StandardError; end
    class NotAuthorizedError < StandardError; end

    def authorize_upload!
      return unless Bali.block_editor_upload_authorize

      raise NotAuthorizedError unless Bali.block_editor_upload_authorize.call(self)
    end

    def validate_file!(file)
      allowed = Bali.block_editor_allowed_upload_types || ALLOWED_CONTENT_TYPES
      max_size = Bali.block_editor_max_upload_size || MAX_FILE_SIZE

      # Use magic-byte detection via Marcel (bundled with Active Storage) when available,
      # falling back to client-declared content_type
      detected_type = if defined?(Marcel)
                        Marcel::MimeType.for(file.tempfile, name: file.original_filename)
                      else
                        file.content_type
                      end

      unless allowed.include?(detected_type)
        raise UploadError, "File type '#{detected_type}' is not allowed"
      end

      ext = File.extname(file.original_filename).downcase
      if BLOCKED_EXTENSIONS.include?(ext)
        raise UploadError, "File extension '#{ext}' is not allowed"
      end

      return unless file.size > max_size

      max_mb = (max_size.to_f / 1.megabyte).round(1)
      raise UploadError, "File size exceeds maximum of #{max_mb}MB"
    end
  end
end
