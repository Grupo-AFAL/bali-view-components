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
        super
      end

      # DERIVED ON READ, not at construction — and the alias is what makes that
      # possible: `Data` generates the reader on this very class, so redefining
      # it here replaces it and `super` would find nothing. Aliasing first keeps
      # a private handle on the stored value.
      #
      # Lazily because `Data#with` re-runs `initialize` with the current members,
      # so a value computed at construction goes stale: `result.with(count: 99)`
      # kept the headline derived from the OLD count. That matters now that the
      # builders below are `with` underneath.
      alias_method :stored_display_value, :display_value
      private :stored_display_value

      # The headline, in the 4-6 characters a ~215px tile at `text-4xl` has room
      # for. An explicit value is never touched — "72%" and "$1.2k" are not
      # counts, and abbreviating them would corrupt them.
      def display_value = stored_display_value || Widget.abbreviate(count)

      # THE LADDER, one rung at a time. `#call` returns the fact, then says how
      # it is moving and what it looks like over time:
      #
      #   list_from(scope, view_all_path: items_path)
      #     .with_trend(delta: 12, period: "vs last week", positive_when: :down)
      #     .with_series(values: weekly_counts, labels: weekday_names)
      #
      # Builders rather than nine keywords on one `Result.new`, because the list
      # ladder already had `list_from` and the other two had nothing — a library
      # that ships three patterns and gives sugar to one of them is telling you
      # which two it did not mean.
      def with_trend(**attributes) = with(trend: Trend.new(**attributes))

      def with_series(**attributes) = with(series: Series.new(**attributes))

      # Replaces the number as the headline; the ring is drawn from it.
      def with_goal(**attributes) = with(goal: Goal.new(**attributes))

      # The degraded card a widget falls back to when its `#call` raises. A
      # FAILURE rather than a dropped widget on purpose: a tile that vanishes
      # reads as "nothing to see", which is the one thing a failure must not say.
      def self.failed = new(failed: true)

      def failed? = failed
    end
  end
end
