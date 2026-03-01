# frozen_string_literal: true

require "test_helper"

class BaliLocationsMapComponentTest < ComponentTestCase
  def setup
    @component = Bali::LocationsMap::Component.new
  end

  def test_constants_has_frozen_base_classes
    assert(Bali::LocationsMap::Component::BASE_CLASSES.frozen?)
  end

  def test_constants_has_frozen_map_classes
    assert(Bali::LocationsMap::Component::MAP_CLASSES.frozen?)
  end

  def test_constants_defines_default_center_coordinates
    assert_equal(32.5036383, Bali::LocationsMap::Component::DEFAULT_CENTER_LAT)
    assert_equal(-117.0308968, Bali::LocationsMap::Component::DEFAULT_CENTER_LNG)
  end

  def test_default_rendering_renders_with_base_classes
    render_inline(@component)
    assert_selector("div.locations-map-component")
    assert_selector("div.flex")
  end

  def test_default_rendering_renders_the_map_target_div
    render_inline(@component)
    assert_selector('div.location-map[data-locations-map-target="map"]')
  end

  def test_default_rendering_includes_stimulus_controller_data_attributes
    render_inline(@component)
    assert_selector('[data-controller="locations-map"]')
  end

  def test_default_rendering_passes_default_center_values_to_controller
    render_inline(@component)
    assert_selector("[data-locations-map-center-latitude-value='32.5036383']")
    assert_selector("[data-locations-map-center-longitude-value='-117.0308968']")
  end

  def test_custom_center_coordinates_uses_custom_center_coordinates
    render_inline(Bali::LocationsMap::Component.new(center_latitude: 40.7128, center_longitude: -74.0060))
    assert_selector("[data-locations-map-center-latitude-value='40.7128']")
    assert_selector("[data-locations-map-center-longitude-value='-74.006']")
  end

  def test_zoom_parameter_passes_zoom_value_to_controller
    render_inline(Bali::LocationsMap::Component.new(zoom: 15))
    assert_selector("[data-locations-map-zoom-value='15']")
  end

  def test_clustered_parameter_passes_clustering_value_to_controller
    render_inline(Bali::LocationsMap::Component.new(clustered: true))
    assert_selector('[data-locations-map-enable-clustering-value="true"]')
  end

  def test_with_custom_location_marker_renders_marker_data_attributes
    render_inline(@component) do |c|
      c.with_location(
        latitude: 10, longitude: 10, color: "gray", border_color: "black",
        glyph_color: "black", label: "label"
      )
    end
    assert_selector('span[data-marker-label="label"]')
    assert_selector('span[data-marker-color="gray"]')
    assert_selector('span[data-marker-border-color="black"]')
    assert_selector('span[data-marker-glyph-color="black"]')
  end

  def test_with_custom_location_marker_renders_location_with_icon_url
    render_inline(@component) do |c|
      c.with_location(
        latitude: 10, longitude: 10,
        icon_url: "https://example.com/marker.png"
      )
    end
    assert_selector('span[data-marker-url="https://example.com/marker.png"]')
  end

  def test_with_location_without_info_view_does_not_render_template_element
    render_inline(@component) do |c|
      c.with_location(latitude: 10, longitude: 10)
    end
    assert_selector('span[data-locations-map-target="location"]')
    assert_no_selector("template", visible: false)
  end

  def test_with_location_with_info_view_renders_template_element_with_info_view_content
    render_inline(@component) do |c|
      c.with_location(latitude: 10, longitude: 10) do |location|
        location.with_info_view { "Info content" }
      end
    end
    assert_selector('span[data-locations-map-target="location"]')
    assert_selector("template", visible: false)
  end

  def test_with_cards_renders_cards_and_locations_layout
    render_inline(@component) do |c|
      c.with_card(latitude: 10, longitude: 10) { "Card content" }
      c.with_location(latitude: 10, longitude: 10)
    end
    assert_selector("div.locations-map-component--cards")
    assert_selector("div.locations-map-component--locations")
    assert_selector("div.locations-map-component--card")
  end

  def test_with_cards_renders_card_with_daisyui_classes
    render_inline(@component) do |c|
      c.with_card(latitude: 10, longitude: 10) { "Card" }
      c.with_location(latitude: 10, longitude: 10)
    end
    assert_selector("div.card")
    assert_selector("div.card-border")
    assert_selector("div.bg-base-100")
  end

  def test_with_cards_passes_card_data_attributes_for_map_interaction
    render_inline(@component) do |c|
      c.with_card(latitude: 10.5, longitude: 20.5) { "Card" }
      c.with_location(latitude: 10.5, longitude: 20.5)
    end
    assert_selector('div[data-locations-map-target="card"]')
    assert_selector('div[data-latitude="10.5"]')
    assert_selector('div[data-longitude="20.5"]')
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::LocationsMap::Component.new(class: "custom-class"))
    assert_selector("div.locations-map-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::LocationsMap::Component.new(data: { testid: "map-component" }))
    assert_selector('[data-testid="map-component"]')
  end
end
