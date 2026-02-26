# frozen_string_literal: true

require "test_helper"

class Bali_PropertiesTable_ComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_the_properties_table_component
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Label 1", value: "Value 1")
    end
    assert_selector("table.properties-table-component")
    assert_selector("th.property-label", text: "Label 1")
    assert_selector("td.property-value", text: "Value 1")
  end
  def test_basic_rendering_renders_multiple_properties
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Name", value: "John")
    c.with_property(label: "Email", value: "john@example.com")
    c.with_property(label: "Phone", value: "555-1234")
    end
    assert_selector("tr.properties-table-property-component", count: 3)
    assert_selector("th.property-label", text: "Name")
    assert_selector("td.property-value", text: "john@example.com")
  end
  def test_basic_rendering_renders_tbody_wrapper_for_semantic_html
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector("table > tbody > tr")
  end
  #

  def test_property_content_accepts_content_block_instead_of_value_param
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Status") do
    "Active"
    end
    end
    assert_selector("td.property-value", text: "Active")
  end
  def test_property_content_prefers_value_param_over_content_block
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Status", value: "Preferred") do
    "Ignored"
    end
    end
    assert_selector("td.property-value", text: "Preferred")
    assert_no_text("Ignored")
  end
  #

  def test_css_classes_applies_daisyui_table_classes_with_zebra_striping
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector("table.table")
    assert_selector("table.table-zebra")
    assert_selector("table.properties-table-component")
  end
  def test_css_classes_uses_th_for_label_cells_with_scope_row
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector('th.property-label[scope="row"]')
  end
  def test_css_classes_applies_property_row_classes
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector("tr.properties-table-property-component")
  end
  #

  def test_options_passthrough_passes_custom_options_to_table_element
    render_inline(Bali::PropertiesTable::Component.new(id: "my-table", data: { testid: "props-table" })) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector("table#my-table")
    assert_selector('table[data-testid="props-table"]')
  end
  def test_options_passthrough_merges_custom_classes_with_component_classes
    render_inline(Bali::PropertiesTable::Component.new(class: "custom-table")) do |c|
    c.with_property(label: "Test", value: "Value")
    end
    assert_selector("table.properties-table-component.custom-table")
  end
  def test_options_passthrough_passes_custom_options_to_property_rows
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value", id: "row-1", data: { row: "first" })
    end
    assert_selector("tr#row-1")
    assert_selector('tr[data-row="first"]')
  end
  def test_options_passthrough_merges_custom_classes_with_property_row_classes
    render_inline(Bali::PropertiesTable::Component.new) do |c|
    c.with_property(label: "Test", value: "Value", class: "highlight")
    end
    assert_selector("tr.properties-table-property-component.highlight")
  end
  #

  def test_empty_state_renders_empty_table_when_no_properties_provided
    render_inline(Bali::PropertiesTable::Component.new)
    assert_selector("table.properties-table-component")
    assert_selector("tbody")
    assert_no_selector("tr")
  end
end
