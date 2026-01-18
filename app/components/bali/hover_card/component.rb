# frozen_string_literal: true

module Bali
  module HoverCard
    class Component < ApplicationViewComponent
      # Valid Tippy.js/Popper.js placement options for the hovercard
      PLACEMENTS = %w[
        auto auto-start auto-end
        top top-start top-end
        bottom bottom-start bottom-end
        right right-start right-end
        left left-start left-end
      ].freeze

      TRIGGERS = {
        hover: 'mouseenter focus',
        click: 'click'
      }.freeze

      DEFAULT_Z_INDEX = 9999

      renders_one :trigger, ->(**options, &block) do
        tag.div(**options.merge(data: { hovercard_target: 'trigger' }), &block)
      end

      # @param hover_url [String] URL to fetch content from asynchronously
      # @param placement [String] Tippy.js placement option (see PLACEMENTS)
      # @param open_on_click [Boolean] Switch between hover and click behavior
      # @param append_to [String] Where to append the popup ('body', 'parent', or CSS selector)
      # @param z_index [Integer] Z-index for the popup
      # @param content_padding [Boolean] Whether to add padding to content
      # @param arrow [Boolean] Whether to show an arrow pointing to trigger
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        hover_url: nil,
        placement: 'auto',
        open_on_click: false,
        append_to: 'body',
        z_index: DEFAULT_Z_INDEX,
        content_padding: true,
        arrow: true,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @hover_url = hover_url
        @placement = validate_placement(placement)
        @open_on_click = open_on_click
        @append_to = append_to
        @z_index = z_index
        @content_padding = content_padding
        @arrow = arrow
        @options = options
      end

      def wrapper_options
        @options.except(:class, :data).merge(
          class: component_classes,
          data: merged_data_attributes
        )
      end

      def wrapped_content
        return content unless @content_padding

        tag.div(content, class: 'hover-card-content')
      end

      private

      def component_classes
        class_names('hover-card-component', @options[:class])
      end

      def merged_data_attributes
        (@options[:data] || {}).merge(stimulus_data)
      end

      def stimulus_data
        {
          controller: 'hovercard',
          hovercard_placement_value: @placement,
          hovercard_url_value: @hover_url,
          hovercard_content_padding_value: @content_padding,
          hovercard_z_index_value: @z_index,
          hovercard_append_to_value: @append_to,
          hovercard_arrow_value: @arrow,
          hovercard_trigger_value: trigger_event
        }.compact
      end

      def trigger_event
        @open_on_click ? TRIGGERS[:click] : TRIGGERS[:hover]
      end

      def validate_placement(placement)
        return placement if PLACEMENTS.include?(placement.to_s)

        'auto'
      end
    end
  end
end
