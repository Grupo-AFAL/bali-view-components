# frozen_string_literal: true

require "test_helper"

class BaliGoogleMapsTest < ActiveSupport::TestCase
  setup do
    @previous_env = ENV.fetch("GOOGLE_MAPS_KEY", nil)
  end

  teardown do
    Bali.google_maps.api_key = nil
    Bali.google_maps.map_id = nil
    ENV["GOOGLE_MAPS_KEY"] = @previous_env
    ENV.delete("GOOGLE_MAPS_KEY") if @previous_env.nil?
  end

  def test_the_key_is_nil_with_neither_a_setting_nor_an_environment_variable
    ENV.delete("GOOGLE_MAPS_KEY")

    assert_nil Bali.google_maps.api_key
  end

  def test_the_key_falls_back_to_the_environment_variable
    ENV["GOOGLE_MAPS_KEY"] = "from-env"

    assert_equal "from-env", Bali.google_maps.api_key
  end

  def test_an_explicit_key_wins_over_the_environment_variable
    ENV["GOOGLE_MAPS_KEY"] = "from-env"
    Bali.google_maps.api_key = "from-config"

    assert_equal "from-config", Bali.google_maps.api_key
  end

  def test_the_environment_variable_is_read_at_call_time
    ENV.delete("GOOGLE_MAPS_KEY")

    assert_nil Bali.google_maps.api_key

    ENV["GOOGLE_MAPS_KEY"] = "set-later"

    assert_equal "set-later", Bali.google_maps.api_key
  end

  def test_a_blank_environment_variable_is_not_a_key
    ENV["GOOGLE_MAPS_KEY"] = ""

    assert_nil Bali.google_maps.api_key
  end

  def test_a_blank_map_id_is_none
    Bali.google_maps.map_id = ""

    assert_nil Bali.google_maps.map_id
  end

  def test_the_old_reader_warns_and_reads_the_key
    Bali.google_maps.api_key = "map-key"

    key = assert_deprecated(/Bali.google_maps.api_key/, Bali.deprecator) { Bali.google_maps_key }

    assert_equal "map-key", key
  end

  def test_the_old_writer_warns_and_sets_the_key
    assert_deprecated(/Bali.google_maps.api_key=/, Bali.deprecator) { Bali.google_maps_key = "map-key" }

    assert_equal "map-key", Bali.google_maps.api_key
  end

  def test_the_locations_map_component_writes_the_key_without_warning
    Bali.google_maps.api_key = "map-key"

    html = assert_not_deprecated(Bali.deprecator) { render_component(Bali::LocationsMap::Component.new) }

    assert_includes html, 'data-locations-map-api-key-value="map-key"'
  end

  # With no key the component still renders — the map area simply stays blank
  # and the browser console reports the missing key. A `render?` returning false
  # here would make a missing key indistinguishable from a working page in any
  # check that only looks for errors.
  def test_the_locations_map_component_still_renders_without_a_key
    ENV.delete("GOOGLE_MAPS_KEY")

    html = render_component(Bali::LocationsMap::Component.new)

    assert_includes html, 'data-controller="locations-map"'
    assert_includes html, "location-map"
    assert_not_includes html, "locations-map-api-key-value"
  end

  def test_the_coordinates_polygon_field_writes_the_key_without_warning
    Bali.google_maps.api_key = "polygon-key"

    html = assert_not_deprecated(Bali.deprecator) { builder.coordinates_polygon_field(:name).to_s }

    assert_includes html, 'data-drawing-maps-key="polygon-key"'
  end

  private

  def builder
    Bali::FormBuilder.new("movie", Movie.new, vc_test_controller.view_context, {})
  end

  def render_component(component)
    vc_test_controller.view_context.render(component).to_s
  end

  def vc_test_controller
    @vc_test_controller ||= ActionView::TestCase::TestController.new.tap do |controller|
      controller.request = ActionDispatch::TestRequest.create
    end
  end
end
