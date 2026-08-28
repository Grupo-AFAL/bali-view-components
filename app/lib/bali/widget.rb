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

    # TWO WIDGETS, ONE KEY. A key is the class name without its namespace, so
    # `Reports::Overdue` and `Tasks::Overdue` collide — and an offering indexed
    # by key would silently keep the last, dropping a widget from the picker and
    # rendering the survivor's data under the other's stored rows.
    #
    # Loud, because it is a data-integrity bug that looks like a display bug.
    class DuplicateKey < StandardError
      def initialize(keys, widgets)
        classes = widgets.select { |w| keys.include?(w.key) }.map { |w| w.class.name || w.class }.uniq
        super(
          "two widgets share the key #{keys.map(&:inspect).join(', ')} — #{classes.join(', ')}. " \
          "A key is the class name without its namespace, so these collide. " \
          "Declare one explicitly: `key \"something_else\"`."
        )
      end
    end

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

      # THE GATE. Un-loaded widget instances, so it costs only whatever the
      # host's `authorized?` costs — never a widget query.
      #
      # IDEMPOTENT, deliberately: every boundary that takes an `offering:` runs
      # this on what it is handed — the `Store` constructor, `arrange`, `choose`
      # and every host controller filtering params — so a host that filters
      # first pays only for the extra predicate calls, and one that forgets
      # cannot widen the boundary.
      def authorized_for(widgets)
        widgets.select(&:authorized?)
      end

      # THE AUTHORIZED SET, INDEXED. Every boundary that turns a submitted or
      # stored key into a widget looks it up HERE — never by checking it against
      # a permitted list — so an unauthorized, retired or hand-edited key simply
      # finds nothing. Gated on the way in, like everything that takes an
      # offering, so a caller cannot widen the boundary by forgetting to filter.
      #
      # AND IT REFUSES TO INDEX A COLLISION. Keys are demodulized, so
      # `Reports::Overdue` and `Tasks::Overdue` derive the same one — and
      # indexing would silently keep the last, dropping a widget from the picker
      # and rendering the survivor's data under the other's stored rows.
      def by_key(widgets)
        gated = authorized_for(widgets)
        # TWO DIFFERENT CLASSES, not the same one twice. A repeated key is an
        # ordinary submission — a picker can send one, and `Store#choose` dedupes
        # it by design. Only distinct classes colliding is the data-integrity bug.
        clashing = gated.group_by(&:key).select { |_, group| group.map(&:class).uniq.many? }.keys
        raise DuplicateKey.new(clashing, gated) if clashing.any?

        gated.index_by(&:key)
      end
    end
  end
end
