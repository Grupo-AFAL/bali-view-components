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
    # A MODULE, NOT A `ChartedBase < Base` IN THE CHAIN. `Base → ChartedBase →
    # {TrendBase, ProgressBase}` would work and would keep single inheritance, so
    # this is a judgement rather than a rule:
    #
    #   `*Base` is host-facing vocabulary. `--pattern trend` scaffolds
    #   `TrendBase`, the guide's table lists exactly four, and THE PATTERN IS THE
    #   TYPE. A fifth `*Base` reads as a fifth pattern to inherit from, and
    #   nothing inherits from this — it is a capability two patterns have, not a
    #   kind of widget.
    #
    #   A middle class fixes a taxonomy; a mixin does not. Putting "charted" in
    #   the chain commits to it being a LEVEL. It is not obviously one: a list
    #   widget with a sparkline beside its count is a plausible thing to want, and
    #   that is `include Charted` on `ListBase` — one line. With a middle class it
    #   is a re-parenting, and `ListBase` cannot have two parents.
    #
    # Ruby draws the same line: `Comparable` and `Enumerable` are capabilities,
    # inheritance is taxonomy. The name follows those rather than `Chartable` —
    # a widget that includes this HAS a chart; it is not merely able to have one.
    module Charted
      extend ActiveSupport::Concern

      # WHAT A WIDGET CARD CAN ACTUALLY DRAW, which is narrower than what
      # `Bali::Chart` accepts. `s.type` used to pass straight through to Chart.js
      # unvalidated, so a typo emitted a canvas with `chart-type-value="banana"`
      # — a blank tile and an error in the browser console, the silent failure
      # this feature validates against everywhere else.
      #
      # `:line` and `:bar` are the two that survive the size ladder. Both have
      # axes for `SPARK_OPTIONS` to strip below `large`, and both still read at a
      # 2x1. The axis-less types Chart.js offers — `pie`, `doughnut`, `polarArea`
      # — do not: a pie in a sparkline slot beside a headline is a smudge, and
      # the card's own `whole_numbers?` tick precision is meaningless for one.
      # A host wanting one of those wants `renders_one :body` and its own chart.
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
      class SeriesBuilder
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

        private

        def resolve(widget, field)
          field.is_a?(Proc) ? widget.instance_exec(&field) : field
        end
      end

      included do
        class_attribute :_series_builder, **Base::ATTRIBUTE_OPTIONS
        # `:line` for a trend, `:bar` for a breakdown — the including pattern says
        # which, and a widget overrides it with `s.type`.
        #
        # READ WHEN `series` IS FIRST CALLED, not when this module is included, so
        # a pattern setting it must do so in its own class body — before any
        # subclass declares a series. `ProgressBase` does, two lines after
        # `include Charted`.
        class_attribute :_default_series_type, default: :line, **Base::ATTRIBUTE_OPTIONS
      end

      class_methods do
        # DUPS what it inherits, for the same reason `row` does: `class_attribute`
        # copies on write and never on mutation, so a subclass would otherwise be
        # handed its parent's builder and two siblings would overwrite each other.
        def series(&block)
          raise ArgumentError, "`series` needs a block: `series { |s| s.values [ 1, 2 ] }`." unless block

          self._series_builder = _series_builder&.dup || SeriesBuilder.new(_default_series_type)
          block.call(_series_builder)
        end
      end

      # `defined?` rather than `@series ||=`: a widget with no series answers nil,
      # which is the common case and exactly the one `||=` cannot memoise.
      #
      # The card asks through `series?`, `context?`, `empty_state?`, `detail?` and
      # `context_classes`, then again for `series.type`, the chart data and the
      # tick precision — five to eight times per tile, each rebuilding the object
      # and re-running BOTH declaration blocks.
      def series
        return @series if defined?(@series)

        @series = safely(nil) { _series_builder&.to_series(self) }
      end
    end
  end
end
