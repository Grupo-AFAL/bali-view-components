# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::LocationsMap::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::LocationsMap::Component.new(**options) }

  it 'renders locationsmap component' do
    render_inline(component)

    expect(page).to have_css 'div.locations-map-component'
  end
end
