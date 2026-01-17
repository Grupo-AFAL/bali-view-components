# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::DataTable::Component, type: :component do
  let(:form) { Bali::Utils::DummyFilterForm.new }
  let(:component) { Bali::DataTable::Component.new(filter_form: form, url: '#') }

  let(:filter_attributes) do
    [
      { key: :name, label: 'Name', type: :text },
      { key: :status, label: 'Status', type: :select, options: [%w[Active active]] }
    ]
  end

  it 'renders without summary' do
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)

      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    expect(page).to have_css 'div.data-table-component'
    expect(page).to have_css 'div.advanced-filters'
    expect(page).to have_css 'div.table-component'
  end

  it 'renders with summary' do
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)

      c.with_summary { '<p>Summary</p>'.html_safe }

      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    expect(page).to have_css 'div.data-table-component'
    expect(page).to have_css 'div.advanced-filters'
    expect(page).to have_css 'div.table-component'
    expect(page).to have_css 'p', text: 'Summary'
  end

  it 'renders without filters panel' do
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    expect(page).to have_css 'div.data-table-component'
    expect(page).not_to have_css 'div.advanced-filters'
    expect(page).to have_css 'div.table-component'
  end

  it 'renders toolbar buttons' do
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">Export</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    expect(page).to have_css 'div.data-table-component'
    expect(page).to have_css 'button.btn', text: 'Export'
  end
end
