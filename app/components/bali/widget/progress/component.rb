# frozen_string_literal: true

module Bali
  module Widget
    module Progress
      # PROGRESS TOWARD A GOAL — the whole card for a `ProgressBase` widget.
      #
      # THE RING REPLACES THE NUMBER as the headline, which is what makes this a
      # type rather than a list with an ornament — so it does not inherit
      # `Value`, whose headline is a figure.
      #
      # Not to be confused with `Bali::Progress::Component`, the LINEAR bar. This
      # is the radial half, and it composes `Bali::Gauge`, which owns the arc, the
      # percentage and the full `progressbar` ARIA contract.
      class Component < Card::Component
        include Card::Charted

        private

        # `lg` on the hero, where the ring is the whole tile; `md` in a header
        # row, where it shares the line.
        #
        # The `flex justify-center` on the hero is load-bearing rather than
        # decorative: daisyUI's `.stat` is a GRID, and `text-align` does not move
        # a grid item, so the ring sat off to the left of its own label until a
        # flex wrapper went round it.
        def headline
          return gauge unless hero?

          tag.div(gauge, class: "flex justify-center")
        end

        def gauge
          render Bali::Gauge::Component.new(**goal.to_h, size: hero? ? :lg : :md, color: :primary)
        end

        def goal = @goal ||= widget.goal
      end
    end
  end
end
