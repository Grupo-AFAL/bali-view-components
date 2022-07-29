# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Heatmap::Component, type: :component do
  before do
    data = {
      Dom: { 0 => 0, 1 => 10, 2 => 3 },
      Lun: { 0 => 3, 1 => 1, 2 => 6 },
      Mar: { 0 => 2, 1 => 1, 2 => 4 }
    }

    @options = { data: data }
  end

  let(:component) { Bali::Heatmap::Component.new(**@options) }

  it 'renders' do
    render_inline(component)

    expect(page).to have_css 'div.heatmap-component'
    expect(page).to have_css 'td', text: 'Dom'
    expect(page).to have_css 'td', text: 'Lun'
    expect(page).to have_css 'td', text: 'Mar'
  end
end
