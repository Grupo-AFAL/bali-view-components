# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::LabelValue::Component, type: :component do
  let(:options) { { label: 'Name', value: 'Juan Perez' } }
  let(:component) { Bali::LabelValue::Component.new(**options) }

  it 'renders LabelValue component' do
    render_inline(component)

    expect(page).to have_css 'div.label-value-component'
    expect(page).to have_css 'label.text-xs', text: 'Name'
    expect(page).to have_css 'div.label-value', text: 'Juan Perez'
  end
end
