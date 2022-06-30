# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Filters::Component, type: :component do
  let(:form) { DummyFilterForm.new }
  let(:component) do
    Bali::Filters::Component.new(form: form, url: '#', text_field: :name)
  end

  subject { rendered_component }

  it 'renders' do
    render_inline(component)

    is_expected.to have_css 'div.search-input-component'
    is_expected.not_to have_css 'a.filters-button'
  end

  it 'renders with filters' do
    render_inline(component) do |c|
      c.attribute(
        title: 'Active',
        attribute: :status_in,
        collection_options: [['active', true], ['inactive', false]]
      )
    end

    is_expected.to have_css 'div.search-input-component'
    is_expected.to have_css 'a[id="filters-button"]'
  end
end
