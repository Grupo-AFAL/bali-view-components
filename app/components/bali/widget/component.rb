# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # Takes the WIDGET and asks it directly — there is no result object between
    # them. A pattern answers only for what it is, and this component defaults
    # the rest — so it reads one uniform interface and never branches on which
    # kind of widget it is holding.
    #
    # It decides WHAT TO LOAD (`before_render`) and HOW MUCH FITS (`ROWS`);
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
      # THE ONLY THING A SIZE SAYS THAT THE SIZE ITSELF DOES NOT. How many rows a
      # canvas has room for is a MEASUREMENT against Bali's own type sizes, and
      # nothing else about a size needs writing down: hero, inline and stacked
      # are one-to-one with small, medium and large, so a table naming them was
      # `size` wearing a hat.
      #
      #   small   a ~215px tile fits one fact and nothing else, and is a single
      #           tap target — so no rows, and nothing inside may be focusable
      #   medium  fact on the left, three rows or a sparkline on the right
      #   large   fact in a header band, chart under it, seven rows below that
      #
      # OVERRIDABLE, because a host with a larger base font, two-line subtitles
      # or a denser theme gets clipping and, as a frozen constant, no way to say
      # so — a library imposing not a philosophy but a measurement:
      #
      #   Bali::Widget::Component.rows_budget =
      #     Bali::Widget::Component::ROWS.merge(large: 5)
      ROWS = { small: 0, medium: 3, large: 7 }.freeze

      class_attribute :rows_budget, default: ROWS

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

      # ONE INTERFACE, straight off the widget. `Bali::Widget::Base` answers every
      # one of these — with a null where the pattern has nothing — so the card
      # never asks what kind of widget it is holding. A `ValueBase` returns no
      # rows and no series; the regions that would have shown them simply do not
      # render.
      # WHAT EVERY WIDGET ANSWERS. Five patterns, one interface, no type check
      # anywhere in this class or its template.
      delegate :key, :title, :short_title, :empty_message, :supported_sizes,
               :view_all_path, to: :widget

      # WHICH CARD DRAWS THIS WIDGET. The one place the shell asks what kind of
      # widget it is holding — and it asks the WIDGET's own class, so a host's
      # subclass of a pattern gets that pattern's card without registering
      # anything.
      #
      # A widget that is none of the five still renders: `Value` is the fallback,
      # and it needs only `count` and `display_value`, which `Bali::Widget::Base`
      # does not define but every real widget does.
      # SIZE IS TOLD, NOT ASKED. It is a per-owner arrangement fact rather than
      # a property of the widget — the same widget class is `small` for one
      # person and `large` for another — so the card that draws it is the thing
      # that knows which canvas it is drawing on.
      #
      # Defaults to the widget's own `default_size`, which is what a preview, a
      # test or a host rendering one card outside an arrangement wants. A stored
      # size arrives through `Bali::Widget::Placement`, which has already
      # resolved a retired or nil one.
      #
      # `**options` so a host can add a `data-testid`, an extra class, or a Turbo
      # frame attribute to a card — the same passthrough every other component in
      # this library offers on its root tag.
      def initialize(widget, size: nil, **options)
        @widget = widget
        @size = size&.to_sym || widget.class.default_size
        @options = options
        super()
      end

      # A STABLE DOM ID so a host can address one card from a Turbo Stream. The
      # grid's own resize needs it — a card that changes shape has to come back
      # re-rendered, because its interior is built by the server — and any host
      # refreshing a single tile can target the same id.
      #
      # Public: it is the one thing about the card a host outside this component
      # legitimately needs to name.
      def self.dom_id(key) = "bali-widget-#{key}"

      # THE ERROR BOUNDARY. One tile's failure must not take the page with it,
      # and a tile that VANISHES reads as "nothing to see" — the one thing a
      # failure must not say — so a raising widget renders the degraded card in
      # its own place.
      #
      # HERE and not in the widget. The rescue is a RENDERING concern: "one of
      # twelve tiles must not kill the page" is a fact about the page, and a
      # widget knows nothing about being one of twelve. A widget raises like any
      # other object and this decides what a page does about it — the same shape
      # as a React error boundary, and as `react-island`'s own.
      #
      # `render_in` rather than a rescue inside the template: ViewComponent
      # buffers the subtree, so unwinding here discards whatever markup had
      # already been emitted. A rescue further in would leave half a card on the
      # page above the apology.
      #
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — and a forgotten declaration is the
      # most likely way to author a broken widget.
      # The apology, as its own component so the boundary has something to render
      # that cannot itself fail.
      def self.degraded(widget) = Bali::Widget::Degraded::Component.new(widget)

      private

      attr_reader :widget, :size, :options

      def dom_id = self.class.dom_id(key)

      # A radiogroup with one option is not a choice. A widget that offers a
      # single size gets no picker rather than a picker that cannot do anything.
      def resizable? = supported_sizes.many?

      # The hero is a tighter card — one fact needs less room around it than a
      # header, a chart and a breakdown do.
      def hero? = size == :small

      CARDS = {
        Bali::Widget::ListBase => Bali::Widget::List::Component,
        Bali::Widget::TrendBase => Bali::Widget::Trend::Component,
        Bali::Widget::ProgressBase => Bali::Widget::Progress::Component,
        Bali::Widget::CheckBase => Bali::Widget::Check::Component
      }.freeze

      def card
        klass = CARDS.find { |pattern, _| widget.is_a?(pattern) }&.last ||
                Bali::Widget::Value::Component

        klass.new(widget, size: size)
      end

      # THE ERROR BOUNDARY, around the CARD and not around this component. One
      # tile's failure must not take the page with it, and a tile that VANISHES
      # reads as "nothing to see" — the one thing a failure must not say — so a
      # raising widget gets the degraded body inside its own section.
      #
      # Around the card specifically, because the section carries the tile's
      # whole identity: `data-widget-key`, the drag handle, the size picker, the
      # `inert` target. Unwinding the shell too would leave a failed widget
      # undraggable, unresizable and invisible to the grid's `toArray`.
      #
      # `render` returns the child's markup as a string, so an exception on the
      # way through means nothing was appended — the partial card is discarded
      # rather than left above the apology.
      #
      # HERE and not in the widget. The rescue is a RENDERING concern: "one of
      # twelve tiles must not kill the page" is a fact about the page, and a
      # widget knows nothing about being one of twelve. It raises like any other
      # object; this decides what a page does about it — the same shape as a
      # React error boundary, and as `react-island`'s own.
      #
      # `Unavailable` is caught first and never re-raised: a widget saying "my
      # source is down" reports a fact, not a bug, and a stack trace in
      # development gives a developer nothing to fix.
      #
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — and a forgotten declaration is the
      # most likely way to author a broken widget.
      def card_or_apology
        render card
      rescue Bali::Widget::Unavailable => e
        report(e)
        render self.class.degraded(widget)
      rescue StandardError, NotImplementedError => e
        raise if Rails.env.development?

        report(e)
        render self.class.degraded(widget)
      end

      def card_classes
        class_names(
          "bali-widget-card",
          hero? ? "p-4" : "p-6",
          options[:class]
        )
      end

      def card_attributes
        options.except(:class)
      end

      # Tagged by widget key so an error reporter groups these per tile rather
      # than piling every widget's failure under one controller action.
      def report(error)
        Sentry.capture_exception(error, tags: { widget: key }) if defined?(Sentry)
        Rails.logger.error(
          "[bali/widget] #{key} failed to load — #{error.class}: #{error.message}\n" \
          "#{error.backtrace&.first(5)&.join("\n")}"
        )
      end
    end
  end
end
