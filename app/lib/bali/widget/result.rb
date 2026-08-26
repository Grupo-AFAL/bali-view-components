# frozen_string_literal: true

module Bali
  module Widget
    # What every widget's `#call` returns. `Base` delegates the readers to it, so
    # `Bali::Widget::Component` talks to the widget and never sees this.
    #
    # `failed` is a field rather than a class-level declaration because a
    # declaration fifteen lines from the `#call` it describes can drift from what
    # `#call` actually returns; a field on the result cannot.
    #
    # The last four are the SIZE LADDER's half of the contract, and every one of
    # them defaults to nil or a derived value. That is what makes the ladder
    # additive: a widget written against the original five fields still renders
    # at every size — the card simply omits the regions it has nothing to put in,
    # rather than failing to find them. Richer widgets fill more of the canvas.
    #
    #   `display_value` — the headline, in the 4-6 characters a ~215px tile has
    #   `trend`         — Bali::Widget::Trend, the "number + trend" rung
    #   `series`        — Bali::Widget::Series, what the context region charts
    #   `goal`          — Bali::Widget::Goal, the ring ladder's headline
    Result = Data.define(:count, :items, :view_all_path, :failed,
                         :display_value, :trend, :series, :goal) do
      def initialize(count: 0, items: [], view_all_path: nil, failed: false,
                     display_value: nil, trend: nil, series: nil, goal: nil)
        # Abbreviated HERE rather than in the card, so a widget can read back the
        # same string the tile shows. An explicit value is never touched: a
        # headline of "72%" or "$1.2k" is not a count and abbreviating it would
        # corrupt it.
        super(count:, items:, view_all_path:, failed:, trend:, series:, goal:,
              display_value: display_value || Widget.abbreviate(count))
      end

      # The degraded card a widget falls back to when its `#call` raises. A
      # FAILURE rather than a dropped widget on purpose: a tile that vanishes
      # reads as "nothing to see", which is the one thing a failure must not say.
      def self.failed = new(failed: true)

      def failed? = failed
    end
  end
end
