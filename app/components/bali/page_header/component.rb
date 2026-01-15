# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      HEADING_SIZES = {
        h1: 'text-4xl',
        h2: 'text-3xl',
        h3: 'text-2xl',
        h4: 'text-xl',
        h5: 'text-lg',
        h6: 'text-base'
      }.freeze

      attr_reader :options

      renders_one :title, ->(text = nil, tag: :h3, **options, &block) do
        options = prepend_class_name(
          options,
          class_names('title font-bold mb-1', HEADING_SIZES[tag])
        )

        heading_tag(text, tag, **options, &block)
      end

      renders_one :subtitle, ->(text = nil, tag: :h5, **options, &block) do
        subtitle_classes = class_names('subtitle text-base-content/60', HEADING_SIZES[tag])
        options = prepend_class_name(options, subtitle_classes)

        heading_tag(text, tag, **options, &block)
      end

      def initialize(title: nil, subtitle: nil, align: :center, back: {}, **options)
        @title = title
        @subtitle = subtitle
        @align = align

        @options = prepend_class_name(options, 'page-header-component')
        @back_options = prepend_class_name(back, 'back-button btn btn-ghost size-9 text-primary')

        @left_options = {}

        if align == :top
          @left_options = prepend_class_name(@left_options, 'items-start')
          @options = prepend_class_name(options, 'items-start')
        end

        return unless align == :bottom

        @left_options = prepend_class_name(@left_options, 'items-end')
        @options = prepend_class_name(options, 'items-end')
      end

      def heading_tag(text, tag_name, **, &)
        text.present? ? tag.send(tag_name, text, **) : tag.send(tag_name, **, &)
      end
    end
  end
end
