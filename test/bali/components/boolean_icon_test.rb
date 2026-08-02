# frozen_string_literal: true

require "test_helper"

class BaliBooleanIconComponentTest < ComponentTestCase
  def test_with_true_value_renders_success_styling
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    assert_selector("div.boolean-icon-component.text-success")
  end

  def test_with_true_value_renders_check_circle_icon
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    # Verify icon is rendered (SVG with path)
    assert_selector(".icon-component svg")
  end

  def test_with_false_value_renders_error_styling
    render_inline(Bali::BooleanIcon::Component.new(value: false))
    assert_selector("div.boolean-icon-component.text-error")
  end

  def test_with_false_value_renders_times_circle_icon
    render_inline(Bali::BooleanIcon::Component.new(value: false))
    # Verify icon is rendered (SVG with path)
    assert_selector(".icon-component svg")
  end

  # A record that never answered the question has not answered "no". Both the
  # icon and the announced name stay neutral, or the component asserts something
  # the data does not say.
  def test_with_nil_value_renders_a_neutral_state_instead_of_false
    render_inline(Bali::BooleanIcon::Component.new(value: nil))
    assert_selector("div.boolean-icon-component")
    assert_no_selector("div.text-error")
    assert_no_selector("div.text-success")
    assert_selector(".icon-component svg")
  end

  def test_with_nil_value_does_not_announce_no
    render_inline(Bali::BooleanIcon::Component.new(value: nil))
    assert_selector("span.sr-only", text: "Not specified")
    assert_no_selector("span.sr-only", text: "No", exact_text: true)
  end

  # Only nil is missing data: a truthy non-boolean keeps reading as true, which
  # is what the old `!!value` coercion did for everything but nil.
  def test_coerces_a_truthy_non_boolean_to_true
    render_inline(Bali::BooleanIcon::Component.new(value: "anything"))
    assert_selector("div.boolean-icon-component.text-success")
    assert_selector("span.sr-only", text: "Yes")
  end

  def test_a11y_names_the_true_state
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    assert_selector("span.sr-only", text: "Yes")
  end

  def test_a11y_names_the_false_state
    render_inline(Bali::BooleanIcon::Component.new(value: false))
    assert_selector("span.sr-only", text: "No")
  end

  # The Lucide SVG already ships aria-hidden; the wrapper says so too, so the
  # only node left with a name is the sr-only text.
  def test_a11y_hides_the_icon_from_the_accessibility_tree
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    assert_selector('.icon-component[aria-hidden="true"]')
  end

  def test_a11y_accepts_a_label_for_context
    render_inline(Bali::BooleanIcon::Component.new(value: true, label: "Indie film: yes"))
    assert_selector("span.sr-only", text: "Indie film: yes")
  end

  def test_a11y_translates_the_default_name
    I18n.with_locale(:es) do
      render_inline(Bali::BooleanIcon::Component.new(value: nil))
      assert_selector("span.sr-only", text: "Sin especificar")
    end
  end

  def test_options_passthrough_merges_custom_classes
    render_inline(Bali::BooleanIcon::Component.new(value: true, class: "custom-class"))
    assert_selector("div.boolean-icon-component.custom-class")
  end

  def test_options_passthrough_passes_data_attributes
    render_inline(Bali::BooleanIcon::Component.new(value: true, data: { testid: "boolean-icon" }))
    assert_selector('[data-testid="boolean-icon"]')
  end
end
