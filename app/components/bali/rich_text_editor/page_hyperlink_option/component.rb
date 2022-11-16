module Bali
  module RichTextEditor
    module PageHyperlinkOption
      class Component < ApplicationViewComponent
        attr_reader :title, :id, :url, :options

        def initialize(title:, id: , url: , **options)
          @title = title
          @id = id
          @url = url

          @options = prepend_class_name(options, 'page-link')
          @options = prepend_action(@options, 'click->rich-text-editor#savePageLink')
          @options = prepend_data_attribute(@options, 'id', id)
          @options = prepend_data_attribute(@options, 'url', url)
        end

        def call
          tag.a title, **options
        end
      end
    end
  end
end