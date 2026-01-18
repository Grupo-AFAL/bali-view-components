# frozen_string_literal: true

module Bali
  module Tags
    # Container component for grouping multiple Tag components.
    #
    # Renders tags in a flex container with configurable gap spacing.
    # Each tag can be styled independently - pass options to with_item.
    #
    # @example Basic usage
    #   render Tags::Component.new do |c|
    #     c.with_item(text: 'Ruby', color: :primary)
    #     c.with_item(text: 'Rails', color: :success)
    #   end
    #
    # @example With custom gap
    #   render Tags::Component.new(gap: :lg) do |c|
    #     c.with_item(text: 'Spaced', color: :info)
    #   end
    class Component < ApplicationViewComponent
      GAPS = {
        none: 'gap-0',
        xs: 'gap-1',
        sm: 'gap-2',
        md: 'gap-3',
        lg: 'gap-4'
      }.freeze

      BASE_CLASSES = 'tags-component flex flex-wrap items-center'

      renders_many :items, ->(text: nil, href: nil, **options) do
        Bali::Tag::Component.new(text: text, href: href, **options)
      end

      def initialize(gap: :sm, **options)
        @gap = gap
        @options = options
      end

      def render?
        items.any?
      end

      private

      attr_reader :gap, :options

      def component_classes
        class_names(
          BASE_CLASSES,
          GAPS.fetch(gap, GAPS[:sm]),
          options[:class]
        )
      end

      def component_attributes
        options.except(:class)
      end
    end
  end
end
