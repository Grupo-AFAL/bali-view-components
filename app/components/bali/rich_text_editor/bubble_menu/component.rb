module Bali
  module RichTextEditor
    module BubbleMenu
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = prepend_class_name(options, 'rich-text-editor-menu')
          @options = prepend_data_attribute(options, :rich_text_editor_target, 'bubbleMenu')
        end
      end
    end
  end
end
