# frozen_string_literal: true

require "test_helper"

class ThemeHelperTest < ActionView::TestCase
  include Bali::ThemeHelper

  def setup
    super
    @themes = Bali.themes
    Bali.themes = { light: "afal", dark: "afal-dark" }
  end

  def teardown
    Bali.themes = @themes
    super
  end

  def test_without_a_choice_the_page_is_light
    assert_equal "afal", bali_theme
  end

  def test_the_dark_choice_paints_the_dark_theme
    request.cookies["bali_theme"] = "dark"

    assert_equal "afal-dark", bali_theme
  end

  def test_the_light_choice_paints_the_light_theme
    request.cookies["bali_theme"] = "light"

    assert_equal "afal", bali_theme
  end

  def test_an_unknown_value_reads_as_light
    request.cookies["bali_theme"] = "midnight"

    assert_equal "afal", bali_theme
  end

  def test_a_dark_choice_is_ignored_where_no_dark_theme_is_configured
    Bali.themes = { light: "costa-norte" }
    request.cookies["bali_theme"] = "dark"

    assert_equal "costa-norte", bali_theme
  end

  def test_an_unconfigured_host_is_told_what_to_set
    Bali.themes = nil

    error = assert_raises(ArgumentError) { bali_theme }
    assert_match(/Bali\.themes = \{ light:/, error.message)
  end

  def test_string_keys_are_read_as_symbols
    Bali.themes = { "light" => "afal", "dark" => "afal-dark" }

    assert_equal({ light: "afal", dark: "afal-dark" }, Bali.themes)
  end

  def test_a_misspelt_key_fails_on_assignment
    error = assert_raises(ArgumentError) { Bali.themes = { light: "afal", drak: "afal-dark" } }
    assert_match(/drak/, error.message)
  end

  def test_a_pair_without_light_fails_on_assignment
    error = assert_raises(ArgumentError) { Bali.themes = { dark: "afal-dark" } }
    assert_match(/light:/, error.message)
  end

  def test_the_cookie_name_is_the_one_the_toggle_writes
    assert_equal "bali_theme", Bali::ThemeHelper::COOKIE
    assert_equal "dark", Bali::ThemeHelper::DARK
  end

  def test_helper_is_exposed_to_host_app_views
    assert ApplicationController.helpers.respond_to?(:bali_theme),
           "Expected the engine to expose bali_theme to host controllers"
  end
end
