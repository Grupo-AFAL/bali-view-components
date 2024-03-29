# frozen_string_literal: true

module Bali
  module RichTextEditor
    module BubbleMenu
      class Component < ApplicationViewComponent
        attr_reader :images_url

        renders_many :page_hyperlink_options, PageHyperlinkOption::Component

        def initialize(images_url: nil, **options)
          @images_url = images_url

          @options = prepend_class_name(options, 'rich-text-editor-menu')
          @options = prepend_data_attribute(options, :rich_text_editor_target, 'bubbleMenu')
        end
      end
    end
  end
end
