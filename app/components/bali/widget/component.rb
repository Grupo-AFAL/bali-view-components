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
      #   headline — the fact. A number and its label, or a gauge ring.
      #   context  — how the fact is moving. A chart.
      #   detail   — the breakdown. The row list.
      #
      # `rows` is a PAIR — `[with_context, without_context]` — and that pair is
      # what makes the ladder additive instead of a migration. A widget that
      # supplies no `series` and no `gauge` (every widget written against the
      # original contract) has no context region, takes the second number, and
      # renders exactly what it always did: 3 rows at medium, 7 at large. A
      # widget that supplies a series trades rows for the chart.
      #
      # Truncation lives HERE, not in `#call`: the widget answers "which rows
      # matter", the card answers "how many fit".
      REGIONS = {
        # A ~215px tile fits one fact and nothing else, and it is a single tap
        # target — so no rows at either count, and nothing inside may be
        # focusable.
        small: { headline: :hero, context: nil, rows: [ 0, 0 ] },
        # Fact on the left, sparkline on the right. Axis-less: below roughly 2x2
        # a chart's axes cost more room than they explain.
        medium: { headline: :inline, context: :spark, rows: [ 0, 3 ] },
        # Fact in a header band, chart under it, breakdown below that.
        large: { headline: :header, context: :full, rows: [ 3, 7 ] },
        # Two columns — Apple's extra large is defined as two mediums side by
        # side, so the fact and its chart take the left and the breakdown the
        # right, where it has room for more rows than `large` gives it.
        wide: { headline: :header, context: :full, rows: [ 6, 6 ] }
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

      # Which of the 4x2 lattice cells each size fills, in the grid's own reading
      # order: left to right, top row then bottom.
      #
      # The LATTICE is the point, not the fill. Four rectangles floating in
      # whitespace are four masses with no shared origin — which is why `medium`
      # (2x1) and `large` (2x2), being the same WIDTH, were indistinguishable.
      # The same four inside a visible 4x2 grid are a map.
      CELLS = {
        small: [ 0 ],
        medium: [ 0, 1 ],
        large: [ 0, 1, 4, 5 ],
        wide: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
      }.freeze

      # The empty cell is a CONSTANT — `base-content`, never `current` — because
      # a frame of reference that changes with the state it frames is not a
      # reference. Deriving it from the button's text colour stacked two
      # opacities into 9% ink on white: invisible, which collapsed the map back
      # into the mass it replaced.
      CELL_FILLED = "rounded-[1px] bg-base-content/45 " \
                    "group-hover:bg-base-content/70 group-aria-checked:bg-primary"
      CELL_EMPTY = "rounded-[1px] bg-base-content/20 group-aria-checked:bg-primary/25"

      # Custom content for a widget that isn't a list. Replaces the shape enum
      # the source app used, which had to name an app concept (`:verdict`)
      # inside a library.
      renders_one :body

      delegate :key, :title, :short_title, :count, :items, :view_all_path,
               :empty_message, :size, :failed?,
               :display_value, :trend, :series, :gauge, to: :widget

      # `**options` so a host can add a `data-testid`, an extra class, or a
      # Turbo frame attribute to a card — the same passthrough every other
      # component in this library offers on its root tag.
      def initialize(widget, **options)
        @widget = widget
        @options = options
        super()
      end

      def region = REGIONS.fetch(size)

      def headline_style = region[:headline]

      # The compact card: one fact, and the whole tile is the link. Keyed on the
      # headline style rather than a row count of zero — a charted widget at
      # `medium` also has no rows, and it is emphatically not a summary tile.
      def summary? = headline_style == :hero

      # A region the widget has nothing to put in is not rendered. This is the
      # degradation that keeps every pre-ladder widget working.
      def context? = region[:context].present? && (series? || gauge?)

      def context_style = region[:context]

      def spark? = context_style == :spark

      def series? = series.present? && series.any?

      def gauge? = gauge.present?

      # Two columns, because an extra-large tile laid out as one long strip shows
      # less than a medium does in four times the space.
      def two_column? = size == :wide

      def rows = items.first(region[:rows][context? ? 0 : 1])

      def detail? = rows.any? || (!summary? && !any_items?)

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
      # At `medium` it divides a row with the headline, so it takes the
      # remaining width. At `wide` it has a column to itself — the breakdown is
      # in the other one — so it takes the remaining height. Only at `large` is
      # it stacked ABOVE the breakdown, and there an even split starves the list
      # and clips its last row; two fifths leaves the rows whole.
      def context_classes
        class_names(
          "bali-widget-context min-h-0 min-w-0 overflow-hidden",
          spark? || two_column? ? "flex-1" : "basis-2/5"
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

      # Here rather than in the template so the template stops doing conditional
      # presentation with fully qualified constants on a 160-character line.
      def cell_class(name, cell)
        CELLS.fetch(name).include?(cell) ? CELL_FILLED : CELL_EMPTY
      end

      private

      attr_reader :widget, :options

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
