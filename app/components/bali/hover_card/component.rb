# frozen_string_literal: true

module Bali
  module HoverCard
    class Component < ApplicationViewComponent
      attr_reader :placement, :options, :data, :hover_url

      renders_one :trigger, ->(**options, &block) do
        options = prepend_class_name(options, 'hovercard-component--trigger')

        tag.div(**options, &block)
      end

      renders_one :template

      def initialize(hover_url: nil, placement: 'auto', **options)
        @placement = placement
        @data = options.delete(:data) || {}
        @hover_url = options.dig(:data, :'hovercard-url-value') || hover_url
        @options = prepend_class_name(options, 'hover-card-component')
      end

      private

      def hovercard_data
        {
          controller: "hovercard #{data.delete(:controller)}",
          'hovercard-placement-value': placement,
          'hovercard-url-value': hover_url
        }.merge!(data).compact
      end
    end
  end
end
