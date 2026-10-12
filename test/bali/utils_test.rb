# frozen_string_literal: true

require "test_helper"

class UtilsHelperContext < ActionView::Base
  include Bali::Utils
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

  # #1373: summing R+G+B put black on this blue, 4.06:1 where white gives 5.17.
  def test_contrasting_text_color_picks_the_higher_contrast_ratio
    assert_equal("#fff", @helper.contrasting_text_color("#535BEB"))
  end

  # Black and white tie at a relative luminance of 0.179. These two greys straddle it:
  # #757575 gives white 4.61 and black 4.56, #767676 white 4.54 and black 4.62.
  def test_contrasting_text_color_flips_where_the_two_ratios_cross
    assert_equal("#fff", @helper.contrasting_text_color("#757575"))
    assert_equal("#000", @helper.contrasting_text_color("#767676"))
  end

  def test_contrasting_text_color_reads_the_short_and_the_alpha_hex_forms
    assert_equal("#000", @helper.contrasting_text_color("#fff"))
    assert_equal("#000", @helper.contrasting_text_color("#ff08"))
    assert_equal("#fff", @helper.contrasting_text_color("#535BEBcc"))
  end
end
