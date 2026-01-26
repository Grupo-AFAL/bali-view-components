# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'page-header-component'

      HEADING_SIZES = {
        h1: 'text-4xl',
        h2: 'text-3xl',
        h3: 'text-2xl',
        h4: 'text-xl',
        h5: 'text-lg',
        h6: 'text-base'
      }.freeze

      # Maps PageHeader alignment values to Level alignment values
      ALIGNMENTS = {
        top: :start,
        center: :center,
        bottom: :end
      }.freeze

      BACK_BUTTON_CLASSES = 'back-button btn btn-ghost size-9 text-primary'

      TITLE_CLASSES = 'title text-2xl font-bold mb-1'
      SUBTITLE_CLASSES = 'subtitle text-lg text-base-content/60'

      renders_one :title, ->(text = nil, tag: :h3, **options, &block) do
        options = prepend_class_name(
          options,
          class_names('title font-bold mb-1', HEADING_SIZES[tag])
        )
        heading_tag(text, tag, **options, &block)
      end

      renders_one :subtitle, ->(text = nil, tag: :h5, **options, &block) do
        options = prepend_class_name(
          options,
          class_names('subtitle text-base-content/60', HEADING_SIZES[tag])
        )
        heading_tag(text, tag, **options, &block)
      end

      def initialize(title: nil, subtitle: nil, align: :center, back: nil, **options)
        @title = title
        @subtitle = subtitle
        @align = align.to_sym
        @back = back
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names(BASE_CLASSES, options[:class])
      end

      def level_align
        ALIGNMENTS.fetch(@align, :center)
      end

      def title_classes
        class_names(TITLE_CLASSES)
      end

      def subtitle_classes
        class_names(SUBTITLE_CLASSES)
      end

      def heading_tag(text, tag_name, **, &)
        text.present? ? tag.send(tag_name, text, **) : tag.send(tag_name, **, &)
      end

      def render_back_button?
        @back.present? && @back[:href].present?
      end

      def back_button_options
        prepend_class_name(@back.dup, BACK_BUTTON_CLASSES)
      end
    end
  end
end
