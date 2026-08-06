# frozen_string_literal: true

require "test_helper"

class BaliWorkflowStepsComponentTest < ComponentTestCase
  def test_renders_an_ordered_list_with_the_component_class
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Submitted", state: :success)
    end
    assert_selector("ol.workflow-steps li.workflow-step", count: 1)
  end

  def test_accepts_custom_classes_and_html_attributes_on_the_container
    render_inline(Bali::WorkflowSteps::Component.new(class: "my-flow", data: { testid: "flow" })) do |c|
      c.with_step(title: "Submitted", state: :success)
    end
    assert_selector('ol.workflow-steps.my-flow[data-testid="flow"]')
  end

  def test_each_state_paints_its_circle_classes
    {
      success: "bg-success",
      error: "bg-error",
      warning: "bg-warning",
      pending: "bg-base-300",
      skipped: "bg-base-200",
      current: "bg-primary"
    }.each do |state, circle_class|
      render_inline(Bali::WorkflowSteps::Component.new) do |c|
        c.with_step(title: "Step", state: state)
      end
      assert_selector(".workflow-step-circle.#{circle_class}", count: 1)
    end
  end

  def test_current_state_gets_the_ring_emphasis
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "In review", state: :current)
    end
    assert_selector(".workflow-step-circle.ring-2", count: 1)
  end

  def test_steps_are_numbered_automatically_from_one
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :current)
      c.with_step(title: "C", state: :pending)
    end
    assert_equal(%w[1 2 3], circle_texts)
  end

  def test_an_explicit_number_overrides_the_automatic_one
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :pending, number: 7)
      c.with_step(title: "C", state: :pending)
    end
    assert_equal(%w[1 7 2], circle_texts)
  end

  def test_a_skipped_step_shows_no_number_and_consumes_no_position
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :skipped)
      c.with_step(title: "C", state: :pending)
    end

    assert_equal([ "1", "", "2" ], circle_texts)
    assert_selector("li:nth-child(2) .workflow-step-circle .icon-component")
  end

  def test_an_explicit_number_still_wins_on_a_skipped_step
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :skipped, number: 4)
    end
    assert_equal(%w[4], circle_texts)
  end

  def test_the_connector_takes_the_state_of_the_next_step
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :error)
      c.with_step(title: "C", state: :pending)
    end

    assert_selector("li:nth-child(1) .workflow-step-connector.bg-error", count: 1)
    assert_selector("li:nth-child(2) .workflow-step-connector.bg-base-300", count: 1)
  end

  def test_the_last_step_draws_no_connector
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :pending)
    end

    assert_selector(".workflow-step-connector", count: 1)
    assert_no_selector("li:last-child .workflow-step-connector")
  end

  def test_a_single_step_draws_no_connector
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Only", state: :pending)
    end
    assert_no_selector(".workflow-step-connector")
  end

  def test_an_unknown_state_raises_with_the_valid_names
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new) do |c|
        c.with_step(title: "A", state: :done)
      end
    end
    assert_includes(error.message, "unknown state :done")
    assert_includes(error.message, ":skipped")
  end

  def test_a_nil_state_raises_instead_of_rendering_a_broken_circle
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new) do |c|
        c.with_step(title: "A", state: nil)
      end
    end
    assert_includes(error.message, "state is required")
  end

  def test_assignee_and_date_render_in_the_step_body
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Review", state: :success,
                  assignee: "Ana Gutiérrez", date: "Jul 2, 2026")
    end

    assert_selector(".workflow-step-assignee", text: "Ana Gutiérrez")
    assert_selector(".workflow-step-date", text: "Jul 2, 2026")
  end

  def test_assignee_and_date_are_omitted_when_absent
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Review", state: :pending)
    end

    assert_no_selector(".workflow-step-assignee")
    assert_no_selector(".workflow-step-date")
  end

  def test_the_block_renders_as_the_comment
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal", state: :error) { "Rejected: missing appendix B." }
    end
    assert_selector(".workflow-step-comment", text: "Rejected: missing appendix B.")
  end

  def test_no_comment_container_without_a_block
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal", state: :pending)
    end
    assert_no_selector(".workflow-step-comment")
  end

  def test_pending_and_skipped_titles_read_muted
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Done", state: :success)
      c.with_step(title: "Skipped", state: :skipped)
      c.with_step(title: "Later", state: :pending)
    end

    assert_selector('li:nth-child(2) .workflow-step-title[class*="text-base-content/40"]')
    assert_selector('li:nth-child(3) .workflow-step-title[class*="text-base-content/40"]')
    assert_no_selector('li:nth-child(1) .workflow-step-title[class*="text-base-content/40"]')
  end

  def test_step_html_attributes_reach_the_list_item
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success, class: "my-step", data: { testid: "step-a" })
    end
    assert_selector('li.workflow-step.my-step[data-testid="step-a"]')
  end

  private

  # Circle contents in document order; a skipped circle's icon has no text.
  def circle_texts
    page.all(".workflow-step-circle", visible: :all).map { |node| node.text.strip }
  end
end

class BaliWorkflowStepsStepComponentTest < ComponentTestCase
  def test_constants_the_class_tables_are_frozen_and_agree_on_the_states
    assert(Bali::WorkflowSteps::Step::Component::CIRCLE_CLASSES.frozen?)
    assert(Bali::WorkflowSteps::Step::Component::CONNECTOR_CLASSES.frozen?)
    assert_equal(
      Bali::WorkflowSteps::Step::Component::STATES,
      Bali::WorkflowSteps::Step::Component::CONNECTOR_CLASSES.keys
    )
  end

  def test_constants_covers_the_six_states
    assert_equal(
      %i[success error warning pending skipped current],
      Bali::WorkflowSteps::Step::Component::STATES
    )
  end

  def test_rendered_standalone_it_draws_no_connector
    render_inline(
      Bali::WorkflowSteps::Step::Component.new(title: "Solo", state: :success, number: 1)
    )
    assert_no_selector(".workflow-step-connector")
    assert_selector(".workflow-step-circle", text: "1")
  end
end
