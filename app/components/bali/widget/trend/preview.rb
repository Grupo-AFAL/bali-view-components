# frozen_string_literal: true

module Bali
  module Widget
    module Trend
      class Preview < ApplicationViewComponentPreview
        # A figure and how it moved — the whole card for a `TrendBase` widget.
        #
        # `positive_when` is the point. Leave `current` above `previous` and flip
        # it to see the SAME movement render green and then red: a rising revenue
        # count and a rising overdue count are opposite news, and the colour
        # follows the meaning rather than the direction.
        #
        # Set `charted` off to see the card without a context region — the
        # breakdown, or nothing, takes the space instead.
        #
        # @param size select { choices: [small, medium, large] }
        # @param current number
        # @param previous number
        # @param positive_when [Symbol] select [up, down]
        # @param charted toggle
        def default(size: :medium, current: 12, previous: 6, positive_when: :up, charted: true)
          widget = Class.new(Bali::Widget::TrendBase) do
            def self.key = "low_stock"
            title "Low stock items"
            short_title "Low stock"
            empty_message "Nothing running low"
          end
          widget.trend do |t|
            t.current current.to_i
            t.previous previous.to_i
            t.positive_when positive_when.to_sym
            t.period_label "vs last week"
          end
          widget.series { |s| s.values [ 3, 5, 4, 8, 6, 9, 12 ] } if charted

          render Bali::Widget::Trend::Component.new(
            widget.new, size: size.to_sym
          )
        end
      end
    end
  end
end
