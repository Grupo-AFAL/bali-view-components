# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderCoordinatesPolygonFieldsTest < FormBuilderTestCase
  def setup
    silence_deprecations do
      @coordinates_polygon_group = builder.coordinates_polygon_group(:available_region)
      @coordinates_polygon_field = builder.coordinates_polygon_field(:available_region)
    end
    render_inline(Bali::FieldGroupWrapper::Component.new(builder, :available_region)) { "" }
  end

  # Deprecated in v3 and removed in 4.0. The group renders the field's markup, so it must not
  # warn twice for the one call a host wrote.
  def test_each_helper_warns_once_through_the_bali_deprecator
    %i[coordinates_polygon_group coordinates_polygon_field].each do |name|
      warnings = []
      with_deprecator_behavior(->(message, *) { warnings << message }) do
        builder.public_send(name, :available_region)
      end

      assert_equal 1, warnings.size, "#{name} warned #{warnings.size} times"
      assert_match(/Bali::FormBuilder##{name} is deprecated/, warnings.first)
      assert_match(/DrawingManager/, warnings.first)
    end
  end

  def test_coordinates_polygon_group_renders_a_label_and_input_within_a_field_wrapper
    assert_html(@coordinates_polygon_group, "fieldset.fieldset")
  end

  def test_coordinates_polygon_group_renders_a_label
    assert_html(@coordinates_polygon_group, "legend.fieldset-legend", text: "Available region")
  end

  def test_coordinates_polygon_group_renders_a_hidden_input_and_a_map
    assert_html(@coordinates_polygon_group, 'div[data-controller="drawing-maps"]')
    assert_html(@coordinates_polygon_group, "div.map")
    assert_html(@coordinates_polygon_group, 'input#movie_available_region[value="[]"]', visible: false)
  end

  def test_coordinates_polygon_group_renders_clear_buttons_with_correct_text
    node = Capybara.string(@coordinates_polygon_group)
    # Literal text on purpose: comparing the rendered button against the same
    # I18n.t call passed even when the key did not exist, because both sides
    # returned the identical "Translation missing:" string.
    assert node.has_button?("Clear holes"), "Expected to find button 'Clear holes'"
    assert node.has_button?("Clear"), "Expected to find button 'Clear'"
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
    field = silence_deprecations do
      builder.coordinates_polygon_field(:available_region, value: [ [ 1, 2 ], [ 3, 4 ] ])
    end
    assert_html(field, 'input#movie_available_region[value="[[1,2],[3,4]]"]', visible: false)
  end
end
