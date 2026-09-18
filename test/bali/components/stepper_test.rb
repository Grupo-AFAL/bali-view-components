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

  def test_step_sublabel_renders_below_title
    render_inline(Bali::Stepper::Component.new(current: 1)) do |c|
      c.with_step(title: "Aprobado", sublabel: "03/07 · Ana Gutiérrez")
      c.with_step(title: "Publicado")
    end

    assert_selector("li.step .step-sublabel", text: "03/07 · Ana Gutiérrez")
    assert_selector("li.step", text: "Aprobado")
  end

  def test_step_without_sublabel_renders_no_sublabel_element
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Step One")
    end

    assert_no_selector(".step-sublabel")
  end

  def test_step_renders_free_content_block
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado") { "publicación #12" }
    end

    assert_selector("li.step", text: "Publicado")
    assert_selector("li.step", text: "publicación #12")
  end

  # A host writes "the detail, if there is one" by deciding inside the block,
  # and ViewComponent's `content?` is true for any block whatever it renders —
  # so every step took the wrapping branch and the bare `else` was unreachable
  # for anyone passing a block. Same wrong predicate as Bali::WorkflowSteps
  # (#1153); the wrapper here carries no class, so nothing moves on screen.
  def test_a_block_that_renders_nothing_draws_no_wrapper
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado") { "" }
    end

    assert_no_selector("li.step > div", visible: :all)
    assert_selector("li.step", text: "Publicado")
  end

  # Whitespace is its own case: `content?` is true here as well, and it is
  # `blank?` inside `present?` — not emptiness — that drops the wrapper. A
  # condition narrowed to a bare emptiness check would pass the test above and
  # fail this one.
  def test_a_block_of_only_whitespace_draws_no_wrapper
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado") { "\n      \n" }
    end

    assert_no_selector("li.step > div", visible: :all)
    assert_selector("li.step", text: "Publicado")
  end

  # Every case above hands `with_step` a Ruby block that returns a String. A
  # host writes ERB with the `if` inside, which hands ViewComponent a captured
  # buffer instead — the form the issue describes and the form the preview
  # teaches. It gets rendered as ERB here rather than approximated, so nothing
  # about the fix rests on the two spellings capturing the same way.
  def test_an_erb_block_whose_condition_is_false_draws_no_wrapper
    rendered = Capybara.string(vc_test_controller.view_context.render(inline: <<~ERB))
      <%= render Bali::Stepper::Component.new(current: 1) do |c| %>
        <% detail = nil %>
        <% c.with_step(title: 'Publicado') do %>
          <% if detail.present? %>
            <span class="text-xs opacity-60"><%= detail %></span>
          <% end %>
        <% end %>
      <% end %>
    ERB

    assert_no_selector(rendered, "li.step > div", visible: :all)
    assert_equal "Publicado", rendered.find("li.step").text.squish
  end

  # The whitespace an ERB block leaves around real content must not read as
  # blank — the fix has to drop the empty wrapper, not the working one.
  def test_a_block_padded_with_whitespace_still_wraps
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado") { "\n  publicación #12\n" }
    end

    assert_selector("li.step > div", text: "publicación #12")
  end

  # The exact edge of the new predicate: `content.present?` reads the rendered
  # string, so a block that writes markup showing no text — a Stimulus mount, a
  # hidden field — still wraps, same answer WorkflowSteps gives. A condition
  # narrowed to the visible text would pass every other case in this file and
  # drop that node on the floor.
  def test_a_block_of_markup_without_text_still_wraps
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado") { '<input type="hidden" name="step_id" value="12">'.html_safe }
    end

    assert_selector("li.step > div", visible: :all)
    assert_selector('li.step > div input[type="hidden"][name="step_id"]', visible: :all)
  end

  # `sublabel:` keeps the wrapper on its own: the step still has two lines to
  # stack, so a blank block must not take the sublabel down with it.
  def test_a_sublabel_with_a_blank_block_keeps_its_wrapper
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Aprobado", sublabel: "03/07 · Ana Gutiérrez") { "" }
    end

    assert_selector("li.step > div .step-sublabel", text: "03/07 · Ana Gutiérrez")
  end

  # `sublabel:` and a block with real content is the only case where all three
  # nodes land inside the wrapper at once, so it is the only place their order
  # is pinned: title, sublabel, then the block's markup.
  def test_a_sublabel_and_a_real_block_stack_title_sublabel_and_content_in_order
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado", sublabel: "03/07 · Ana Gutiérrez") do
        '<span class="detail">publicación #12</span>'.html_safe
      end
    end

    stacked = page.all("li.step > div > *", visible: :all).map { |node| node.text.squish }
    assert_equal [ "Publicado", "03/07 · Ana Gutiérrez", "publicación #12" ], stacked
  end

  # Every assertion above names a selector, so all of them stay green while the
  # template leaks prose as text — which is exactly what a malformed ERB comment
  # in it does. This one reads the body instead: a step with no block says its
  # title and nothing else.
  def test_a_step_without_a_block_says_its_title_and_nothing_else
    render_inline(Bali::Stepper::Component.new) do |c|
      c.with_step(title: "Publicado")
    end

    assert_equal "Publicado", page.find("li.step").text.squish
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
