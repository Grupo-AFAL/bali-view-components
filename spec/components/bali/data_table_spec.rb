# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bali::DataTable::Component, type: :component do
  let(:component) { Bali::DataTable::Component.new(filter_form: DummyFilterForm.new, url: '#') }

  subject { rendered_component }

  it "renders without summary" do
    render_inline(component) do |c|
      c.filters_panel(text_field: :name, opened: false)

      c.table { '<div class="table-component"></div>'.html_safe }
    end

    is_expected.to have_css "div.data-table-component"
    is_expected.to have_css "div.filters-component"
    is_expected.to have_css "div.table-component"
  end

  it "renders with summary" do
    render_inline(component) do |c|
      c.filters_panel(text_field: :name, opened: false)

      c.summary { '<p>Summary</p>'.html_safe }

      c.table { '<div class="table-component"></div>'.html_safe }
    end

    is_expected.to have_css "div.data-table-component"
    is_expected.to have_css "div.filters-component"
    is_expected.to have_css "div.table-component"
    is_expected.to have_css "p", text: 'Summary'
  end
end
