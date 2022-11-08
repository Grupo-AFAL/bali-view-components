# frozen_string_literal: true

module Bali
  module RichTextEditor
    class Component < ApplicationViewComponent
      attr_reader :options

      def initialize(html_content: nil, editable: false, **options)
        @options = prepend_class_name(options,
                                      'rich-text-editor-component rich-editor-content input')
        @options = prepend_controller(@options, 'rich-text-editor')
        @options = prepend_values(@options, 'rich-text-editor',
                                  { content: html_content, editable: editable })
      end
    end
  end
end
