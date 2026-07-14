# frozen_string_literal: true

require "test_helper"

class TestPathHelperComponent
  include Bali::PathHelper
end

class BaliPathHelperTest < ActiveSupport::TestCase
  def setup
    @helper = TestPathHelperComponent.new
  end

  # active_extra_path? — String prefix

  def test_active_extra_path_matches_a_string_prefix_on_a_nested_route
    assert @helper.active_extra_path?("/departments/1/merges", "/departments/1/merges/new")
  end

  def test_active_extra_path_does_not_match_an_unrelated_sibling_sub_resource
    refute @helper.active_extra_path?("/departments/1/merges", "/departments/1/source_links/new")
  end

  # active_extra_path? — avoids :starts_with over-matching

  def test_active_extra_path_avoids_starts_with_over_matching
    matcher = %r{\A/departments/\d+/(merges|source_links)}
    # A precise matcher keeps the item active on its own sub-resources...
    assert @helper.active_extra_path?(matcher, "/departments/1/merges/new")
    # ...but does NOT light up on a sibling sub-resource that a plain
    # `:starts_with "/departments"` would wrongly catch.
    refute @helper.active_extra_path?(matcher, "/departments/1/reports")
  end

  # active_extra_path? — Regexp

  def test_active_extra_path_matches_a_regexp
    assert @helper.active_extra_path?(%r{\A/departments/\d+/merges}, "/departments/42/merges/new")
  end

  def test_active_extra_path_returns_false_when_regexp_does_not_match
    refute @helper.active_extra_path?(%r{\A/departments/\d+/merges}, "/dashboard")
  end

  # active_extra_path? — Array of mixed matchers

  def test_active_extra_path_matches_any_matcher_in_an_array
    matchers = [ "/departments/1/merges", %r{/source_links} ]
    assert @helper.active_extra_path?(matchers, "/departments/1/merges/new")
    assert @helper.active_extra_path?(matchers, "/departments/1/source_links/new")
  end

  def test_active_extra_path_returns_false_when_no_array_matcher_matches
    matchers = [ "/departments/1/merges", %r{/source_links} ]
    refute @helper.active_extra_path?(matchers, "/dashboard")
  end

  # active_extra_path? — Proc / lambda

  def test_active_extra_path_calls_a_proc_with_the_current_path
    matcher = ->(current_path) { current_path.start_with?("/departments/") && current_path.include?("/merges") }
    assert @helper.active_extra_path?(matcher, "/departments/1/merges/new")
    refute @helper.active_extra_path?(matcher, "/departments/1/edit")
  end

  # active_extra_path? — normalization matches active_path? (strip query and .html)

  def test_active_extra_path_strips_query_string_before_matching
    assert @helper.active_extra_path?("/departments/1/merges", "/departments/1/merges/new?tab=details")
  end

  def test_active_extra_path_strips_trailing_html_before_matching
    assert @helper.active_extra_path?("/departments/1/merges/new", "/departments/1/merges/new.html")
  end

  # active_extra_path? — blank / nil handling

  def test_active_extra_path_returns_false_when_active_when_is_nil
    refute @helper.active_extra_path?(nil, "/departments/1/merges/new")
  end

  def test_active_extra_path_returns_false_when_active_when_is_a_blank_string
    refute @helper.active_extra_path?("", "/departments/1/merges/new")
  end

  def test_active_extra_path_returns_false_when_active_when_is_an_empty_array
    refute @helper.active_extra_path?([], "/departments/1/merges/new")
  end

  def test_active_extra_path_returns_false_when_current_path_is_nil
    refute @helper.active_extra_path?("/departments", nil)
  end
end
