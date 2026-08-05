# frozen_string_literal: true

require "test_helper"

# `LocationsMap` and the form builder's coordinates polygon field each read
# `ENV.fetch("GOOGLE_MAPS_KEY")` on their own until v3, which made the
# environment the only place the key could come from. The setting is what lets
# an application keep it wherever it keeps the rest of its credentials; the
# environment variable stays as the fallback, so nothing an app already does
# stops working.
class BaliGoogleMapsKeyTest < ActiveSupport::TestCase
  setup do
    @previous_setting = Bali.google_maps_key
    @previous_env = ENV.fetch("GOOGLE_MAPS_KEY", nil)
  end

  teardown do
    Bali.google_maps_key = @previous_setting
    ENV["GOOGLE_MAPS_KEY"] = @previous_env
    ENV.delete("GOOGLE_MAPS_KEY") if @previous_env.nil?
  end

  def test_it_is_nil_with_neither_a_setting_nor_an_environment_variable
    Bali.google_maps_key = nil
    ENV.delete("GOOGLE_MAPS_KEY")

    assert_nil Bali.google_maps_key
  end

  def test_it_falls_back_to_the_environment_variable
    Bali.google_maps_key = nil
    ENV["GOOGLE_MAPS_KEY"] = "from-env"

    assert_equal "from-env", Bali.google_maps_key
  end

  def test_an_explicit_setting_wins_over_the_environment_variable
    ENV["GOOGLE_MAPS_KEY"] = "from-env"
    Bali.google_maps_key = "from-config"

    assert_equal "from-config", Bali.google_maps_key
  end

  # Why the reader resolves per call instead of memoising: an initializer runs
  # before an application's own credential loading in more setups than not, and
  # a value frozen at boot would be the empty string forever in every one.
  def test_the_environment_variable_is_read_at_call_time
    Bali.google_maps_key = nil
    ENV.delete("GOOGLE_MAPS_KEY")

    assert_nil Bali.google_maps_key

    ENV["GOOGLE_MAPS_KEY"] = "set-later"

    assert_equal "set-later", Bali.google_maps_key
  end

  def test_a_blank_environment_variable_is_not_a_key
    Bali.google_maps_key = nil
    ENV["GOOGLE_MAPS_KEY"] = ""

    assert_nil Bali.google_maps_key
  end

  def test_the_locations_map_component_reads_the_setting
    Bali.google_maps_key = "map-key"

    html = render_component(Bali::LocationsMap::Component.new)

    assert_includes html, 'data-locations-map-api-key-value="map-key"'
  end

  # With no key the component still renders — the map area simply stays blank
  # and the browser console reports the missing key. A `render?` returning false
  # here would make a missing key indistinguishable from a working page in any
  # check that only looks for errors.
  def test_the_locations_map_component_still_renders_without_a_key
    Bali.google_maps_key = nil
    ENV.delete("GOOGLE_MAPS_KEY")

    html = render_component(Bali::LocationsMap::Component.new)

    assert_includes html, 'data-controller="locations-map"'
    assert_includes html, "location-map"
    assert_not_includes html, "locations-map-api-key-value"
  end

  def test_the_coordinates_polygon_field_reads_the_setting
    Bali.google_maps_key = "polygon-key"

    html = builder.coordinates_polygon_field(:name).to_s

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
