# frozen_string_literal: true

require "test_helper"

class TestHelperComponent
  include Bali::HtmlElementHelper
end

class BaliHtmlElementHelperTest < ActiveSupport::TestCase
  def setup
    @helper = TestHelperComponent.new
  end

  def test_prepend_action_adds_a_stimulus_controller_action
    options = @helper.prepend_action({}, "modal#open")
    assert_equal("modal#open", options[:data][:action])
  end

  def test_prepend_controller_adds_a_stimulus_controller
    options = @helper.prepend_controller({}, "modal")
    assert_equal("modal", options[:data][:controller])
  end

  def test_prepend_values_adds_values_for_a_stimulus_controller
    options = @helper.prepend_values({}, "list", { param_name: "position" })
    assert_equal("position", options[:data]["list-param-name-value"])
  end

  def test_prepend_values_does_not_override_other_values_in_data
    options = { data: { controller: "list" } }
    options = @helper.prepend_values(options, "list", { param_name: "position" })
    assert_equal("list", options[:data][:controller])
    assert_equal("position", options[:data]["list-param-name-value"])
  end

  def test_prepend_values_when_value_is_a_hash_adds_values_for_a_stimulus_controller
    options = @helper.prepend_values({}, "list", { params: { name: "position" } })
    assert_equal('{"name":"position"}', options[:data]["list-params-value"])
  end

  def test_prepend_class_name_adds_a_class_to_options_hash
    options = @helper.prepend_class_name({}, "is-active")
    assert_equal("is-active", options[:class])
  end

  def test_prepend_class_name_prepends_the_class_name_to_the_existing_class
    options = @helper.prepend_class_name({ class: "list" }, "is-active")
    assert_equal("is-active list", options[:class])
  end
end
