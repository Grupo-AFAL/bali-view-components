# frozen_string_literal: true

module Bali
  module RichTextEditor
    class Component < ApplicationViewComponent
      attr_reader :html_content, :output_input_name, :images_url, :options

      def initialize(
        html_content: nil,
        output_input_name: nil,
        editable: false,
        placeholder: nil,
        images_url: nil,
        **options
      )
        @editable = editable
        @html_content = html_content
        @placeholder = placeholder
        @output_input_name = output_input_name
        @images_url = images_url

        @options = prepend_class_name(options,
                                      'rich-text-editor-component rich-editor-content input')
        @options = prepend_controller(@options, 'rich-text-editor')
        @options = prepend_values(@options, 'rich-text-editor', controller_values)
      end

      def controller_values
        {
          content: @html_content || '',
          editable: @editable,
          placeholder: @placeholder || 'Start typing...',
          images_url: @images_url
        }
      end

      def editable?
        @editable
      end
    end
  end
end
