# frozen_string_literal: true

require "test_helper"

class UtilsHelperContext < ActionView::Base
  include Bali::Utils
end

class UrlHelperContext
  include Bali::Utils::Url
end

class BaliUtilsUrlTest < ActiveSupport::TestCase
  def setup
    @helper = UrlHelperContext.new
  end

  def test_add_query_param_appends_to_a_url_without_a_query_string
    assert_equal("/movies?view=grid", @helper.add_query_param("/movies", :view, :grid))
  end

  def test_add_query_param_keeps_the_other_params
    assert_equal(
      "/movies?page=2&view=grid",
      @helper.add_query_param("/movies?page=2", :view, :grid)
    )
  end

  # #653: parse_query returns String keys, so merging the Symbol :view left both
  # entries and the param was emitted twice — Rack's last-wins then handed the
  # value back to whatever was already in the URL, freezing the toggle.
  def test_add_query_param_replaces_a_param_already_in_the_url
    assert_equal("/movies?view=grid", @helper.add_query_param("/movies?view=table", :view, :grid))
  end

  def test_add_query_param_replaces_a_param_already_in_the_url_given_a_string_name
    assert_equal("/movies?view=grid", @helper.add_query_param("/movies?view=table", "view", :grid))
  end

  def test_add_query_param_collapses_repeated_scalar_params
    assert_equal(
      "/movies?sort=name&view=grid",
      @helper.add_query_param("/movies?sort=name&sort=year", :view, :grid)
    )
  end

  # The `_in` / `_not_in` / `[]` names are the multi-value ones, so they keep
  # every value instead of collapsing to the first — re-encoded as `name[]`,
  # which is what Rails' own params parser reads back as an Array.
  def test_add_query_param_keeps_multi_value_params_whole
    assert_equal(
      "/movies?genre_in%5B%5D=action&genre_in%5B%5D=drama&view=grid",
      @helper.add_query_param("/movies?genre_in=action&genre_in=drama", :view, :grid)
    )
  end
end

class BaliUtilsTest < ActiveSupport::TestCase
  def setup
    @helper = UtilsHelperContext.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  def test_class_names_when_names_are_given_as_string_conditional_names_are_given_returns_a_string_with_the_class_names
    conditional_names = { "is-centered" => false, "is-primary" => true }
    assert_equal("is-active is-primary", @helper.class_names("is-active", conditional_names))
  end

  def test_class_names_when_names_are_given_as_a_hash_returns_a_string_with_the_class_names
    names = { "is-active" => true, "is-centered" => false, "is-primary" => true }
    assert_equal("is-active is-primary", @helper.class_names(names))
  end

  def test_custom_dom_id_returns_a_string_with_the_dom_id
    assert_equal("movie_", @helper.custom_dom_id(Movie.new))
  end

  def test_test_id_attr_when_params_are_given_as_string_returns_a_string_with_the_test_id
    assert_equal('test-id="movie_1"', @helper.test_id_attr("movie_1"))
  end

  def test_test_id_attr_when_params_are_given_as_activerecord_returns_a_string_with_the_test_id
    assert_equal('test-id="movie_"', @helper.test_id_attr(Movie.new))
  end

  def test_test_id_attr_when_no_params_are_given_returns_nil
    assert_nil(@helper.test_id_attr(nil))
  end
end

class ColorCalculatorContext
  include Bali::Utils::ColorCalculator
end

class BaliUtilsColorCalculatorTest < ActiveSupport::TestCase
  def setup
    @helper = ColorCalculatorContext.new
  end

  def test_deterministic_color_returns_a_bg_fg_pair_from_the_status_palette
    pair = @helper.deterministic_color("Ana García")

    assert_includes(Bali::Status::Component::PALETTE.values, pair)
    assert(pair.key?(:bg))
    assert(pair.key?(:fg))
  end

  def test_deterministic_color_is_stable_for_the_same_seed
    assert_equal(@helper.deterministic_color("Ana García"),
                 @helper.deterministic_color("Ana García"))
  end

  # String#hash is randomized per process; the mapping must survive restarts,
  # so it is pinned to Zlib.crc32 and these seeds assert the exact colour.
  def test_deterministic_color_mapping_is_stable_across_processes
    palette = Bali::Status::Component::PALETTE

    assert_equal(palette[:red], @helper.deterministic_color("Ana García"))
    assert_equal(palette[:green], @helper.deterministic_color("Juan Pérez"))
  end

  def test_deterministic_color_never_picks_slate_or_gray
    excluded = Bali::Status::Component::PALETTE.values_at(:slate, :gray)

    1_000.times do |i|
      refute_includes(excluded, @helper.deterministic_color("seed-#{i}"))
    end
  end

  def test_deterministic_color_accepts_a_nil_seed
    assert_includes(Bali::Status::Component::PALETTE.values, @helper.deterministic_color(nil))
  end
end
