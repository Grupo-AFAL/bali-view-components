# frozen_string_literal: true

module Bali
  module RichTextEditor
    class Component < ApplicationViewComponent
      attr_reader :options

      def initialize(html_content: nil, editable: false, placeholder: nil, **options)
        @editable = editable
        @html_content = html_content
        @placeholder = placeholder

        @options = prepend_class_name(options,
                                      'rich-text-editor-component rich-editor-content input')
        @options = prepend_controller(@options, 'rich-text-editor')
        @options = prepend_values(@options, 'rich-text-editor', controller_values)
      end

      def controller_values
        {
          content: @html_content || '',
          editable: @editable,
          placeholder: @placeholder || 'Start typing...'
        }
      end

      def editable?
        @editable
      end
    end
  end
end
