# frozen_string_literal: true

module Bali
  module Chart
    class Preview < ApplicationViewComponentPreview
      # Sample data for simple charts (single dataset)
      SIMPLE_DATA = { Mobile: 70, Desktop: 30 }.freeze

      # Sample data for multi-series charts
      MULTI_SERIES_DATA = {
        labels: ['Wed, 12 Jan 2022', 'Thu, 13 Jan 2022'],
        datasets: [{ label: 'Beef', data: [10, 5] }, { label: 'Pork', data: [20, 10] }]
      }.freeze

      # Richer sample data for demos
      WEEKLY_DATA = {
        labels: %w[Mon Tue Wed Thu Fri Sat Sun],
        datasets: [
          { label: 'Sales', data: [120, 190, 300, 250, 420, 380, 290] },
          { label: 'Returns', data: [20, 30, 25, 35, 40, 25, 15] }
        ]
      }.freeze

      # @param type select { choices: [bar, line, pie, doughnut, polarArea] }
      # @param card_style select { choices: [default, bordered, compact, none] }
      # @param height select { choices: [sm, md, lg, xl] }
      # @param legend toggle
      # @param display_percent toggle
      def default(type: :bar, card_style: :default, height: :md, legend: false, display_percent: false)
        data = %w[pie doughnut polarArea].include?(type.to_s) ? SIMPLE_DATA : WEEKLY_DATA

        render Chart::Component.new(
          data: data,
          type: type.to_sym,
          card_style: card_style.to_sym,
          height: height.to_sym,
          legend: legend,
          display_percent: display_percent
        )
      end

      # @label With Color
      # `color:` names the DaisyUI colour the palette starts from, so a
      # single-series chart is painted in it and a multi-series one cycles from
      # it. `custom_color:` takes a hex and drops the theme palette entirely —
      # a canvas cannot resolve a `var()`, so a chart cannot mix the two.
      # @param color select { choices: [neutral, primary, secondary, accent, info, success, warning, error, ghost] }
      # @param custom_color text
      def with_color(color: :success, custom_color: nil)
        render Chart::Component.new(
          data: WEEKLY_DATA,
          type: :bar,
          card_style: :bordered,
          legend: true,
          color: color.to_sym,
          custom_color: custom_color.presence
        )
      end

      # @label Series Palette
      # One series per theme colour, in the order a multi-series chart hands
      # them out (`Bali::Color::CYCLE`). An eighth series would start over at
      # the first.
      # @param type select { choices: [bar, line] }
      def series_palette(type: :bar)
        render Bali::Chart::Component.new(
          data: {
            labels: %w[Q1 Q2 Q3 Q4],
            datasets: (1..7).map { |n| { label: "Series #{n}", data: [n + 3, n + 6, n + 4, n + 8] } }
          },
          type: type.to_sym,
          card_style: :bordered,
          legend: true
        )
      end

      # @label Own Colours
      # A series whose own `borderColor:` is a literal colour is not repainted
      # from the theme: on a line its points and legend swatch take its
      # `backgroundColor:`, or that border when it gives no fill. A
      # `var(--color-*)` border is repainted by position, fill and points
      # included: the third series is not red.
      def own_colors
        render Bali::Chart::Component.new(
          data: {
            labels: %w[Jan Feb Mar Apr May],
            datasets: [
              { label: 'Border only', data: [12, 15, 13, 18, 16], borderColor: '#2563eb' },
              { label: 'Border and fill', data: [8, 9, 11, 10, 12],
                borderColor: '#16a34a', backgroundColor: 'rgba(22, 163, 74, 0.5)' },
              { label: 'Theme border, own fill', data: [4, 6, 5, 7, 6],
                borderColor: Bali::Color.css(:error), backgroundColor: 'rgba(220, 38, 38, 0.5)' }
            ]
          },
          type: :line,
          card_style: :bordered,
          legend: true
        )
      end

      # @label Accessible Data Table
      # A canvas is pixels: `role="img"` and a name are all the accessibility
      # tree gets from it, and neither carries a number. The `data_table` slot
      # renders a visually hidden table (Bali's `.chart-fallback-table`) with
      # the same figures — the only way a screen reader user reads a value off
      # the chart, and the chart's no-JS fallback: with scripting off the table
      # is revealed in place of the empty canvas box (#1067).
      def with_data_table
        render_with_template
      end

      # @label With Title
      # Chart wrapped in a card with a title header.
      def with_title
        render Chart::Component.new(
          data: WEEKLY_DATA,
          type: :bar,
          title: 'Weekly Sales Report',
          legend: true
        )
      end

      # @label Stacked Bar
      # Stacked bar chart with multiple datasets.
      def stacked
        render Chart::Component.new(
          data: MULTI_SERIES_DATA,
          type: :bar,
          legend: true,
          options: { scales: { x: { stacked: true }, y: { stacked: true } } }
        )
      end

      # @label Mixed Types
      # Combine bar and line charts in a single visualization.
      def mixed_types
        render Chart::Component.new(
          data: MULTI_SERIES_DATA,
          type: %i[bar line],
          legend: true
        )
      end

      # @label Multiple Y-Axes
      # Chart with two Y-axes for comparing different scales.
      def multiple_axes
        render Chart::Component.new(
          title: 'Dual Axis Chart',
          data: MULTI_SERIES_DATA,
          type: %i[bar line],
          y_axis_ids: %w[y_1 y_2],
          order: [1, 0],
          options: {
            scales: {
              y_1: { type: 'linear', position: 'left', title: { display: true, text: 'Axis 1' } },
              y_2: { type: 'linear', position: 'right', title: { display: true, text: 'Axis 2' } }
            }
          }
        )
      end

      # @label Custom Tooltips
      # Customized tooltip with prefix/suffix formatting.
      def custom_tooltips
        render Chart::Component.new(
          title: 'Custom Tooltips',
          data: MULTI_SERIES_DATA,
          type: %i[bar line],
          y_axis_ids: %w[y_1 y_2],
          order: [1, 0],
          options: {
            interaction: { intersect: false, mode: :index },
            plugins: { tooltip: { callbacks: { label: { y_1: { suffix: '%' }, y_2: { prefix: '$' } } } } },
            scales: {
              y_1: {
                type: 'linear', position: 'left', label: { suffix: '%' },
                title: { display: true, text: 'Percentage' }
              },
              y_2: {
                type: 'linear', position: 'right', label: { prefix: '$' },
                title: { display: true, text: 'Revenue' }
              }
            }
          }
        )
      end

      # @label String Keys
      # The multi-series format written with string keys — what a payload that has
      # round-tripped through JSON looks like. It charts identically to the symbol
      # form; it used to be read as two categories named "labels" and "datasets".
      def with_string_keys
        render Chart::Component.new(
          data: {
            'labels' => %w[Mon Tue Wed Thu Fri],
            'datasets' => [
              { 'label' => 'Sales', 'data' => [120, 190, 300, 250, 420] },
              { 'label' => 'Returns', 'data' => [20, 30, 25, 35, 40] }
            ]
          },
          type: :bar,
          legend: true,
          card_style: :bordered
        )
      end

      # @label Chart.js Data Structures
      # Reference documentation for Chart.js data structures.
      def chart_js_data_structures
        render_with_template(
          template: 'bali/chart/previews/chart_js_data_structures'
        )
      end

      # @label Bar Chart Samples
      # Various bar chart configurations from Chart.js.
      def chart_js_bar_chart_samples
        render_with_template(
          template: 'bali/chart/previews/chart_js_bar_chart_samples'
        )
      end

      # @label Line Chart Samples
      # Various line chart configurations from Chart.js.
      def chart_js_line_chart_samples
        render_with_template(
          template: 'bali/chart/previews/chart_js_line_chart_samples'
        )
      end

      # @label Other Chart Types
      # Pie, doughnut, and polar area chart samples.
      def chart_js_other_charts_samples
        render_with_template(
          template: 'bali/chart/previews/chart_js_other_charts_samples'
        )
      end
    end
  end
end
