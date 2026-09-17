# frozen_string_literal: true

module Bali
  module Widget
    module Trend
      # A FIGURE AND HOW IT MOVED — the whole card for a `TrendBase` widget.
      #
      # The figure is the headline, the movement sits beside it, and the history
      # fills the context region. `Bali::Widget::TrendIndicator` owns the arrow
      # and the colour rule; this places it.
      class Component < Value::Component
        include Card::Charted

        private

        # The indicator sits BESIDE the figure at every size but the hero, where
        # it goes underneath — a ~215px tile has room for a figure and a label on
        # one axis, not three things on a line.
        def headline
          return super if hero?

          tag.div(class: "flex items-center gap-3") { safe_join([ super, indicator ].compact) }
        end

        # `compact`: a hero tile has room for an arrow and a delta, not the
        # period they compare against.
        def hero_footer
          return if trend.blank?

          tag.p(indicator(compact: true), class: "mt-1 flex justify-center")
        end

        def indicator(compact: false)
          return if trend.blank?

          render Bali::Widget::TrendIndicator::Component.new(trend, compact: compact)
        end

        def trend = @trend ||= widget.trend
      end
    end
  end
end
