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
