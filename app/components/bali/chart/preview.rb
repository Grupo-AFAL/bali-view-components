# frozen_string_literal: true

module Bali
  module Chart
    class Preview < ApplicationViewComponentPreview
      DATA_FORMAT_1 = { Mobile: 70, Desktop: 30 }.freeze

      DATA_FORMAT_2 = {
        labels: ['Wed, 12 Jan 2022', 'Thu, 13 Jan 2022'],
        datasets: [{ label: 'Res', data: [10, 5] }, { label: 'Cerdo', data: [20, 10] }]
      }.freeze

      def bar(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_2, type: :bar, id: id)
      end

      def bar_with_percent(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_1, type: :bar, id: id, display_percent: true)
      end

      def line(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_2, type: :line, id: id)
      end

      def pie(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_1, id: id, type: :pie, legend: true)
      end

      def two_lines(id: 'chart')
        render Chart::Component.new(
          data: DATA_FORMAT_2, id: id, type: ["line", "line"], legend: true
        )
      end

      def stacked_bar_line(id: 'chart')
        render Chart::Component.new(
          data: DATA_FORMAT_2, id: id, type: ["bar", "line"], legend: true
        )
      end

      def doughnut(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_1, id: id, type: :doughnut, legend: true)
      end

      def polar_area(id: 'chart')
        render Chart::Component.new(data: DATA_FORMAT_1, id: id, type: :polarArea, legend: true)
      end

      def stacked(id: 'chart')
        render Chart::Component.new(
          data: DATA_FORMAT_2, id: id, type: :bar, legend: true,
          options: { scales: { x: { stacked: true, }, y: { stacked: true } } }
        )
      end

      def multiple_axis(id: 'chart', type: [:bar, :line], title: 'Title')
        render Chart::Component.new(
          id: id, title: title, data: DATA_FORMAT_2, type: type, y_axis_ids: ['y_1', 'y_2'], order: [1, 0],
          options: {
            scales: {
              y_1: { type: 'linear', position: 'left', title: { display: true, text: 'Axis 1' } },
              y_2: { type: 'linear', position: 'right', title: { display: true, text: 'Axis 2' } }
            }
          })
      end

      def customize_axes_and_tooltip(id: 'chart', type: [:bar, :line], title: 'Title')
        render Chart::Component.new(
          id: id, title: title, data: DATA_FORMAT_2, type: type, y_axis_ids: ['y_1', 'y_2'], order: [1, 0],
          options: {
            interaction: { intersect: false, mode: :index },
            plugins: { tooltip: { callbacks: { label: { y_1: { suffix: '%' }, y_2: { prefix: '$' } } } } },
            scales: {
              y_1: {
                type: 'linear', position: 'left', label: { suffix: '%' },
                title: { display: true, text: 'Axis 1' }
              },
              y_2: {
                type: 'linear', position: 'right', label: { prefix: '$' },
                title: { display: true, text: 'Axis 2' }
              }
            }
          })
      end

      def chart_js_data_structures(id: 'chart')
        render_with_template(
          template: 'bali/chart/previews/chart_js_data_structures'
        )
      end

      def chart_js_bar_chart_samples(id: 'chart')
        render_with_template(
          template: 'bali/chart/previews/chart_js_bar_chart_samples'
        )
      end

      def chart_js_line_chart_samples(id: 'chart')
        render_with_template(
          template: 'bali/chart/previews/chart_js_line_chart_samples'
        )
      end

      def chart_js_other_charts_samples(id: 'chart')
        render_with_template(
          template: 'bali/chart/previews/chart_js_other_charts_samples'
        )
      end
    end
  end
end
