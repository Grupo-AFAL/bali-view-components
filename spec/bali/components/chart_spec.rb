# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Chart::Component, type: :component do
  let(:component) { Bali::Chart::Component.new(**@options) }

  before { @options = { data: { chocolate: 3 } } }

  subject { page }

  it 'renders a chart title' do
    @options.merge!(title: 'Chocolate Sales', id: 'chocolate-sales')
    render_inline(component)

    is_expected.to have_css 'h3.title', text: 'Chocolate Sales'
  end

  it 'renders a div with chart controller' do
    render_inline(component)

    expect(page).to have_css 'canvas.chart'
    expect(page).to have_css 'canvas[data-controller="chart"]'
  end

  it 'renders a line chart' do
    @options.merge!(type: :line)
    render_inline(component)

    expect(page).to have_css 'canvas[data-chart-type-value="line"]'
  end

  it 'renders a pie chart' do
    @options.merge!(type: :pie)
    render_inline(component)

    expect(page).to have_css 'canvas[data-chart-type-value="pie"]'
  end

  it 'renders a bar chart' do
    @options.merge!(type: :bar)
    render_inline(component)

    expect(page).to have_css 'canvas[data-chart-type-value="bar"]'
  end

  it 'renders a doughnut chart' do
    @options.merge!(type: :doughnut)
    render_inline(component)

    expect(page).to have_css 'canvas[data-chart-type-value="doughnut"]'
  end

  it 'renders a polarArea chart' do
    @options.merge!(type: :polarArea)
    render_inline(component)

    expect(page).to have_css 'canvas[data-chart-type-value="polarArea"]'
  end
end
