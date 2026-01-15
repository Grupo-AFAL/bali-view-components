# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Filters::Component, type: :component do
  let(:form) { Bali::Utils::DummyFilterForm.new }
  let(:component) do
    Bali::Filters::Component.new(form: form, url: '#', text_field: :name)
  end

  it 'renders' do
    render_inline(component)

    expect(page).to have_css 'div.search-input-component'
    expect(page).not_to have_css 'a.filters-button'
  end

  it 'renders with filters' do
    render_inline(component) do |c|
      c.with_attribute(
        title: 'Active',
        attribute: :status_in,
        collection_options: [['active', true], ['inactive', false]]
      )
    end

    expect(page).to have_css 'div.search-input-component'
    expect(page).to have_css 'button[id="filters-button"]'
  end
end
