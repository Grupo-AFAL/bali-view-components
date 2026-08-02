# frozen_string_literal: true

module Bali
  module Tooltip
    class Component < ApplicationViewComponent
      renders_one :trigger

      POSITIONS = {
        top: "top",
        bottom: "bottom",
        left: "left",
        right: "right"
      }.freeze

      CONTROLLER = "tooltip"

      # `focusin` and not tippy's `focus`, for the same reason Bali::HoverCard spells it that
      # way: tippy only honours `focus` when the focused element IS the reference, and the
      # reference here is the `<span class="trigger">` the template wraps the slot in, which
      # has no tabindex and therefore never takes focus. Focusing the caller's own control
      # inside the slot left the balloon shut — measured in Chrome on `bali/tooltip/default`,
      # `state.isVisible` false with `focus` and true with `focusin`, which bubbles. The
      # keyboard half of the old default could not fire in any tooltip the library rendered.
      DEFAULT_TRIGGER = "mouseenter focusin"

      # NOTE: The `trigger_event` parameter is named to avoid collision with the `trigger` slot
      #
      # `append_to` controls where the balloon is portaled in the DOM. Defaults to
      # `:parent` (rendered inside the trigger). Pass `:body` or a CSS-selector String
      # to portal the balloon out of ancestors with `overflow` that would clip it.
      def initialize(placement: :top, trigger_event: DEFAULT_TRIGGER, append_to: :parent, **options)
        @placement = placement&.to_sym
        @trigger_event = trigger_event
        @append_to = append_to
        @options = options
      end

      def container_classes
        class_names(
          "tooltip-component",
          "inline-block",
          options[:class]
        )
      end

      def container_attributes
        options.except(:class).merge(
          data: stimulus_data.merge(options.fetch(:data, {}))
        )
      end

      def trigger_classes
        class_names("trigger", "cursor-pointer")
      end

      private

      attr_reader :placement, :trigger_event, :append_to, :options

      def stimulus_data
        {
          controller: CONTROLLER,
          "#{CONTROLLER}-placement-value": placement_value,
          "#{CONTROLLER}-trigger-value": trigger_event,
          "#{CONTROLLER}-append-to-value": append_to_value
        }
      end

      def placement_value
        POSITIONS.fetch(placement, "top")
      end

      def append_to_value
        append_to.to_s
      end
    end
  end
end
