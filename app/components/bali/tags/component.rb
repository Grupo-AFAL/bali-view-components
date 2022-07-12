# frozen_string_literal: true

module Bali
  module Tags
    class Component < ApplicationViewComponent
      renders_many :items, ->(text: nil, href: nil, **options) do
        Bali::Tag::Component.new(
          text: text,
          href: href,
          light: @light,
          rounded: @rounded,
          **options
        )
      end

      def initialize(
        size: nil,
        light: false,
        rounded: false,
        **options
      )
        @light = light
        @rounded = rounded
        @options = prepend_class_name(options, 'tags-component tags')
        @options = prepend_class_name(@options, "are-#{size}") if size.present?
      end

      def render?
        items.size.positive?
      end
    end
  end
end
