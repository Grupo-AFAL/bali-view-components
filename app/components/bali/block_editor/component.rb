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
        images_url: nil,
        theme: :light,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @initial_content = initial_content
        @html_content = html_content
        @input_name = input_name
        @format = format
        @editable = editable
        @placeholder = placeholder
        @images_url = images_url
        @theme = theme

        @options = prepend_class_name(options, 'block-editor-component')
        @options = prepend_controller(@options, 'block-editor')
        @options = prepend_values(@options, 'block-editor', controller_values)
      end

      def editable?
        @editable
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
          theme: @theme.to_s
        }
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
