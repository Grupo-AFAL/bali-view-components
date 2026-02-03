# frozen_string_literal: true

module Bali
  module DirectUpload
    # Direct upload component for uploading files directly to cloud storage.
    #
    # Uses Active Storage's DirectUpload API to upload files from the browser
    # directly to cloud storage (S3, GCS, Azure) without passing through
    # your Rails server.
    #
    # @example Basic usage
    #   <%= form_with model: @document do |f| %>
    #     <%= render Bali::DirectUpload::Component.new(form: f, method: :file) %>
    #   <% end %>
    #
    # @example Multiple files
    #   <%= render Bali::DirectUpload::Component.new(
    #     form: f,
    #     method: :images,
    #     multiple: true,
    #     max_files: 5
    #   ) %>
    #
    # @example With file type restrictions
    #   <%= render Bali::DirectUpload::Component.new(
    #     form: f,
    #     method: :document,
    #     accept: 'application/pdf,image/*'
    #   ) %>
    #
    # @see docs/guides/direct-upload-setup.md Full setup guide
    # @see docs/guides/direct-upload-troubleshooting.md Troubleshooting
    #
    # @note CORS must be configured on your storage bucket for direct uploads to work.
    # @note Client-side validation is for UX only. Always validate on the server.
    class Component < ApplicationViewComponent
      DEFAULT_MAX_FILES = 10
      DEFAULT_MAX_FILE_SIZE_MB = 10

      attr_reader :form, :method, :options

      # Initialize a new DirectUpload component.
      #
      # @param form [ActionView::Helpers::FormBuilder] Rails form builder object
      # @param method [Symbol] Attachment attribute name (e.g., :file, :images)
      # @param multiple [Boolean] Allow multiple file selection
      # @param max_files [Integer] Maximum number of files (when multiple: true)
      # @param max_file_size [Integer] Maximum file size in megabytes
      # @param accept [String] Accepted file types (MIME types or extensions)
      # @param drop_zone [Boolean] Show drag & drop area
      # @param auto_upload [Boolean] Upload files immediately on selection
      # @param options [Hash] Additional options passed to the container element
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(form:, method:, multiple: false, max_files: DEFAULT_MAX_FILES,
                     max_file_size: DEFAULT_MAX_FILE_SIZE_MB, accept: '*', drop_zone: true,
                     auto_upload: true, **options)
        @form = form
        @method = method
        @multiple = multiple
        @max_files = max_files
        @max_file_size = max_file_size
        @accept = accept
        @drop_zone = drop_zone
        @auto_upload = auto_upload
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def multiple?
        @multiple
      end

      def drop_zone?
        @drop_zone
      end

      def auto_upload?
        @auto_upload
      end

      # Returns existing attachments for the form object's attachment method.
      # Used to display currently attached files when editing a record.
      #
      # @return [Array<ActiveStorage::Attachment>] Array of existing attachments
      def existing_attachments
        return [] unless form.object.respond_to?(method)

        attachment = form.object.public_send(method)
        return [] if attachment.blank?

        # Handle both has_one_attached and has_many_attached
        if attachment.respond_to?(:each)
          attachment.to_a
        else
          [attachment]
        end
      end

      private

      attr_reader :max_files, :max_file_size, :accept

      def container_options
        opts = options.except(:class)
        opts[:class] = container_classes
        opts[:data] = container_data
        opts
      end

      def container_classes
        class_names(
          'direct-upload-component',
          options[:class]
        )
      end

      def container_data
        {
          controller: 'direct-upload',
          direct_upload_url_value: direct_upload_url,
          direct_upload_multiple_value: multiple?,
          direct_upload_max_files_value: max_files,
          direct_upload_max_file_size_value: max_file_size,
          direct_upload_accept_value: accept,
          direct_upload_auto_upload_value: auto_upload?,
          direct_upload_field_name_value: field_name,
          direct_upload_remove_field_name_value: remove_field_name
        }
      end

      def direct_upload_url
        Rails.application.routes.url_helpers.rails_direct_uploads_path
      end

      def field_name
        if form.object_name.present?
          multiple? ? "#{form.object_name}[#{method}][]" : "#{form.object_name}[#{method}]"
        else
          multiple? ? "#{method}[]" : method.to_s
        end
      end

      # Field name for marking existing attachments for removal.
      # Used when user clicks remove on an existing attachment.
      def remove_field_name
        if form.object_name.present?
          "#{form.object_name}[remove_#{method}][]"
        else
          "remove_#{method}[]"
        end
      end

      def input_options
        {
          type: 'file',
          multiple: multiple?,
          accept: accept,
          class: 'hidden',
          data: {
            direct_upload_target: 'input',
            action: 'direct-upload#selectFiles'
          }
        }
      end

      def dropzone_classes
        class_names(
          'border-2 border-dashed border-base-300 rounded-box p-8 text-center',
          'hover:border-primary hover:bg-base-200/50 transition-colors cursor-pointer',
          'dropzone-active:border-primary dropzone-active:bg-primary/10'
        )
      end

      def dropzone_data
        {
          direct_upload_target: 'dropzone',
          action: [
            'dragenter->direct-upload#dragenter',
            'dragover->direct-upload#dragover',
            'dragleave->direct-upload#dragleave',
            'drop->direct-upload#drop',
            'click->direct-upload#openFilePicker',
            'keydown->direct-upload#dropzoneKeydown'
          ].join(' ')
        }
      end
    end
  end
end
