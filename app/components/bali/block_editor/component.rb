# frozen_string_literal: true

module Bali
  module BlockEditor
    class Component < ApplicationViewComponent
      attr_reader :input_name, :images_url, :options

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        initial_content: nil,
        html_content: nil,
        input_name: nil,
        format: :json,
        editable: true,
        placeholder: nil,
        images_url: :auto,
        theme: :light,
        export: false,
        export_filename: 'document',
        ai_url: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @initial_content = initial_content
        @html_content = html_content
        @input_name = input_name
        @format = format
        @editable = editable
        @placeholder = placeholder
        @images_url_auto = (images_url == :auto)
        @images_url = images_url == :auto ? nil : images_url
        @theme = theme
        @export = export
        @export_filename = export_filename
        @ai_url = ai_url

        @options = prepend_class_name(options, 'block-editor-component')
        @options = prepend_controller(@options, 'block-editor')
        @options = prepend_values(@options, 'block-editor', controller_values)
      end

      # Resolve images_url at render time (not in initialize) because
      # engine route helpers require the view context which is only available here.
      def before_render
        return unless @images_url_auto && editable?

        resolved = Bali.block_editor_upload_url || resolve_engine_upload_path
        return unless resolved

        @images_url = resolved
        @options[:data] ||= {}
        @options[:data][:'block-editor-images-url-value'] = resolved
      end

      def editable?
        @editable
      end

      def export_enabled?
        @export.present? && @export != false
      end

      def export_pdf?
        @export == true || Array(@export).map(&:to_sym).include?(:pdf)
      end

      def export_docx?
        @export == true || Array(@export).map(&:to_sym).include?(:docx)
      end

      def render?
        Bali.block_editor_enabled
      end

      private

      def controller_values
        {
          initial_content: serialized_content,
          html_content: @html_content || '',
          format: @format.to_s,
          editable: @editable,
          placeholder: @placeholder || '',
          images_url: @images_url,
          theme: @theme.to_s,
          export_filename: @export_filename,
          ai_url: @ai_url || ''
        }
      end

      def resolve_engine_upload_path
        helpers.bali.block_editor_uploads_path
      rescue NoMethodError
        nil
      end

      def serialized_content
        case @initial_content
        when Hash, Array
          @initial_content.to_json
        when String
          @initial_content
        else
          ''
        end
      end
    end
  end
end
