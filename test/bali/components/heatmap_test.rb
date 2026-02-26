# frozen_string_literal: true

require "test_helper"

class Bali_Heatmap_ComponentTest < ComponentTestCase
  private

  def data
    {
      Mon: { 0 => 3, 1 => 10, 2 => 0 },
      Tue: { 0 => 1, 1 => 4,  2 => 6 },
      Wed: { 0 => 7, 1 => 2,  2 => 5 }
    }
  end

  public

  #

  def test_rendering_renders_the_heatmap_structure
    render_inline(Bali::Heatmap::Component.new(data: data))
    assert_selector("div.heatmap-component")
    assert_selector("table")
  end
  def test_rendering_renders_all_x_axis_labels_in_footer
    render_inline(Bali::Heatmap::Component.new(data: data))
    %w[Mon Tue Wed].each do |day|
    assert_selector("tfoot td", text: day)
  end
  end


  def test_rendering_renders_all_y_axis_labels
    render_inline(Bali::Heatmap::Component.new(data: data))
    (0..2).each do |hour|
    assert_selector("td", text: hour.to_s)
  end
  end


  def test_rendering_renders_the_legend_with_min_and_max_values
    render_inline(Bali::Heatmap::Component.new(data: data))
    assert_selector("span", text: "0")
    assert_selector("span", text: "10") # max value in data
  end


  def test_rendering_renders_heatmap_cells_with_background_colors
    render_inline(Bali::Heatmap::Component.new(data: data))
    assert_selector('.heatmap-cell[style*="background"]')
  end
  def test_rendering_renders_responsive_table_by_default
    render_inline(Bali::Heatmap::Component.new(data: data))
    assert_selector("table.w-full")
  end
  #

  def test_slots_renders_x_axis_title_when_provided
    render_inline(Bali::Heatmap::Component.new(data: data)) do |c|
    c.with_x_axis_title("Days")
    end
    assert_selector("tfoot td", text: "Days")
  end
  def test_slots_renders_y_axis_title_when_provided
    render_inline(Bali::Heatmap::Component.new(data: data)) do |c|
    c.with_y_axis_title("Hours")
    end
    assert_selector("th", text: "Hours")
  end
  def test_slots_renders_legend_title_when_provided
    render_inline(Bali::Heatmap::Component.new(data: data)) do |c|
    c.with_legend_title("Activity")
    end
    assert_text("Activity")
  end
  def test_slots_renders_hovercard_title_when_provided
    result = render_inline(Bali::Heatmap::Component.new(data: data)) do |c|
    c.with_hovercard_title("Details")
    end
    # HoverCard content is inside a <template> tag, so we check the raw HTML
    assert_includes(result.to_html, "Details")
  end
  def test_slots_does_not_render_x_axis_title_row_when_not_provided
    render_inline(Bali::Heatmap::Component.new(data: data))
    assert_no_selector("tfoot tr td[colspan]")
  end
  #

  def test_color_customization_accepts_hex_color_string
    render_inline(Bali::Heatmap::Component.new(data: data, color: "#FF0000"))
    assert_selector('.heatmap-cell[style*="background"]')
  end
  def test_color_customization_accepts_daisyui_color_preset_symbols
    Bali::Heatmap::Component::COLOR_PRESETS.each_key do |preset|
    component = Bali::Heatmap::Component.new(data: data, color: preset)
    assert_kind_of(Array, component.gradient_colors)
  end
  end


  def test_color_customization_uses_primary_as_default_color
    component = Bali::Heatmap::Component.new(data: data)
    refute_empty(component.gradient_colors)
  end
  #

  def test_responsive_mode_is_responsive_by_default
    component = Bali::Heatmap::Component.new(data: data)
    assert(component.responsive?)
  end
  def test_responsive_mode_can_be_disabled
    component = Bali::Heatmap::Component.new(data: data, responsive: false)
    refute(component.responsive?)
  end
  def test_responsive_mode_includes_cell_size_in_style
    component = Bali::Heatmap::Component.new(data: data, cell_size: 40)
    style = component.cell_style(5)
    assert_includes(style, "height: 40px")
    assert_includes(style, "background:")
  end
  def test_responsive_mode_uses_default_cell_size_when_not_specified
    component = Bali::Heatmap::Component.new(data: data)
    style = component.cell_style(5)
    assert_includes(style, "height: 28px")
  end
  #

  def test_edge_cases_handles_empty_data_gracefully
    render_inline(Bali::Heatmap::Component.new(data: {}))
    assert_selector("div.heatmap-component")
    assert_selector("table")
  end
  def test_edge_cases_handles_data_with_all_zero_values
    zero_data = { A: { 0 => 0, 1 => 0 }, B: { 0 => 0, 1 => 0 } }
    render_inline(Bali::Heatmap::Component.new(data: zero_data))
    assert_selector("div.heatmap-component")
    assert_selector("span", text: "0")
  end
  def test_edge_cases_handles_missing_values_in_nested_data
    sparse_data = { A: { 0 => 5 }, B: { 1 => 10 } }
    component = Bali::Heatmap::Component.new(data: sparse_data)
    # Should return 0 for missing values
    assert_equal(0, component.value_at(:A, 1))
    assert_equal(0, component.value_at(:B, 0))
  end
  #

  def test_public_api_exposes_x_labels
    component = Bali::Heatmap::Component.new(data: data)
    assert_equal(%i[Mon Tue Wed], component.x_labels)
  end
  def test_public_api_exposes_y_labels_as_a_range
    component = Bali::Heatmap::Component.new(data: data)
    assert_equal(0..2, component.y_labels)
  end
  def test_public_api_exposes_max_value
    component = Bali::Heatmap::Component.new(data: data)
    assert_equal(10, component.max_value)
  end
  def test_public_api_exposes_gradient_colors
    component = Bali::Heatmap::Component.new(data: data)
    assert_kind_of(Array, component.gradient_colors)
    refute_empty(component.gradient_colors)
  end
  def test_public_api_provides_value_at_helper
    component = Bali::Heatmap::Component.new(data: data)
    assert_equal(10, component.value_at(:Mon, 1))
    assert_equal(6, component.value_at(:Tue, 2))
  end
  def test_public_api_provides_cell_style_helper
    component = Bali::Heatmap::Component.new(data: data)
    style = component.cell_style(5)
    assert_includes(style, "background:")
  end
  #

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Heatmap::Component.new(data: data, class: "custom-class"))
    assert_selector("div.heatmap-component.custom-class")
  end
  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::Heatmap::Component.new(data: data, id: "my-heatmap"))
    assert_selector("#my-heatmap")
  end
end
