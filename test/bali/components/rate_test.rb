# frozen_string_literal: true

require "test_helper"

class BaliRateComponentTest < ComponentTestCase
  def setup
    @form = movie_form_builder
    @component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3)
  end

  # basic rendering

  def test_basic_rendering_renders_with_daisyui_rating_classes
    render_inline(@component)
    assert_selector("div.rating")
  end

  def test_basic_rendering_renders_5_star_inputs_by_default
    render_inline(@component)
    assert_selector("input.mask.mask-star-2", count: 5)
  end

  def test_basic_rendering_renders_with_role_radiogroup_for_accessibility
    render_inline(@component)
    assert_selector('div.rating[role="radiogroup"]')
  end

  def test_basic_rendering_renders_with_aria_label
    render_inline(@component)
    assert_selector('div.rating[aria-label="Rating"]')
  end

  def test_basic_rendering_marks_the_correct_star_as_checked
    render_inline(@component)
    assert_selector('input[value="3"][checked]')
  end

  # sizes

  Bali::Rate::Component::SIZES.each do |size_key, size_class|
    define_method("test_sizes_renders_#{size_key}_size") do
      render_inline(Bali::Rate::Component.new(value: 3, size: size_key, readonly: true))
      assert_selector("div.rating.#{size_class}")
    end
  end

  # colors

  Bali::Rate::Component::COLORS.each do |color_key, color_class|
    define_method("test_colors_renders_#{color_key}_color") do
      render_inline(Bali::Rate::Component.new(value: 3, color: color_key, readonly: true))
      assert_selector("input.#{color_class}")
    end
  end

  # auto_submit mode

  def test_auto_submit_mode_renders_radio_inputs_for_visual_feedback
    component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3, auto_submit: true)
    render_inline(component)
    assert_selector('input[type="radio"].mask.mask-star-2', count: 5)
  end

  def test_auto_submit_mode_adds_stimulus_controller_to_container
    component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3, auto_submit: true)
    render_inline(component)
    assert_selector('div[data-controller="rate"]')
    assert_selector('div[data-rate-auto-submit-value="true"]')
  end

  def test_auto_submit_mode_adds_data_action_for_stimulus_submit
    component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3, auto_submit: true)
    render_inline(component)
    assert_selector('input[data-action="change->rate#submit"]', count: 5)
  end

  def test_auto_submit_mode_includes_hidden_input_for_form_submission
    component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3, auto_submit: true)
    render_inline(component)
    assert_selector('input[type="hidden"][name="movie[rating]"][data-rate-target="input"]', visible: :hidden)
  end

  def test_auto_submit_mode_includes_aria_label_on_radio_inputs
    component = Bali::Rate::Component.new(form: @form, method: :rating, value: 3, auto_submit: true)
    render_inline(component)
    assert_selector('input[aria-label="1 stars"]')
    assert_selector('input[aria-label="5 stars"]')
  end

  # readonly mode

  def test_readonly_mode_renders_disabled_inputs
    component = Bali::Rate::Component.new(value: 4, readonly: true)
    render_inline(component)
    assert_selector("input[disabled]", count: 5)
  end

  def test_readonly_mode_does_not_require_form_or_method
    component = Bali::Rate::Component.new(value: 4, readonly: true)
    assert_nothing_raised { render_inline(component) }
  end

  def test_readonly_mode_does_not_have_role_radiogroup
    component = Bali::Rate::Component.new(value: 4, readonly: true)
    render_inline(component)
    assert_no_selector('[role="radiogroup"]')
  end

  def test_readonly_mode_marks_the_correct_star_as_checked
    component = Bali::Rate::Component.new(value: 4, readonly: true)
    render_inline(component)
    assert_selector("input[disabled][checked]", count: 1)
  end

  # form integration

  def test_form_integration_uses_form_radio_button_helper
    render_inline(@component)
    assert_selector('input[type="radio"][name="movie[rating]"]', count: 5)
  end

  def test_form_integration_generates_correct_ids_for_each_star
    render_inline(@component)
    assert_selector('input[id="movie_rating_1"]')
    assert_selector('input[id="movie_rating_5"]')
  end

  # custom scale

  def test_custom_scale_renders_specified_number_of_stars
    render_inline(Bali::Rate::Component.new(value: 2, scale: 1..3, readonly: true))
    assert_selector("input.mask-star-2", count: 3)
  end

  def test_custom_scale_supports_10_star_scale
    render_inline(Bali::Rate::Component.new(value: 7, scale: 1..10, readonly: true))
    assert_selector("input.mask-star-2", count: 10)
  end

  # options passthrough

  def test_options_passthrough_accepts_custom_class
    render_inline(Bali::Rate::Component.new(value: 3, readonly: true, class: "my-custom-class"))
    assert_selector("div.rating.my-custom-class")
  end

  def test_options_passthrough_accepts_custom_aria_label
    render_inline(Bali::Rate::Component.new(value: 3, readonly: true, "aria-label": "Movie rating"))
    assert_selector('div.rating[aria-label="Movie rating"]')
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Rate::Component.new(value: 3, readonly: true, data: { testid: "rating" }))
    assert_selector('div.rating[data-testid="rating"]')
  end
end
