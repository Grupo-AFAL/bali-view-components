# frozen_string_literal: true

require "test_helper"

class BaliDataTableComponentTest < ComponentTestCase
  def setup
    @options = {}
  end


  def component
    Bali::DataTable::Component.new(url: "/", **@options)
  end


  def filter_attributes
    [ { key: :name, type: :text, label: "Name" } ]
  end


  def test_renders_without_summary
    render_inline(component) do |c|
    c.with_filters_panel(available_attributes: filter_attributes)
    c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_with_summary
    render_inline(component) do |c|
    c.with_filters_panel(available_attributes: filter_attributes)
    c.with_summary { "<p>Summary</p>".html_safe }
    c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
    assert_selector("p", text: "Summary")
  end

  def test_renders_without_filters_panel
    render_inline(component) do |c|
    c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_no_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_toolbar_buttons
    render_inline(component) do |c|
    c.with_toolbar_button { '<button class="btn">Export</button>'.html_safe }
    c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("button.btn", text: "Export")
  end
end
