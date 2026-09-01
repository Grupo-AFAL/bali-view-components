# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # The shell: it draws the section a tile lives in — the drag handle, the size
    # picker, `data-widget-key` — picks the card for the widget's pattern, and is
    # the ERROR BOUNDARY around it. The card itself draws the body.
    class Component < ApplicationViewComponent
      # The `<time>` reads its own age, so it stays honest while a card sits
      # unrefreshed. A minute is as often as "12 minutes ago" can change.
      FRESHNESS_TICK = 60_000

      # WHAT THE SHELL ITSELF NEEDS, and only that: the key for the DOM id and the
      # payload, the short title for the label, the sizes for the picker.
      # `title`, `empty_message` and `view_all_path` belong to the BODY, and
      # `Card::Component` reaches them on its own.
      delegate :key, :short_title, :supported_sizes, to: :widget

      # SIZE IS TOLD, NOT ASKED — it is a per-owner arrangement fact, not a
      # property of the widget, so the same class is `small` for one person and
      # `large` for another.
      #
      # Defaults to the widget's `default_size`, which is what a preview or a host
      # rendering one card outside an arrangement wants. A stored size arrives
      # through `Bali::Widget::Placement`, which has already resolved a retired or
      # nil one.
      # `refresh_url` is where the card re-fetches itself. Omitted, the card
      # never polls — which is what a preview, a test, or a host rendering one
      # tile outside a dashboard wants, and why a widget declaring
      # `refresh_every` in those places degrades to static rather than erroring.
      def initialize(widget, size: nil, refresh_url: nil, **options)
        @widget = widget
        @size = resolve_size(size, widget)
        @refresh_url = refresh_url
        # WHEN THIS ANSWER WAS TRUE. Stamped at construction rather than read in
        # the template, so a card and its own freshness claim cannot disagree.
        @rendered_at = Time.current
        @options = options
        super()
      end

      # A STABLE DOM ID so a host — or the grid's own resize — can replace one
      # card from a Turbo Stream. Public: the one thing about a card a host
      # outside this component needs to name.
      def self.dom_id(key) = "bali-widget-#{key}"

      private

      attr_reader :widget, :size, :refresh_url, :rendered_at, :options

      # THROUGH `Placement`, which already owns this rule — a host can reach this
      # constructor directly (`grid.with_widget(widget, size: :bogus)`), and a
      # size the widget does not support renders a radiogroup with no checked
      # button and so no tab stop: a control nobody can reach by keyboard.
      # Restating the rule here is how the two drift apart.
      def resolve_size(size, widget) = Bali::Widget::Placement.new(widget: widget, size: size).size

      # BOTH HALVES OR NEITHER. A widget that declares an interval on a page that
      # gave no URL cannot poll, and a URL alone has no interval to poll on.
      def refreshes? = refresh_url.present? && widget.refresh_every.present?

      # Milliseconds, because that is what `setTimeout` takes and converting in
      # JS would put a unit conversion on the far side of a `data-` attribute.
      def refresh_interval = (widget.refresh_every * 1000).round

      def dom_id = self.class.dom_id(key)

      # A radiogroup with one option is not a choice. A widget that offers a
      # single size gets no picker rather than a picker that cannot do anything.
      def resizable? = supported_sizes.many?

      # The hero is a tighter card — one fact needs less room around it than a
      # header, a chart and a breakdown do.
      def hero? = size == :small

      # WHICH CARD DRAWS THIS WIDGET — the one place the shell asks what kind of
      # widget it holds, and it asks the widget's own class, so a host's subclass
      # of a pattern gets that pattern's card for free. `Value` is the fallback,
      # needing only `count` and `display_value`.
      def card
        klass = case widget
        when Bali::Widget::ListBase then Bali::Widget::List::Component
        when Bali::Widget::TrendBase then Bali::Widget::Trend::Component
        when Bali::Widget::ProgressBase then Bali::Widget::Progress::Component
        when Bali::Widget::CheckBase then Bali::Widget::Check::Component
        else Bali::Widget::Value::Component
        end

        klass.new(widget, size: size)
      end

      # THE ERROR BOUNDARY, around the CARD and not around this component. A tile
      # that VANISHES reads as "nothing to see" — the one thing a failure must not
      # say — so a raising widget gets the degraded body inside its own section.
      #
      # Around the card specifically, because the section carries the tile's
      # identity: `data-widget-key`, the drag handle, the size picker, the `inert`
      # target. Unwinding the shell too would leave a failed widget undraggable,
      # unresizable and invisible to the grid's `toArray`.
      #
      # `render` returns the child's markup as a string, so an exception on the
      # way through means nothing was appended — the partial card is discarded
      # rather than left above the apology.
      #
      # `Unavailable` is caught first and never re-raised: "my source is down" is
      # a fact, not a bug, and a stack trace gives a developer nothing to fix.
      #
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — and a forgotten declaration is the
      # likeliest way to author a broken widget.
      def card_or_apology
        render card
      rescue Bali::Widget::Unavailable => e
        report(e)
        render Bali::Widget::Degraded::Component.new(widget)
      rescue StandardError, NotImplementedError => e
        raise if Rails.env.development?

        report(e)
        render Bali::Widget::Degraded::Component.new(widget)
      end

      def card_classes
        class_names(
          "bali-widget-card",
          hero? ? "p-4" : "p-6",
          options[:class]
        )
      end

      # THROUGH `prepend_*`, not written separately in the template. The refresh
      # wiring is `data-controller` and two values, and a host may pass its own
      # `data: { controller: "my-tooltip" }` for the same tile. Emitting both
      # produces a duplicate attribute: the parser keeps the FIRST and the host's
      # controller never connects, with no error anywhere. `WidgetGrid::Component`
      # already composes its own wiring this way.
      def card_attributes
        attributes = options.except(:class)
        return attributes unless refreshes?

        attributes = prepend_controller(attributes, "bali-widget-refresh")
        prepend_values(attributes, "bali-widget-refresh",
                       url: refresh_url, interval: refresh_interval)
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
