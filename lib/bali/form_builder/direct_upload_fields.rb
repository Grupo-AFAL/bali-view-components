# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DirectUploadFields
      # Renders a direct upload field with optional FieldGroupWrapper
      #
      # @example Basic usage
      #   <%= form.direct_upload_field_group :attachment, label: 'Upload File' %>
      #
      # @example Multiple files
      #   <%= form.direct_upload_field_group :attachments, multiple: true, max_files: 5 %>
      #
      def direct_upload_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          direct_upload_field(method, options)
        end
      end

      # Renders a direct upload field without wrapper
      #
      # @param method [Symbol] The model attribute name
      # @param options [Hash] Configuration options
      # @option options [Boolean] :multiple (false) Allow multiple files
      # @option options [Integer] :max_files (10) Maximum files when multiple
      # @option options [Integer] :max_file_size (10) Max file size in MB
      # @option options [String] :accept ('*') Accepted MIME types or extensions
      # @option options [Boolean] :drop_zone (true) Show drag & drop zone
      # @option options [Boolean] :auto_upload (true) Upload immediately on selection
      #
      # @example Single file
      #   <%= form.direct_upload_field :attachment %>
      #
      # @example Multiple files with restrictions
      #   <%= form.direct_upload_field :documents, multiple: true, accept: 'image/*,.pdf' %>
      #
      def direct_upload_field(method, options = {})
        @template.render(
          Bali::DirectUpload::Component.new(
            form: self,
            method: method,
            **direct_upload_options(options)
          )
        )
      end

      private

      def direct_upload_options(options)
        {
          multiple: options.fetch(:multiple, false),
          max_files: options.fetch(:max_files, 10),
          max_file_size: options.fetch(:max_file_size, 10),
          accept: options.fetch(:accept, '*'),
          drop_zone: options.fetch(:drop_zone, true),
          auto_upload: options.fetch(:auto_upload, true),
          class: options[:class]
        }.compact
      end
    end
  end
end
