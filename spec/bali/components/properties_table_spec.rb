# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PropertiesTable::Component, type: :component do
  let(:options) { {  } }
  let(:component) { Bali::PropertiesTable::Component.new(**options) }

  it 'renders propertiestable component' do
    render_inline(component)

    expect(page).to have_css 'div.properties-table-component'
  end
end
