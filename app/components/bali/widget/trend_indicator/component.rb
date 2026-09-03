# frozen_string_literal: true

module Bali
  module Widget
    module TrendIndicator
      # An arrow, a delta and the period it compares against.
      #
      #   render Bali::Widget::TrendIndicator::Component.new(trend)
      #
      # Its own component because it is a presenter over one `Bali::Widget::Trend`
      # and nothing else — it reads no layout, no size, no region. Inside the card
      # it was five methods that never touched the other twenty, which is the same
      # test the size picker's extraction passed.
      #
      # Moving it here also gives the `positive_when` rule a test file of its own.
      # That rule is the most misusable thing in the widget contract, and it was
      # being asserted through a card render three layers away from where it lives.
      class Component < ApplicationViewComponent
        # `compact` is the `small` card: a ~215px tile has room for an arrow and a
        # delta, and nothing else. Dropping the period there is what keeps the
        # headline the thing you read.
        def initialize(trend, compact: false, **options)
          @trend = trend
          @compact = compact
          @options = options
          super()
        end

        # THE RULE THIS COMPONENT EXISTS FOR. Colour comes from `good?` and NEVER
        # from `direction`: overdue tasks up 12% and revenue up 12% are opposite
        # news, and a component reading the direction would paint half a
        # dashboard's trends the wrong way while looking confident about it.
        #
        # Flat is neither — painting "no change" green would say it was good.
        def classes
          class_names("inline-flex items-center gap-1 text-xs", colour, options[:class])
        end

        # `trending-up` / `trending-down` describe the MOVEMENT, which is why they
        # are chosen from `direction` where the colour above is not.
        def icon
          return "minus" if trend.flat?

          trend.direction == :up ? "trending-up" : "trending-down"
        end

        # What is actually announced. The arrow is decorative, so the direction
        # has to reach a screen reader as a WORD or the trend reads as a bare
        # number with no sign.
        def label
          return t("bali_view.widgets.trend.flat") if trend.flat?

          t("bali_view.widgets.trend.#{trend.direction}", delta: delta)
        end

        # `abs` because the arrow already carries the sign; "↓ -67%" is a double
        # negative that reads as a rise.
        def delta = "#{trend.delta.abs}#{trend.unit}"

        def period? = !compact && trend.period.present?

        def period = trend.period

        private

        attr_reader :trend, :compact, :options

        def colour
          return "text-base-content/60" if trend.flat?

          trend.good? ? "text-success" : "text-error"
        end
      end
    end
  end
end
