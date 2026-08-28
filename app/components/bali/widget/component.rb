# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # Takes the WIDGET and asks it directly — there is no result object between
    # them. `Bali::Widget::Base` answers every question with a null where the
    # pattern has nothing, so this component reads one uniform interface and
    # never branches on which kind of widget it is holding.
    #
    # It decides WHAT TO LOAD (`before_render`) and HOW MUCH FITS (`REGIONS`);
    # the widget decides what the answers are.
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
      # Truncation lives HERE, not in the widget: the widget answers "which rows
      # matter", the card answers "how many fit".
      #
      # There is no separate budget for "rows beside a chart". A widget is
      # exactly one pattern, and no pattern has both a series and items —
      # `ListBase` overrides `items` and never `series`, `TrendBase` and
      # `ProgressBase` the reverse — so a card is never asked to fit both.
      # Reinstate one here if `TrendBase`/`ProgressBase` ever gain rows.
      REGIONS = {
        # A ~215px tile fits one fact and nothing else, and it is a single tap
        # target — so no rows, and nothing inside may be focusable.
        small: { layout: :hero, context: nil, rows: 0 },
        # Fact on the left, sparkline on the right. Axis-less: below roughly 2x2
        # a chart's axes cost more room than they explain.
        medium: { layout: :inline, context: :spark, rows: 3 },
        # Fact in a header band, chart under it, breakdown below that.
        large: { layout: :stacked, context: :full, rows: 7 }
      }.freeze

      # OVERRIDABLE, because `rows` is a pixel budget measured against Bali's
      # own type sizes. A host with a larger base font, two-line
      # subtitles or a denser theme gets clipping and, as a frozen constant, no
      # way to say so — a library imposing not a philosophy but a MEASUREMENT.
      #
      # Set it in an initializer:
      #
      #   Bali::Widget::Component.regions = Bali::Widget::Component::REGIONS.deep_merge(
      #     large: { rows: 5 }
      #   )
      #
      # `layout` and `context` are structure rather than measurement — they name
      # which regions exist and how they are arranged — so overriding those is
      # possible and not the point of this.
      class_attribute :regions, default: REGIONS

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

      # ONE INTERFACE, straight off the widget. `Bali::Widget::Base` answers every
      # one of these — with a null where the pattern has nothing — so the card
      # never asks what kind of widget it is holding. A `ValueBase` returns no
      # rows and no series; the regions that would have shown them simply do not
      # render.
      delegate :key, :title, :short_title, :empty_message, :size, :supported_sizes,
               :count, :items, :view_all_path, :failed?,
               :display_value, :trend, :series, :goal, to: :widget

      # A STABLE DOM ID so a host can address one card from a Turbo Stream. The
      # grid's own resize needs it — a card that changes shape has to come back
      # re-rendered, because its interior is built by the server — and any host
      # refreshing a single tile can target the same id.
      #
      # Public: it is the one thing about the card a host outside this component
      # legitimately needs to name.
      def self.dom_id(key) = "bali-widget-#{key}"

      # `**options` so a host can add a `data-testid`, an extra class, or a
      # Turbo frame attribute to a card — the same passthrough every other
      # component in this library offers on its root tag.
      def initialize(widget, **options)
        @widget = widget
        @options = options
        super()
      end

      # THE CARD BRANCHES ON FAILURE FIRST, before it has asked the widget
      # anything — and a widget reads lazily, so at that moment nothing has
      # failed yet. Without this the card takes the healthy branch and renders a
      # confident grey `0` for a widget that is actually broken, which is the one
      # thing the degraded tile exists to prevent.
      #
      # Loading belongs here rather than behind a probing `failed?`, because
      # deciding what a canvas needs read is the CARD's job: `count` always,
      # since every pattern defines it and every region depends on it, and
      # `items` only where rows will actually render. A hero tile shows none, so
      # it never pays for them.
      def before_render
        count
        items if region.fetch(:rows).positive?
      end

      private

      attr_reader :widget, :options

      def dom_id = self.class.dom_id(key)

      # A radiogroup with one option is not a choice. A widget that offers a
      # single size gets no picker rather than a picker that cannot do anything.
      def resizable? = supported_sizes.many?

      def region = regions.fetch(size)

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

      # The detail region is rendered only when it HAS something. An empty
      # wrapper is not free: at `:stacked` it takes `flex-1` and squeezes the
      # chart into two fifths of a canvas it could have had whole, and at
      # `:split` it is a blank right-hand column. The number and ring ladders are
      # documented as having no items, so this is the common case, not the edge.
      #
      # The counterpart to `context?`. Both answer "does this region have
      # anything to put in it", and having only one of them was the whole defect.
      #
      # `failed?` because a failed detail region has an apology to show, and
      # dropping the region would drop that with it. `before_render` has already
      # attempted both reads, so this is a plain question by the time it is asked.
      def detail? = body? || rows.any? || empty_state? || failed?

      # ONE home for this rule. The template used to spell it inline as well,
      # and two spellings of one rule is how the `context?` bug got in.
      #
      # Suppressed when a chart is already speaking for the card: "nothing to
      # show" beside a populated sparkline is a contradiction.
      def empty_state? = !any_items? && !context?

      def rows = @rows ||= items.first(region.fetch(:rows))

      def any_items? = count.positive?

      def view_all_link? = any_items? && view_all_path.present?

      def trend? = trend.present?

      # The chart's share of the canvas, which differs by what it is SHARING
      # WITH rather than by taste.
      #
      # At `:inline` it divides a row with the headline, so it takes the
      # remaining width. At `:stacked` it sits ABOVE the breakdown, and there an
      # even split starves the list and clips its last row; two fifths leaves the
      # rows whole.
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
          spark? || !detail? ? "flex-1" : "basis-2/5"
        )
      end

      def chart_options
        return SPARK_OPTIONS.deep_dup if spark?

        # `precision: 0` when every value is a whole number, because most widget
        # series are COUNTS and Chart.js's default tick algorithm happily offers
        # "1.6" of them. Inferred rather than configured: a widget charting
        # integers never wants fractional ticks, so there is nothing to ask it.
        { plugins: { tooltip: { enabled: true } } }.tap do |options|
          options[:scales] = { y: { ticks: { precision: 0 } } } if whole_numbers?
        end
      end

      def whole_numbers?
        series.values.all? { |value| value.is_a?(Integer) || value.to_f % 1 == 0 }
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
