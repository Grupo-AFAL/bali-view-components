# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderCoordinatesPolygonFieldsTest < FormBuilderTestCase
  def setup
    @coordinates_polygon_field_group = builder.coordinates_polygon_field_group(:available_region)
    @coordinates_polygon_field = builder.coordinates_polygon_field(:available_region)
    render_inline(Bali::FieldGroupWrapper::Component.new(builder, :available_region)) { "" }
  end

  def test_coordinates_polygon_field_group_renders_a_label_and_input_within_a_field_wrapper
    assert_html(@coordinates_polygon_field_group, "fieldset.fieldset")
  end

  def test_coordinates_polygon_field_group_renders_a_label
    assert_html(@coordinates_polygon_field_group, "legend.fieldset-legend", text: "Available region")
  end

  def test_coordinates_polygon_field_group_renders_a_hidden_input_and_a_map
    assert_html(@coordinates_polygon_field_group, 'div[data-controller="drawing-maps"]')
    assert_html(@coordinates_polygon_field_group, "div.map")
    assert_html(@coordinates_polygon_field_group, 'input#movie_available_region[value="[]"]', visible: false)
  end

  def test_coordinates_polygon_field_group_renders_clear_buttons_with_correct_text
    node = Capybara.string(@coordinates_polygon_field_group)
    assert node.has_button?(I18n.t("helpers.clear_holes.text")),
      "Expected to find button '#{I18n.t("helpers.clear_holes.text")}'"
    assert node.has_button?(I18n.t("helpers.clear.text")),
      "Expected to find button '#{I18n.t("helpers.clear.text")}'"
  end

  def test_coordinates_polygon_field_renders_a_hidden_input_and_a_map
    assert_html(@coordinates_polygon_field, 'div[data-controller="drawing-maps"]')
    assert_html(@coordinates_polygon_field, "div.map")
    assert_html(@coordinates_polygon_field, 'input#movie_available_region[value="[]"]', visible: false)
  end

  def test_coordinates_polygon_field_applies_map_height_class
    assert_html(@coordinates_polygon_field, 'div.map.h-\[400px\]')
  end

  def test_coordinates_polygon_field_accepts_custom_value_option
    field = builder.coordinates_polygon_field(:available_region, value: [ [ 1, 2 ], [ 3, 4 ] ])
    assert_html(field, 'input#movie_available_region[value="[[1,2],[3,4]]"]', visible: false)
  end
end
