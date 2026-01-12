# frozen_string_literal: true

module Bali
  module HoverCard
    class Component < ApplicationViewComponent
      attr_reader :options, :content_padding

      renders_one :trigger, ->(**options, &block) do
        options = prepend_data_attribute(options, 'hovercard-target', 'trigger')
        tag.div(**options, &block)
      end

      # @param hover_url [String]
      # @param placement [String] one of the placement options that @popper offers:
      #          auto
      #          auto-start
      #          auto-end
      #          top
      #          top-start
      #          top-end
      #          bottom
      #          bottom-start
      #          bottom-end
      #          right
      #          right-start
      #          right-end
      #          left
      #          left-start
      #          left-end
      # @param open_on_click [Boolean] Switch between a hover and a click behavior
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(hover_url: nil, placement: 'auto', open_on_click: false,
                     append_to: 'body', z_index: 9999, content_padding: true,
                     arrow: true, **options)
        @placement = placement
        @hover_url = hover_url
        @open_on_click = open_on_click
        @append_to = append_to
        @z_index = z_index
        @content_padding = content_padding
        @arrow = arrow

        @options = prepend_class_name(options, 'hover-card-component')
        @options = prepend_controller(@options, 'hovercard')
        @options = prepend_values(@options, 'hovercard', controller_values)
        @options = if @open_on_click
                     prepend_data_attribute(@options, 'hovercard-trigger-value', 'click')
                   else
                     prepend_data_attribute(@options, 'hovercard-trigger-value', 'mouseenter focus')
                   end
      end
      # rubocop:enable Metrics/ParameterLists

      def controller_values
        {
          placement: @placement,
          url: @hover_url,
          content_padding: @content_padding,
          z_index: @z_index,
          append_to: @append_to,
          arrow: @arrow
        }
      end
    end
  end
end
