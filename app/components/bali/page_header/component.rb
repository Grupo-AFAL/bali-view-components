# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :title, ->(text = nil, tag: :h3, **options, &block) do
        options = prepend_class_name(
          options,
          class_names('title is-spaced', heading_size_class(tag))
        )

        heading_tag(text, tag, **options, &block)
      end

      renders_one :subtitle, ->(text = nil, tag: :h5, **options, &block) do
        options = prepend_class_name(options, class_names('subtitle', heading_size_class(tag)))

        heading_tag(text, tag, **options, &block)
      end

      def initialize(title: nil, subtitle: nil, align: :center, back: {}, **options)
        @title = title
        @subtitle = subtitle
        @align = align

        @options = prepend_class_name(options, 'page-header-component is-mobile')
        @back_options = prepend_class_name(back, 'back-button button is-text')

        @left_options = {}
        if align == :top
          @left_options = prepend_class_name(@left_options, 'is-align-items-flex-start')
          @options = prepend_class_name(options, 'is-align-items-flex-start')
        end
        if align == :bottom
          @left_options = prepend_class_name(@left_options, 'is-align-items-flex-end')
          @options = prepend_class_name(options, 'is-align-items-flex-end')
        end
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
        text.present? ? tag.send(tag_name, text, **options) : tag.send(tag_name, **options, &)
      end
    end
  end
end
