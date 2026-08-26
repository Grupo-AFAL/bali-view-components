# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # Takes the WIDGET, not its `Result` — the widget delegates count/items to
    # the result and still knows its own key, which is what lets one component
    # derive every widget's copy.
    #
    # Does no data access at all, which is what lets it be tested against plain
    # `Base` subclasses with a stubbed `#call`.
    class Component < ApplicationViewComponent
      # What each canvas has room for. The card shows the SAME FACT at every
      # size and gives it more context as it grows — it does not change subject.
      #
      # Three regions fill in progressively:
      #
      #   headline — the fact. A number and its label, or a goal as a ring.
      #   context  — how the fact is moving. A chart.
      #   detail   — the breakdown. The row list.
      #
      # `rows` is what a PRE-LADDER widget gets — 3 at medium, 7 at large, exactly
      # what it always rendered — and `charted_rows` is what is left once a chart
      # takes part of the canvas. Two named numbers rather than one positional
      # pair, because "index 0 means with a chart" is a fact a reader should not
      # have to carry.
      #
      # Truncation lives HERE, not in `#call`: the widget answers "which rows
      # matter", the card answers "how many fit".
      REGIONS = {
        # A ~215px tile fits one fact and nothing else, and it is a single tap
        # target — so no rows either way, and nothing inside may be focusable.
        small: { layout: :hero, context: nil, rows: 0, charted_rows: 0 },
        # Fact on the left, sparkline on the right. Axis-less: below roughly 2x2
        # a chart's axes cost more room than they explain.
        medium: { layout: :inline, context: :spark, rows: 3, charted_rows: 0 },
        # Fact in a header band, chart under it, breakdown below that.
        large: { layout: :stacked, context: :full, rows: 7, charted_rows: 3 },
        # Two columns — Apple's extra large is defined as two mediums side by
        # side, so the fact and its chart take the left and the breakdown the
        # right, where it has room for more rows than `large` gives it.
        wide: { layout: :split, context: :full, rows: 6, charted_rows: 6 }
      }.freeze

      # `Bali::Chart` options that turn a chart into a sparkline. The library is
      # already dynamically imported (`chart/index.js`), so reusing it here costs
      # an instance and a canvas rather than a bundle.
      SPARK_OPTIONS = {
        scales: { x: { display: false }, y: { display: false } },
        plugins: { tooltip: { enabled: false } }
      }.freeze

      # NOT `elements: { point: { radius: 0 } }`, which is the obvious spelling
      # and does nothing here: `Chart::Dataset#to_h` writes `pointRadius` onto
      # every line dataset explicitly, and a dataset-level value beats the
      # `elements` default it would otherwise fall back to.
      SPARK_DATASET = { pointRadius: 0, pointHoverRadius: 0 }.freeze

      # Custom content for a widget that isn't a list. Replaces the shape enum
      # the source app used, which had to name an app concept (`:verdict`)
      # inside a library.
      renders_one :body

      delegate :key, :title, :short_title, :count, :items, :view_all_path,
               :empty_message, :size, :failed?,
               :display_value, :trend, :series, :goal, to: :widget

      # `**options` so a host can add a `data-testid`, an extra class, or a
      # Turbo frame attribute to a card — the same passthrough every other
      # component in this library offers on its root tag.
      def initialize(widget, **options)
        @widget = widget
        @options = options
        super()
      end

      private

      attr_reader :widget, :options

      def region = REGIONS.fetch(size)

      # The ONE fact about a size that the rest of this class reads. Every
      # "what does this size look like" question resolves through `REGIONS`;
      # nothing keys off `size` directly, or the table stops being the source of
      # truth the moment someone adds a size.
      def layout = region.fetch(:layout)

      # The compact card: one fact, and the whole tile is the link. Keyed on
      # `layout` rather than a row count of zero — a charted widget at `medium`
      # also has no rows, and it is emphatically not a summary tile.
      def summary? = layout == :hero

      # A region the widget has nothing to put in is not rendered. This is the
      # degradation that keeps every pre-ladder widget working.
      #
      # A SERIES AND NOTHING ELSE. A goal is a HEADLINE — it replaces the
      # number — and the context region can only ever draw a chart. Counting a
      # goal here made the card reserve room for a chart that never rendered:
      # at `medium` the detail region was suppressed and the tile showed a ring
      # alone, where the same widget without a goal showed three rows.
      def context? = region.fetch(:context).present? && series?

      def spark? = region.fetch(:context) == :spark

      def series? = series&.charted? || false

      def goal? = goal.present?

      # Two columns, because an extra-large tile laid out as one long strip shows
      # less than a medium does in four times the space.
      def split? = layout == :split

      # The detail region is rendered only when it HAS something. An empty
      # wrapper is not free: at `:stacked` it takes `flex-1` and squeezes the
      # chart into two fifths of a canvas it could have had whole, and at
      # `:split` it is a blank right-hand column. The number and ring ladders are
      # documented as having no items, so this is the common case, not the edge.
      #
      # The counterpart to `context?`. Both answer "does this region have
      # anything to put in it", and having only one of them was the whole defect.
      def detail? = body? || rows.any? || empty_state?

      # ONE home for this rule. The template used to spell it inline as well,
      # and two spellings of one rule is how the `context?` bug got in.
      #
      # Suppressed when a chart is already speaking for the card: "nothing to
      # show" beside a populated sparkline is a contradiction.
      def empty_state? = !any_items? && !context?

      def rows = items.first(region.fetch(context? ? :charted_rows : :rows))

      def any_items? = count.positive?

      def view_all_link? = any_items? && view_all_path.present?

      def trend? = trend.present?

      # Colour comes from `good?` and NEVER from `direction`. Overdue tasks up
      # 12% and revenue up 12% are opposite news; a card reading the direction
      # would paint half a dashboard's trends the wrong way while looking
      # confident about it.
      def trend_classes
        return "text-base-content/60" if trend.flat?

        trend.good? ? "text-success" : "text-error"
      end

      def trend_icon
        return "minus" if trend.flat?

        trend.direction == :up ? "trending-up" : "trending-down"
      end

      # The arrow is decorative and `aria-hidden`; this is what is actually
      # announced, so it has to carry the direction as a WORD.
      def trend_label
        return t("bali_view.widgets.trend.flat") if trend.flat?

        t("bali_view.widgets.trend.#{trend.direction}", delta: trend_delta)
      end

      def trend_delta = "#{trend.delta.abs}#{trend.unit}"

      # The chart's share of the canvas, which differs by what it is SHARING
      # WITH rather than by taste.
      #
      # At `:inline` it divides a row with the headline, so it takes the
      # remaining width. At `:split` it has a column to itself — the breakdown is
      # in the other one — so it takes the remaining height. Only at `:stacked`
      # does it sit ABOVE the breakdown, and there an even split starves the list
      # and clips its last row; two fifths leaves the rows whole.
      #
      # `!detail?` is the condition those two fifths always depended on: with no
      # breakdown beneath it, the chart takes the canvas. Without this the empty
      # wrapper goes away and the whitespace it was holding stays — a chart in
      # the top 40% of a card with dead space under it.
      #
      # THIS METHOD IS THE ONE PLACE that has to know about more than one region.
      # `context?` and `detail?` each decide whether their OWN region renders;
      # this decides how big one of them is GIVEN the other, which is why three
      # bugs of the same shape all ended here. Anything that changes WHEN a
      # region renders has to be checked against this line.
      def context_classes
        class_names(
          "bali-widget-context min-h-0 min-w-0 overflow-hidden",
          spark? || split? || !detail? ? "flex-1" : "basis-2/5"
        )
      end

      def chart_options
        return SPARK_OPTIONS.deep_dup if spark?

        { plugins: { tooltip: { enabled: true } } }
      end

      def chart_data
        dataset = { label: short_title, data: series.values }
        dataset = dataset.merge(SPARK_DATASET) if spark?

        { labels: series.labels, datasets: [ dataset ] }
      end

      def card_classes
        class_names(
          "bali-widget-card",
          summary? ? "p-4" : "p-6",
          options[:class]
        )
      end

      def card_attributes
        options.except(:class)
      end
    end
  end
end
