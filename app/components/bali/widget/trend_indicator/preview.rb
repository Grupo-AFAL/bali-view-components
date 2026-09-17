# frozen_string_literal: true

module Bali
  module Widget
    module TrendIndicator
      class Preview < ApplicationViewComponentPreview
        # An arrow, a delta and the period it compares against.
        #
        # `positive_when` is the whole point. Set `delta` positive and flip
        # `positive_when` to see the SAME movement render green and then red —
        # a rising revenue count and a rising overdue count are opposite news,
        # and the colour follows the meaning rather than the direction.
        #
        # @param delta number
        # @param unit text
        # @param period text
        # @param positive_when [Symbol] select [up, down]
        # @param compact toggle
        def default(delta: 12, unit: "%", period: "vs last week", positive_when: :up,
                    compact: false)
          render Bali::Widget::TrendIndicator::Component.new(
            Bali::Widget::TrendBase::Trend.new(delta: delta.to_i, unit: unit, period: period.presence,
                                    positive_when: positive_when.to_sym),
            compact: compact
          )
        end
      end
    end
  end
end
