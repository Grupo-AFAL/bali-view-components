# frozen_string_literal: true

module Bali
  # Dashboard widgets: the contract a host's widget classes implement, and the
  # value objects they return. `Bali::Widget::Component` renders one of them and
  # `Bali::WidgetGrid::Component` arranges many.
  #
  # This file exists so the namespace is EXPLICIT and can hold constants —
  # without it Zeitwerk would define `Bali::Widget` implicitly from the two
  # directories that extend it (`app/lib/bali/widget/` and
  # `app/components/bali/widget/`) and `SIZES` would have nowhere to live.
  module Widget
    # DELIBERATELY UNAVAILABLE, as opposed to broken. A widget raises this when
    # its data source is known to be down — an upstream API returning 503, a
    # feature switched off mid-request — and the card degrades WITHOUT
    # re-raising in development, because there is no bug for a developer to fix.
    #
    # Every other exception is a bug: loud in development, degraded in
    # production. This is the one a host can throw on purpose.
    Unavailable = Class.new(StandardError)

    # Semantic, not Tailwind — and 2-D, adapted from iOS: `small` is 1x1,
    # `medium` 2x1, `large` 2x2. `large` is `medium`'s WIDTH at double HEIGHT,
    # which is why it earns more rows rather than wider ones.
    #
    # THREE, not four. A `wide` 4x2 shipped briefly and was cut: it was the only
    # size needing a second layout branch in the card, its own row budget and its
    # own pair of grid rules, and its two columns collapsed below `lg` anyway —
    # which is most tablet use. Three sizes carry the whole ladder argument.
    #
    # A stored row still saying "wide" is harmless: `Base#with_size` falls back to
    # the widget's own size for a name it does not recognise, which is exactly the
    # case it was written for.
    SIZES = %i[small medium large].freeze

    # Largest first, so `find` returns the biggest unit that applies. Stops at
    # billions: a dashboard tile showing a trillion of anything has a bigger
    # problem than its formatting.
    ABBREVIATIONS = [ [ 1_000_000_000, "B" ], [ 1_000_000, "M" ], [ 1_000, "k" ] ].freeze

    # Subtitles read "A · B" everywhere. The separator lives here rather than
    # baked into translator-editable strings.
    SEPARATOR = " · "

    class << self
      # The small card is ~215px wide and draws its headline at `text-4xl`, which
      # gives it roughly 4-6 characters before the number runs off the tile. This
      # is what keeps a count of 1_234_567 from doing that.
      #
      # One decimal at most, and a trailing ".0" is dropped — "1k" reads better
      # than "1.0k" and both fit, so the shorter one wins.
      def abbreviate(number)
        value = number.to_i
        # Destructuring nil gives two nils, so the guard below still reads.
        threshold, suffix = ABBREVIATIONS.find { |limit, _| value.abs >= limit }
        return value.to_s if threshold.nil?

        scaled = (value.to_f / threshold).round(1)
        # "1k" over "1.0k": both fit, and the shorter one reads better.
        scaled = scaled.to_i if (scaled % 1).zero?
        "#{scaled}#{suffix}"
      end

      # "3 left · Cocina". Blank parts drop out, so a row with only one half does
      # not render a dangling separator.
      def join(*parts) = parts.compact_blank.join(SEPARATOR)

      # Whether a widget whose data read raises should take the request down with
      # it. True in development and test, so a widget bug is loud where someone
      # can fix it — this is what keeps `Base#safely` from being the blanket kind
      # of rescue that turns a bug into a permanent shrug. False in production,
      # where the person looking at the dashboard cannot fix it and the other
      # tiles are still worth rendering.
      #
      # A method, not a constant: `Rails.env` is read per call, so a test can
      # stub this without freezing the answer at boot.
      def raise_load_errors? = Rails.env.local?

      # THE GATE. Un-loaded widget instances, so it costs only whatever the
      # host's `authorized?` costs — never a widget query.
      #
      # IDEMPOTENT, deliberately: every boundary that takes an `offering:` runs
      # this on what it is handed — `Store`, `Layout.from`, `Layout.chosen` — so
      # a host that filters first pays only for the extra predicate calls, and
      # one that forgets cannot widen the boundary.
      def authorized_for(widgets)
        widgets.select(&:authorized?)
      end
    end
  end
end
