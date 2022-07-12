# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :title, ->(text = nil, tag: :h3, **options, &block) do
        options = prepend_class_name(options, class_names('title', heading_size_class(tag)))

        heading_tag(text, tag, **options, &block)
      end

      renders_one :subtitle, ->(text = nil, tag: :h5, **options, &block) do
        options = prepend_class_name(options, class_names('subtitle', heading_size_class(tag)))

        heading_tag(text, tag, **options, &block)
      end

      def initialize(title: nil, subtitle: nil, **options)
        @title = title
        @subtitle = subtitle
        @options = prepend_class_name(options, 'page-header-component is-mobile')
      end

      def heading_size_class(tag)
        {
          'is-1': tag == :h1,
          'is-2': tag == :h2,
          'is-3': tag == :h3,
          'is-4': tag == :h4,
          'is-5': tag == :h5,
          'is-6': tag == :h6
        }
      end

      def heading_tag(text, tag_name, **options, &)
        text.present? ? tag.send(tag_name, text, **options) : tag.div(&)
      end
    end
  end
end
