# frozen_string_literal: true

module Bali
  module Widget
    # A FIGURE AND HOW IT MOVED, with the history behind it.
    #
    #   class StudioFoundings < Bali::Widget::TrendBase
    #     default_size :medium
    #
    #     trend do |t|
    #       t.current  { decades.values.last }
    #       t.previous { decades.values[-2] }
    #       t.period_label "vs previous decade"
    #     end
    #
    #     series do |s|
    #       s.labels { decades.keys.map(&:to_s) }
    #       s.values { decades.values }
    #     end
    #   end
    #
    # The base computes the delta. Every trend widget was hand-rolling
    # `(((latest - previous) / previous.to_f) * 100).round`; it is written once
    # here, and `current` / `previous` is a contract you cannot half-implement.
    class TrendBase < Base
      include Charted

      Trend = Data.define(:delta, :direction, :period, :positive_when, :unit) do
        def initialize(delta:, direction: nil, period: nil, positive_when: :up, unit: "%")
          super(delta: delta, direction: direction || (delta.to_f.negative? ? :down : :up),
                period: period, positive_when: positive_when, unit: unit)
        end

        # WHAT THE CARD COLOURS FROM, and never `direction`. Overdue tasks up 12%
        # and revenue up 12% are opposite news; a card reading the direction would
        # paint half a dashboard's trends the wrong way while looking confident.
        #
        # A flat trend is never good: no change is not news worth painting green.
        def good? = !flat? && direction == positive_when

        def flat? = delta.to_f.zero?
      end

      # What `trend` yields — the two figures, and how the movement between them
      # reads. Each setter writes its OWN ivar, so two `trend` blocks merge per
      # field, the same rule as `row`, `series` and `goal`.
      class TrendBuilder
        def initialize
          @positive_when = :up
        end

        def current(value = nil, &block) = @current = block || value

        # What `current` is compared against. NIL means the trend is ABSENT
        # rather than zero — a widget's first week has no previous period, and
        # the card drops the indicator rather than drawing a flat 0%.
        def previous(value = nil, &block) = @previous = block || value

        # `:up` unless the widget says otherwise. A widget counting something BAD
        # — overdue work, low stock — says `:down`, and a rising number then reads
        # red. Getting this wrong makes the card lie confidently, which is why it
        # is declared rather than guessed.
        def positive_when(value) = @positive_when = value

        # "vs last week". What `current` is being compared against, in words.
        def period_label(value) = @period_label = value

        # Reads through the widget's memoised `#current`/`#previous`, never its
        # own `resolved_*` — those exist only for those readers to call.
        def to_trend(widget)
          before = widget.previous
          return if before.nil? || before.to_f.zero?

          Trend.new(delta: (((widget.current - before) / before.to_f) * 100).round,
                    period: @period_label, positive_when: @positive_when)
        end

        def resolved_current(widget) = resolve(widget, @current)

        def resolved_previous(widget) = resolve(widget, @previous)

        # Called from `count`, which the card reads at every size.
        def check!(widget_class)
          return if @current

          raise NotImplementedError,
                "#{widget_class.name || 'This widget'} must declare " \
                "`t.current` in its `trend` block."
        end

        private

        # A BLOCK runs against the WIDGET, so it reaches `context`, route helpers
        # and private methods; anything else is the value itself.
        def resolve(widget, field)
          field.is_a?(Proc) ? widget.instance_exec(&field) : field
        end
      end
      private_constant :TrendBuilder

      # HOW THE MOVEMENT READS.
      declares :trend, hint: "trend { |t| t.current { Item.count } }" do
        TrendBuilder.new
      end

      # READERS over the declaration. Memoised with `defined?` rather than `||=`,
      # because NIL is a documented answer here rather than an edge case: a
      # widget's first period has no `previous`, the generator scaffolds
      # `t.previous { nil }`, and `||=` would re-run that block on every read.
      # CHECKS HERE, not only in `#trend`. `count` reads this and the card's
      # `before_render` always reads `count` — at every size — so validating here
      # is what makes a missing `t.current` degrade the tile rather than print a
      # confident zero. Guarding only `#trend` left `:small` unprotected: the hero
      # branch decides on `failed?` before it ever asks `trend?`, so the failure
      # was discovered after the card had already committed to looking healthy.
      def current
        return @current if defined?(@current)

        trend_builder.check!(self.class)
        @current = trend_builder.resolved_current(self)
      end

      def previous
        return @previous if defined?(@previous)

        @previous = trend_builder.resolved_previous(self)
      end

      # `to_i` because a widget with no data at all has a nil `current`, and the
      # card asks `count.positive?`.
      def count = @count ||= current.to_i

      def display_value = Bali::Widget.abbreviate(count)

      # NON-ZERO, not positive. A trend reporting -12 has news; only a figure of
      # zero is the ambiguous "nothing happened" the card dims.
      def any? = !current.to_i.zero?

      # Memoised: the card asks `trend?` and then renders `trend`, and a nil trend
      # — the documented no-previous-period state — is what `||=` could not hold.
      def trend
        return @trend if defined?(@trend)

        trend_builder.check!(self.class)
        @trend = trend_builder.to_trend(self)
      end

      private

      def trend_builder
        _trend_builder || raise(NotImplementedError,
                                "#{self.class.name || 'This widget'} must declare `trend`.")
      end
    end
  end
end
