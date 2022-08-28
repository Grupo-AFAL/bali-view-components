# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PropertiesTable::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::PropertiesTable::Component.new(**options) }

  it 'renders the properties table component' do
    render_inline(component) do |c|
      c.property(label: 'Label 1', value: 'Value 1')
    end

    expect(page).to have_css 'table.properties-table-component'
    expect(page).to have_css 'td.property-label', text: 'Label 1'
    expect(page).to have_css 'td.property-value', text: 'Value 1'
  end
end
