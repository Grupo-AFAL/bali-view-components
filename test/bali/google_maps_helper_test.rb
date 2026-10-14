# frozen_string_literal: true

require "test_helper"

class GoogleMapsHelperTest < ActionView::TestCase
  include Bali::GoogleMapsHelper

  def setup
    super
    @previous_env = ENV.fetch("GOOGLE_MAPS_KEY", nil)
    ENV.delete("GOOGLE_MAPS_KEY")
  end

  def teardown
    Bali.google_maps.api_key = nil
    Bali.google_maps.map_id = nil
    ENV["GOOGLE_MAPS_KEY"] = @previous_env
    ENV.delete("GOOGLE_MAPS_KEY") if @previous_env.nil?
    super
  end

  def test_writes_the_key_and_the_map_id
    Bali.google_maps.api_key = "map-key"
    Bali.google_maps.map_id = "map-id"

    html = google_maps_meta_tags

    assert_html html, 'meta[name="bali-google-maps-key"][content="map-key"]'
    assert_html html, 'meta[name="bali-google-maps-map-id"][content="map-id"]'
  end

  def test_writes_the_key_from_the_environment_variable
    ENV["GOOGLE_MAPS_KEY"] = "from-env"

    assert_html google_maps_meta_tags, 'meta[name="bali-google-maps-key"][content="from-env"]'
  end

  def test_writes_no_tag_for_what_is_not_set
    assert_equal "", google_maps_meta_tags

    Bali.google_maps.api_key = "map-key"

    assert_no_match(/map-id/, google_maps_meta_tags)
  end

  # The other half of the contract: googleMapsConfig() looks the tags up by these names.
  def test_the_names_are_the_ones_google_maps_config_reads
    source = Bali::Engine.root.join("app/assets/javascripts/bali/utils/google-maps-loader.js").read

    [ Bali::GoogleMapsHelper::KEY_META, Bali::GoogleMapsHelper::MAP_ID_META ].each do |name|
      assert source.include?(%(meta[name="#{name}"])), "googleMapsConfig() does not read meta[name=\"#{name}\"]"
    end
  end

  def test_helper_is_exposed_to_host_app_views
    assert ApplicationController.helpers.respond_to?(:google_maps_meta_tags),
           "Expected the engine to expose google_maps_meta_tags to host controllers"
  end

  private

  def assert_html(html, selector)
    assert Capybara.string(html).has_css?(selector, visible: false), "Expected '#{selector}' in:\n#{html}"
  end
end
