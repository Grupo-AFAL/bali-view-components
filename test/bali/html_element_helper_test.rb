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

  # Classes are separated by a space; DECLARATIONS are separated by a `;`. This
  # used to interpolate the two sides with a space, which fuses them into one
  # unparseable declaration and loses BOTH — the component's style and the
  # host's. Measured in the browser through its only caller, StatCard's
  # `emphasis:` tint (#1146): `border-color: color-mix(…) opacity:.5` left the
  # border at `border-base-300` and the opacity at 1.
  def test_prepend_style_separates_the_declarations_with_a_semicolon
    options = @helper.prepend_style({ style: "opacity:.5" }, "border-color: red")

    assert_equal("border-color: red; opacity:.5", options[:style])
  end

  def test_prepend_style_does_not_double_a_semicolon_the_caller_already_wrote
    options = @helper.prepend_style({ style: "opacity:.5" }, "border-color: red;")

    assert_equal("border-color: red; opacity:.5", options[:style])
  end

  def test_prepend_style_with_nothing_to_prepend_onto_leaves_the_declaration_alone
    assert_equal("border-color: red", @helper.prepend_style({}, "border-color: red")[:style])
  end

  def test_prepend_style_keeps_the_hosts_declaration_when_there_is_nothing_to_prepend
    assert_equal("opacity:.5", @helper.prepend_style({ style: "opacity:.5" }, nil)[:style])
  end

  # Through a real write, not by asserting the copy's identity — that would pass
  # for a `dup` nothing ever uses.
  def test_prepending_onto_a_detached_copy_leaves_the_original_alone
    original = { data: { controller: "my-tooltip" } }

    @helper.prepend_controller(@helper.detach_data(original), "modal")

    assert_equal({ controller: "my-tooltip" }, original[:data])
  end

  def test_detach_data_carries_the_data_across
    detached = @helper.detach_data({ id: "card", data: { controller: "my-tooltip" } })

    assert_equal("card", detached[:id])
    assert_equal({ controller: "my-tooltip" }, detached[:data])
  end

  # So it is always safe to call, rather than something to think about first.
  def test_detach_data_leaves_a_hash_without_data_exactly_as_it_found_it
    options = { id: "card" }

    assert_same(options, @helper.detach_data(options))
  end

  # Pinned because 39 other call sites still do this: it is the documented
  # behaviour of the family, not an accident to be fixed in place.
  def test_prepending_straight_onto_a_shared_hash_writes_through_to_it
    shared = { data: { controller: "my-tooltip" } }

    2.times { @helper.prepend_controller(shared.dup, "modal") }

    assert_equal("modal modal my-tooltip", shared[:data][:controller],
                 "`dup` copies the outer hash only — this is why `detach_data` exists")
  end
end
