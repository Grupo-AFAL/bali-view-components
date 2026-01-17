# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Chart::Component, type: :component do
  let(:component) { described_class.new(**options) }
  let(:options) { { data: { chocolate: 3 } } }

  describe 'rendering' do
    it 'renders a chart title with Tailwind classes' do
      render_inline(described_class.new(data: { chocolate: 3 }, title: 'Chocolate Sales',
                                        id: 'chocolate-sales'))

      expect(page).to have_css 'h3.text-lg.font-semibold', text: 'Chocolate Sales'
    end

    it 'renders a div with chart controller' do
      render_inline(component)

      expect(page).to have_css 'canvas.chart'
      expect(page).to have_css 'canvas[data-controller="chart"]'
    end

    it 'renders without title when not provided' do
      render_inline(component)

      expect(page).not_to have_css 'h3'
    end
  end

  describe 'chart types' do
    it 'renders a bar chart by default' do
      render_inline(component)

      expect(page).to have_css 'canvas[data-chart-type-value="bar"]'
    end

    it 'renders a line chart' do
      render_inline(described_class.new(data: { chocolate: 3 }, type: :line))

      expect(page).to have_css 'canvas[data-chart-type-value="line"]'
    end

    it 'renders a pie chart' do
      render_inline(described_class.new(data: { chocolate: 3 }, type: :pie))

      expect(page).to have_css 'canvas[data-chart-type-value="pie"]'
    end

    it 'renders a doughnut chart' do
      render_inline(described_class.new(data: { chocolate: 3 }, type: :doughnut))

      expect(page).to have_css 'canvas[data-chart-type-value="doughnut"]'
    end

    it 'renders a polarArea chart' do
      render_inline(described_class.new(data: { chocolate: 3 }, type: :polarArea))

      expect(page).to have_css 'canvas[data-chart-type-value="polarArea"]'
    end
  end

  describe 'data attributes' do
    it 'includes chart data as JSON' do
      render_inline(component)

      canvas = page.find('canvas.chart')
      expect(canvas['data-chart-data-value']).to include('chocolate')
    end

    it 'includes display percent value when enabled' do
      render_inline(described_class.new(data: { chocolate: 3 }, display_percent: true))

      canvas = page.find('canvas.chart')
      expect(canvas['data-chart-display-percent-value']).to eq('true')
    end
  end

  describe 'constants' do
    it 'has MAX_LABEL_LENGTH constant' do
      expect(described_class::MAX_LABEL_LENGTH).to eq(16)
    end

    it 'has MULTI_COLOR_TYPES constant' do
      expect(described_class::MULTI_COLOR_TYPES).to eq(%i[pie doughnut polarArea])
    end

    it 'has DEFAULT_OPTIONS constant' do
      expect(described_class::DEFAULT_OPTIONS).to eq({ responsive: true,
                                                       maintainAspectRatio: false })
    end
  end

  describe 'options passthrough' do
    it 'accepts custom html attributes' do
      render_inline(described_class.new(data: { chocolate: 3 }, id: 'my-chart',
                                        class: 'custom-class'))

      expect(page).to have_css '.chart-container#my-chart.custom-class'
    end
  end
end
