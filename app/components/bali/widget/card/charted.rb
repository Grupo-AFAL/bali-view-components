# frozen_string_literal: true

module Bali
  module Widget
    module Card
      # THE CONTEXT REGION for the two types that have one. The card-side twin of
      # `Bali::Widget::Charted`, which is the widget-side declaration — this one
      # turns the resulting `Series` into a chart.
      #
      # `Bali::Chart` at every size, configured axis-less below `large`: a
      # sparkline is a chart that has given up its axes, not a different
      # component.
      module Charted
        # What turns a chart into a sparkline. The library is already dynamically
        # imported, so reusing it here costs an instance and a canvas rather than
        # a bundle.
        SPARK_OPTIONS = {
          scales: { x: { display: false }, y: { display: false } },
          plugins: { tooltip: { enabled: false } }
        }.freeze

        # NOT `elements: { point: { radius: 0 } }`, which is the obvious spelling
        # and does nothing here: `Chart::Dataset#to_h` writes `pointRadius` onto
        # every line dataset explicitly, and a dataset-level value beats the
        # `elements` default it would otherwise fall back to.
        SPARK_DATASET = { pointRadius: 0, pointHoverRadius: 0 }.freeze

        private

        # A region the widget has nothing to put in is not rendered, and an empty
        # series is a chart with nothing to draw. A hero has no room for one at
        # all.
        def context? = !hero? && charted?

        def context
          render Bali::Chart::Component.new(
            type: series.type, height: :fit, legend: false,
            aria_label: short_title, data: chart_data, options: chart_options
          )
        end

        def charted? = series&.charted? || false

        def series = @series ||= widget.series

        def chart_options
          return SPARK_OPTIONS.deep_dup if spark?

          # `precision: 0` when every value is a whole number, because most
          # widget series are COUNTS and Chart.js's default tick algorithm
          # happily offers "1.6" of them. Inferred rather than configured: a
          # widget charting integers never wants fractional ticks, so there is
          # nothing to ask it.
          { plugins: { tooltip: { enabled: true } } }.tap do |options|
            options[:scales] = { y: { ticks: { precision: 0 } } } if whole_numbers?
          end
        end

        def whole_numbers?
          series.values.all? { |value| value.is_a?(Integer) || value.to_f % 1 == 0 }
        end

        def chart_data
          dataset = { label: short_title, data: series.values }
          dataset = dataset.merge(SPARK_DATASET) if spark?

          { labels: series.labels, datasets: [ dataset ] }
        end
      end
    end
  end
end
