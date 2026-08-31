# frozen_string_literal: true

module Bali
  # Dashboard widgets: the contract a host's widget classes implement.
  # `Bali::Widget::Component` renders one and `Bali::WidgetGrid::Component`
  # arranges many.
  #
  # This file exists so the namespace is EXPLICIT and can hold constants —
  # otherwise Zeitwerk defines `Bali::Widget` implicitly from the two directories
  # that extend it and `SIZES` has nowhere to live.
  module Widget
    # DELIBERATELY UNAVAILABLE, as opposed to broken — an upstream API returning
    # 503, a feature switched off mid-request. The card degrades without
    # re-raising in development, because there is no bug for a developer to fix.
    # Every other exception is a bug: loud in development, degraded in production.
    Unavailable = Class.new(StandardError)

    # TWO WIDGETS, ONE KEY. Keys are demodulized, so `Reports::Overdue` and
    # `Tasks::Overdue` collide — and an offering indexed by key would silently
    # keep the last, dropping a widget from the picker and rendering the
    # survivor's data under the other's stored rows.
    class DuplicateKey < StandardError
      def initialize(keys, classes)
        classes = classes.select { |klass| keys.include?(klass.key) }.map { |k| k.name || k }.uniq
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
    # A stored row naming a size that no longer exists is harmless: `Placement`
    # falls back to the widget's default for a name it does not recognise.
    SIZES = %i[small medium large].freeze

    # Largest first, so `find` returns the biggest unit that applies.
    ABBREVIATIONS = [ [ 1_000_000_000, "B" ], [ 1_000_000, "M" ], [ 1_000, "k" ] ].freeze

    # Subtitles read "A · B" everywhere. The separator lives here rather than
    # baked into translator-editable strings.
    SEPARATOR = " · "

    class << self
      # The small card is ~215px wide and draws its headline at `text-4xl`,
      # leaving roughly 4-6 characters before the number runs off the tile.
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
      # IDEMPOTENT, deliberately: every boundary taking an `offering:` runs it on
      # what it is handed, so a host that filters first pays only for the extra
      # predicate calls and one that forgets cannot widen the boundary.
      def authorized_for(widgets)
        widgets.select(&:authorized?)
      end

      # THE AUTHORIZED SET, INDEXED. Every boundary that turns a submitted or
      # stored key into a widget looks it up here — never by checking against a
      # permitted list — so an unauthorized, retired or hand-edited key finds
      # nothing.
      #
      # NO COLLISION CHECK HERE. Whether two classes derive the same key is a
      # property of the code, not of the request: it cannot change between calls,
      # and this runs on every store read, every write and every refresh poll.
      # `check_keys!` does it once, where the catalog is declared.
      def by_key(widgets) = authorized_for(widgets).index_by(&:key)

      # RAISES IF TWO CLASSES SHARE A KEY. Called once per catalog — by
      # `dashboard_widgets` at class-definition time, and by
      # `Bali::Testing::WidgetCatalog` — so a collision is a boot failure rather
      # than a wrong dashboard.
      #
      # TWO DIFFERENT CLASSES, not the same one twice. A repeated key is an
      # ordinary submission that `Store#choose` dedupes by design; only distinct
      # classes colliding is the data-integrity bug.
      def check_keys!(classes)
        clashing = classes.group_by { |klass| klass.key }
                          .select { |_, group| group.uniq.many? }
                          .keys
        raise DuplicateKey.new(clashing, classes) if clashing.any?
      end
    end
  end
end
