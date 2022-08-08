# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::GanttChart::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::GanttChart::Component.new(**options) }

  it 'renders gantt chart component' do
    render_inline(component)

    expect(page).to have_css 'div.gantt-chart-component'
  end
end
