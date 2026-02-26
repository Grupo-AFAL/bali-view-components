# frozen_string_literal: true

require "test_helper"

class UtilsHelperContext < ActionView::Base
  include Bali::Utils
end

class Bali_UtilsTest < ActiveSupport::TestCase
  def setup
    @helper = UtilsHelperContext.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  #

  #

  #

  def test_class_names_when_names_are_given_as_string_conditional_names_are_given_returns_a_string_with_the_class_names
    conditional_names = { "is-centered" => false, "is-primary" => true }
    assert_equal("is-active is-primary", @helper.class_names("is-active", conditional_names))
  end
  #

  def test_class_names_when_names_are_given_as_a_hash_returns_a_string_with_the_class_names
    names = { "is-active" => true, "is-centered" => false, "is-primary" => true }
    assert_equal("is-active is-primary", @helper.class_names(names))
  end
  #

  def test_custom_dom_id_returns_a_string_with_the_dom_id
    assert_equal("movie_", @helper.custom_dom_id(Movie.new))
  end
  #

  #

  def test_test_id_attr_when_params_are_given_as_string_returns_a_string_with_the_test_id
    assert_equal('test-id="movie_1"', @helper.test_id_attr("movie_1"))
  end
  #

  def test_test_id_attr_when_params_are_given_as_activerecord_returns_a_string_with_the_test_id
    assert_equal('test-id="movie_"', @helper.test_id_attr(Movie.new))
  end
  #

  def test_test_id_attr_when_no_params_are_given_returns_nil
    assert_nil(@helper.test_id_attr(nil))
  end
end
