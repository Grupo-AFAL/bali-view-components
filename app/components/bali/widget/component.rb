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
      # HOW MANY ROWS EACH CANVAS FITS — the only thing a size says that the size
      # itself does not, and a MEASUREMENT against Bali's own type sizes:
      #
      #   small   a ~215px tile fits one fact and nothing else
      #   medium  fact on the left, three rows or a sparkline on the right
      #   large   fact in a header band, chart under it, seven rows below
      #
      # Truncation lives here rather than in the widget: the widget answers which
      # rows matter, the card answers how many fit.
      #
      # Override per host through `Card::Component.rows_budget`, which is where
      # it is read.
      ROWS = { small: 0, medium: 3, large: 7 }.freeze

      # The `<time>` reads its own age, so it stays honest while a card sits
      # unrefreshed. A minute is as often as "12 minutes ago" can change.
      FRESHNESS_TICK = 60_000

      # WHAT EVERY WIDGET ANSWERS, whatever its pattern — so the shell needs no
      # type check.
      delegate :key, :title, :short_title, :empty_message, :supported_sizes,
               :view_all_path, to: :widget

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
        @size = size&.to_sym || widget.class.default_size
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

      # BOTH HALVES OR NEITHER. A widget that declares an interval on a page that
      # gave no URL cannot poll, and a URL alone has no interval to poll on.
      def refreshes? = refresh_url.present? && widget.refresh_every.present?

      # Milliseconds, because that is what `setTimeout` takes and converting in
      # JS would put a unit conversion on the far side of a `data-` attribute.
      def refresh_interval = (widget.refresh_every * 1000).round

      # HOW OLD THIS CARD IS, and it is present on every refreshing card rather
      # than only on a stale one.
      #
      # A refresh that fails is silent by design — the card keeps showing the
      # last good answer, which is still true, just older. That silence is right
      # for a failure the user cannot act on, and wrong the moment the card
      # starts CLAIMING to be current when it has stopped being so. This is the
      # card refusing to make that claim.
      #
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
