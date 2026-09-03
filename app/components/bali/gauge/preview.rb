# frozen_string_literal: true

module Bali
  module Gauge
    class Preview < ApplicationViewComponentPreview
      # A radial progress ring — the circular half of what `Bali::Progress` does
      # linearly. CSS-only underneath (daisyUI's `radial-progress`), so a page of
      # them costs no JavaScript.
      #
      # @param value number
      # @param max number
      # @param label text
      # @param size [Symbol] select [sm, md, lg]
      # @param color [Symbol] select [primary, secondary, accent, neutral, info, success, warning, error]
      # @param show_percentage toggle
      def default(value: 7, max: 10, label: "shifts", size: :md, color: :primary,
                  show_percentage: true)
        render Bali::Gauge::Component.new(
          value: value, max: max, label: label.presence, size: size, color: color,
          show_percentage: show_percentage
        )
      end

      # `value` past `max` is a real state — eleven of ten shifts covered — and
      # the ring fills without overflowing while the accessible value still
      # reports the truth.
      def beyond_the_goal
        render Bali::Gauge::Component.new(value: 11, max: 10, label: "shifts")
      end
    end
  end
end
