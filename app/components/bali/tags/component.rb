# frozen_string_literal: true

module Bali
  module Tags
    class Component < ApplicationViewComponent
      renders_many :items, ->(text: nil, href: nil, **options) do
        @withlinks = true if text.to_s.length.positive? && href.present?
        Bali::Tag::Component.new(
          text: text,
          href: href,
          light: @light,
          rounded: @rounded,
          **options
        )
      end

      def initialize(
        sizes: nil,
        light: false,
        rounded: false,
        **options
      )
        @withlinks = false
        @light = light
        @rounded = rounded
        @options = prepend_class_name(options, 'tags-component tags')
        @options = prepend_class_name(@options, "are-#{sizes}") if sizes.present?
      end

      def render?
        items.size.positive?
      end
    end
  end
end
