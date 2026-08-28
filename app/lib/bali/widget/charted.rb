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
    module Charted
      extend ActiveSupport::Concern

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

        def type(value) = @type = value

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
