# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Chart::Component, type: :component do
  let(:component) { described_class.new(**options) }
  let(:options) { { data: { chocolate: 3 } } }

  describe 'rendering' do
    it 'renders a chart title with DaisyUI card classes' do
      render_inline(described_class.new(data: { chocolate: 3 }, title: 'Chocolate Sales',
                                        id: 'chocolate-sales'))

      expect(page).to have_css 'h3.card-title', text: 'Chocolate Sales'
      expect(page).to have_css '.card.bg-base-100'
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

  describe 'card styles' do
    it 'renders with default card style' do
      render_inline(described_class.new(data: { chocolate: 3 }))

      expect(page).to have_css '.card.bg-base-100.shadow-sm'
    end

    it 'renders with bordered card style' do
      render_inline(described_class.new(data: { chocolate: 3 }, card_style: :bordered))

      expect(page).to have_css '.card.bg-base-100.card-border'
    end

    it 'renders with compact card style' do
      render_inline(described_class.new(data: { chocolate: 3 }, card_style: :compact))

      expect(page).to have_css '.card.bg-base-100.card-compact'
    end

    it 'renders without card when style is none' do
      render_inline(described_class.new(data: { chocolate: 3 }, card_style: :none))

      expect(page).not_to have_css '.card'
      expect(page).to have_css '.chart-component'
    end
  end

  describe 'height presets' do
    it 'renders with medium height by default' do
      render_inline(described_class.new(data: { chocolate: 3 }))

      expect(page).to have_css '.chart-container.h-\\[250px\\]'
    end

    it 'renders with small height' do
      render_inline(described_class.new(data: { chocolate: 3 }, height: :sm))

      expect(page).to have_css '.chart-container.h-\\[180px\\]'
    end

    it 'renders with large height' do
      render_inline(described_class.new(data: { chocolate: 3 }, height: :lg))

      expect(page).to have_css '.chart-container.h-\\[350px\\]'
    end

    it 'renders with extra large height' do
      render_inline(described_class.new(data: { chocolate: 3 }, height: :xl))

      expect(page).to have_css '.chart-container.h-\\[450px\\]'
    end
  end

  describe 'theme colors' do
    it 'sets use_theme_colors data attribute' do
      render_inline(described_class.new(data: { chocolate: 3 }))

      expect(page).to have_css 'canvas[data-chart-use-theme-colors-value="true"]'
    end

    it 'can disable theme colors' do
      render_inline(described_class.new(data: { chocolate: 3 }, use_theme_colors: false))

      expect(page).to have_css 'canvas[data-chart-use-theme-colors-value="false"]'
    end
  end
end
