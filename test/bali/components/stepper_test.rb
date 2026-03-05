# frozen_string_literal: true

require "test_helper"

class BaliStepperComponentTest < ComponentTestCase
  def test_rendering_renders_stepper_with_daisyui_steps_classes
    render_inline(Bali::Stepper::Component.new(current: 0)) do |c|
      c.with_step(title: "Step One")
      c.with_step(title: "Step Two")
    end
    assert_selector("ul.steps")
    assert_selector("li.step", count: 2)
  end

  def test_rendering_renders_horizontal_orientation_by_default
    render_inline(Bali::Stepper::Component.new(current: 0)) do |c|
      c.with_step(title: "Step One")
    end
    assert_selector("ul.steps.steps-horizontal")
  end

  def test_rendering_renders_vertical_orientation_when_specified
    render_inline(Bali::Stepper::Component.new(current: 0, orientation: :vertical)) do |c|
      c.with_step(title: "Step One")
    end
    assert_selector("ul.steps.steps-vertical")
  end

  def test_step_states_renders_first_step_as_active_with_color_class
    render_inline(Bali::Stepper::Component.new(current: 0)) do |c|
      c.with_step(title: "Step One")
      c.with_step(title: "Step Two")
      c.with_step(title: "Step Three")
    end
    # First step is active - gets color class
    assert_selector("li.step.step-primary", text: "Step One")
    # Other steps are pending - no color class
    assert_selector("li.step:not(.step-primary)", text: "Step Two")
    assert_selector("li.step:not(.step-primary)", text: "Step Three")
  end

  def test_step_states_renders_completed_steps_with_color_class_and_checkmark
    render_inline(Bali::Stepper::Component.new(current: 1)) do |c|
      c.with_step(title: "Step One")
      c.with_step(title: "Step Two")
      c.with_step(title: "Step Three")
    end
    # First step is done - gets color class and checkmark
    assert_selector('li.step.step-primary[data-content="✓"]', text: "Step One")
    # Second step is active - gets color class, no checkmark
    assert_selector("li.step.step-primary", text: "Step Two")
    # Third step is pending - no color class
    assert_selector("li.step:not(.step-primary)", text: "Step Three")
  end

  def test_step_states_renders_all_steps_as_done_except_last_one_active
    render_inline(Bali::Stepper::Component.new(current: 2)) do |c|
      c.with_step(title: "Step One")
      c.with_step(title: "Step Two")
      c.with_step(title: "Step Three")
    end
    assert_selector('li.step.step-primary[data-content="✓"]', text: "Step One")
    assert_selector('li.step.step-primary[data-content="✓"]', text: "Step Two")
    assert_selector("li.step.step-primary", text: "Step Three")
  end
  Bali::Stepper::Step::Component::COLORS.each_key do |color|
    define_method("test_color_variants_applies_#{color}_color_to_completed_steps") do
      render_inline(Bali::Stepper::Component.new(current: 1, color: color)) do |c|
        c.with_step(title: "Step One")
        c.with_step(title: "Step Two")
      end
      assert_selector("li.step.step-#{color}")
    end
  end

  def test_options_passthrough_accepts_custom_classes_on_stepper
    render_inline(Bali::Stepper::Component.new(current: 0, class: "custom-class")) do |c|
      c.with_step(title: "Step One")
    end
    assert_selector("ul.steps.custom-class")
  end

  def test_options_passthrough_accepts_custom_classes_on_steps
    render_inline(Bali::Stepper::Component.new(current: 0)) do |c|
      c.with_step(title: "Step One", class: "my-step")
    end
    assert_selector("li.step.my-step")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Stepper::Component.new(current: 0, data: { testid: "stepper" })) do |c|
      c.with_step(title: "Step One")
    end
    assert_selector('ul.steps[data-testid="stepper"]')
  end
end

class BaliStepperStepComponentTest < ComponentTestCase
  def test_status_calculation_returns_active_when_index_equals_current
    component = Bali::Stepper::Step::Component.new(title: "Test", current: 1, index: 1)
    assert_equal(:active, component.status)
    assert(component.active?)
  end

  def test_status_calculation_returns_done_when_index_is_less_than_current
    component = Bali::Stepper::Step::Component.new(title: "Test", current: 2, index: 0)
    assert_equal(:done, component.status)
    assert(component.done?)
  end

  def test_status_calculation_returns_pending_when_index_is_greater_than_current
    component = Bali::Stepper::Step::Component.new(title: "Test", current: 0, index: 2)
    assert_equal(:pending, component.status)
    assert(component.pending?)
  end
end
