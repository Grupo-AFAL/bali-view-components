# frozen_string_literal: true

module Bali
  module Widget
    # THE HISTORY BEHIND THE FACT — a sparkline at `medium`, a chart with axes at
    # `large`. Shared by the two patterns that have one, because the declaration
    # and the reading of it were identical in both.
    #
    #   series do |s|
    #     s.labels { decades.keys.map(&:to_s) }
    #     s.values { decades.values }
    #   end
    #
    # A widget with no `series` renders no chart, and the card gives the space to
    # whatever else it has. That is a supported state, not a missing declaration —
    # which is why there is no guard here, unlike `list` and `row`.
    #
    # A MODULE, not a `ChartedBase` in the chain. `*Base` is host-facing
    # vocabulary and THE PATTERN IS THE TYPE, so another one would read as
    # another pattern to inherit from — but nothing inherits from this. It is a
    # capability two patterns have, and a mixin keeps it available to a third:
    # a list widget wanting a sparkline is `include Charted`, not a re-parenting
    # `ListBase` could not do anyway.
    module Charted
      extend ActiveSupport::Concern

      # WHAT A WIDGET CARD CAN ACTUALLY DRAW, which is narrower than what
      # `Bali::Chart` accepts. Unvalidated, a typo emits a canvas with
      # `chart-type-value="banana"` — a blank tile and a console error.
      #
      # `:line` and `:bar` are the two that survive the size ladder. Both have
      # axes for `SPARK_OPTIONS` to strip below `large`, and both still read at a
      # 2x1. The axis-less types Chart.js offers — `pie`, `doughnut`, `polarArea`
      # — do not: a pie in a sparkline slot beside a headline is a smudge, and
      # the card's `whole_numbers?` tick precision is meaningless for one.
      TYPES = %i[line bar].freeze

      # `charted?` rather than `values.any?` at the call site: an empty series is
      # a chart with nothing to draw, and the card should skip the region rather
      # than render an empty canvas.
      Series = Data.define(:labels, :values, :type) do
        def initialize(values:, labels: [], type: :line) = super

        def charted? = values.present?
      end

      # What `series` yields. Each setter writes its OWN ivar, so two `series`
      # blocks merge per field rather than the second replacing the first — the
      # same rule as `row`.
      class SeriesBuilder < Builder
        def initialize(type)
          @type = type
        end

        # A block is `instance_exec`'d on the WIDGET, so it reaches `context` and
        # private methods; anything else is the value itself, which is what lets a
        # fixed series be written `s.values [ 1, 2, 3 ]`.
        def labels(value = nil, &block) = @labels = block || value

        def values(value = nil, &block) = @values = block || value

        # Validated where it is written, so a typo is a boot failure rather than
        # a blank tile — the same bargain `default_size` and `supports` make.
        def type(value)
          unless TYPES.include?(value)
            raise ArgumentError,
                  "unknown series type #{value.inspect} — a widget card draws #{TYPES.join(' or ')}."
          end

          @type = value
        end

        def to_series(widget)
          drawn = resolve(widget, @values)
          return if drawn.blank?

          Series.new(values: drawn, labels: resolve(widget, @labels) || [], type: @type)
        end
      end

      included do
        # `:line` for a trend, `:bar` for a breakdown — the including pattern says
        # which, and a widget overrides it with `s.type`.
        #
        # READ WHEN `series` IS FIRST CALLED, not when this module is included, so
        # a pattern setting it must do so in its own class body — before any
        # subclass declares a series. `ProgressBase` does, two lines after
        # `include Charted`.
        class_attribute :_default_series_type, default: :line, **Base::ATTRIBUTE_OPTIONS

        # SEEDED FROM CLASS STATE, which is why `declares` takes a block: the
        # including pattern chooses the default type, and a widget overrides it
        # with `s.type`.
        declares :series, hint: "series { |s| s.values [ 1, 2 ] }" do
          SeriesBuilder.new(_default_series_type)
        end
      end

      # `defined?` rather than `@series ||=`: a widget with no series answers nil,
      # which is the common case and exactly the one `||=` cannot memoise. The
      # card asks five to eight times per tile, each one otherwise re-running both
      # declaration blocks.
      def series
        return @series if defined?(@series)

        @series = _series_builder&.to_series(self)
      end
    end
  end
end
