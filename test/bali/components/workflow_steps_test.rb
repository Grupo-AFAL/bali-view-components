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

  # The circle says the state in colour and the number says a position, so
  # without this a screen reader hears "3, Legal review" and never learns the
  # step was rejected.
  def test_every_state_is_named_for_a_screen_reader
    {
      success: "Completed",
      error: "Rejected",
      warning: "Needs attention",
      pending: "Pending",
      skipped: "Skipped",
      current: "In progress"
    }.each do |state, label|
      render_inline(Bali::WorkflowSteps::Component.new) do |c|
        c.with_step(title: "Step", state: state)
      end
      assert_selector(".workflow-step-marker .sr-only", text: label, visible: :all)
    end
  end

  # Inside the circle it would be announced as part of the number and would
  # break every assertion about what the circle contains.
  def test_the_state_name_sits_outside_the_circle
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal review", state: :error)
    end

    assert_no_selector(".workflow-step-circle .sr-only", visible: :all)
    assert_equal(%w[1], circle_texts)
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
    assert(Bali::WorkflowSteps::Step::Component::DOT_CLASSES.frozen?)
    assert_equal(
      Bali::WorkflowSteps::Step::Component::STATES,
      Bali::WorkflowSteps::Step::Component::CONNECTOR_CLASSES.keys
    )
    assert_equal(
      Bali::WorkflowSteps::Step::Component::STATES,
      Bali::WorkflowSteps::Step::Component::DOT_CLASSES.keys
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

  def test_a_dot_step_draws_the_dot_instead_of_the_circle
    render_inline(
      Bali::WorkflowSteps::Step::Component.new(title: "Solo", state: :success, number: 1, dot: true)
    )
    assert_selector(".workflow-step-dot.bg-success")
    assert_no_selector(".workflow-step-circle")
  end
end

class BaliWorkflowStepsHorizontalTest < ComponentTestCase
  def test_the_root_is_a_div_carrying_the_variant_class
    render_horizontal do |c|
      c.with_step(title: "Submitted", state: :success)
    end

    assert_selector("div.workflow-steps.workflow-steps-horizontal")
    assert_selector("div.workflow-steps > ol.workflow-steps-list > li.workflow-step", count: 1)
  end

  def test_the_vertical_root_keeps_the_list_and_takes_its_own_variant_class
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Submitted", state: :success)
    end

    assert_selector("ol.workflow-steps.workflow-steps-vertical")
    assert_no_selector(".workflow-steps-horizontal")
  end

  def test_html_attributes_land_on_the_root_div
    render_inline(
      Bali::WorkflowSteps::Component.new(orientation: :horizontal, class: "my-flow", data: { testid: "flow" })
    ) do |c|
      c.with_step(title: "Submitted", state: :success)
    end

    assert_selector('div.workflow-steps.workflow-steps-horizontal.my-flow[data-testid="flow"]')
  end

  def test_each_state_paints_its_dot_classes
    {
      success: "bg-success",
      error: "bg-error",
      warning: "bg-warning",
      pending: "bg-base-300",
      skipped: "bg-base-100",
      current: "bg-primary"
    }.each do |state, dot_class|
      render_horizontal do |c|
        c.with_step(title: "Step", state: state)
      end
      assert_selector(".workflow-step-dot.#{dot_class}", count: 1)
      assert_no_selector(".workflow-step-circle")
    end
  end

  # The vertical circle tells these two apart with a dash where the number
  # would be; the dot has no such room, and two greys at 10px are one grey.
  def test_the_skipped_dot_is_hollow_where_the_pending_one_is_filled
    render_horizontal do |c|
      c.with_step(title: "Skipped", state: :skipped)
      c.with_step(title: "Later", state: :pending)
    end

    assert_selector("li:nth-child(1) .workflow-step-dot.ring-1.ring-base-300")
    assert_no_selector("li:nth-child(2) .workflow-step-dot.ring-1")
  end

  def test_the_current_dot_gets_the_ring_emphasis
    render_horizontal do |c|
      c.with_step(title: "In review", state: :current)
    end
    assert_selector(".workflow-step-dot.ring-2", count: 1)
  end

  # The bar already says how far the flow got; a second line saying the same
  # thing between the cards is noise, and it has nowhere to run in a wrapped row.
  def test_no_connectors_are_drawn
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :error)
      c.with_step(title: "C", state: :pending)
    end
    assert_no_selector(".workflow-step-connector")
  end

  def test_the_step_body_renders_the_same_as_in_the_vertical_variant
    render_horizontal do |c|
      c.with_step(title: "Legal review", state: :error,
                  assignee: "Ana Gutiérrez", date: "Jul 4, 2026") { "Missing appendix B." }
    end

    assert_selector(".workflow-step-title", text: "Legal review")
    assert_selector(".workflow-step-assignee", text: "Ana Gutiérrez")
    assert_selector(".workflow-step-date", text: "Jul 4, 2026")
    assert_selector(".workflow-step-comment", text: "Missing appendix B.")
  end

  def test_the_dot_is_decorative_and_the_state_is_read_from_the_sr_only_name
    render_horizontal do |c|
      c.with_step(title: "Legal review", state: :error)
    end

    assert_selector('.workflow-step-dot[aria-hidden="true"]', visible: :all)
    assert_selector(".workflow-step-marker .sr-only", text: "Rejected", visible: :all)
  end

  def test_the_progress_bar_counts_the_steps_with_a_verdict
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :warning)
      c.with_step(title: "C", state: :current)
      c.with_step(title: "D", state: :pending)
    end

    assert_selector('.workflow-steps-progress progress.progress[value="2"][max="4"]')
    assert_selector(".workflow-steps-count", text: "2/4")
  end

  # A step the route left out is settled, and it is still one of the dots on
  # screen: counting it keeps N/M matching what the reader can count.
  def test_a_skipped_step_counts_as_resolved_on_both_sides_of_the_bar
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :skipped)
      c.with_step(title: "C", state: :pending)
    end

    assert_selector('.workflow-steps-progress progress.progress[value="2"][max="3"]')
    assert_selector(".workflow-steps-count", text: "2/3")
  end

  def test_neither_pending_nor_current_counts_as_resolved
    render_horizontal do |c|
      c.with_step(title: "A", state: :current)
      c.with_step(title: "B", state: :pending)
    end

    assert_selector('.workflow-steps-progress progress.progress[value="0"][max="2"]')
    assert_selector(".workflow-steps-count", text: "0/2")
  end

  def test_a_flow_with_every_step_resolved_fills_the_bar
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :success)
    end
    assert_selector('.workflow-steps-progress progress.progress[value="2"][max="2"]')
  end

  def test_the_bar_is_neutral_while_nothing_has_gone_wrong
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :pending)
    end
    assert_selector("progress.progress-primary")
  end

  def test_a_rejected_step_turns_the_bar_red
    render_horizontal do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :error)
      c.with_step(title: "C", state: :pending)
    end
    assert_selector("progress.progress-error")
  end

  def test_an_error_outranks_a_warning
    render_horizontal do |c|
      c.with_step(title: "A", state: :warning)
      c.with_step(title: "B", state: :error)
    end

    assert_selector("progress.progress-error")
    assert_no_selector("progress.progress-warning")
  end

  def test_a_warning_alone_turns_the_bar_amber
    render_horizontal do |c|
      c.with_step(title: "A", state: :warning)
      c.with_step(title: "B", state: :pending)
    end
    assert_selector("progress.progress-warning")
  end

  def test_the_bar_can_be_turned_off
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :horizontal, progress: false)) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_no_selector(".workflow-steps-progress")
    assert_selector("ol.workflow-steps-list li.workflow-step", count: 1)
  end

  # `<progress max="0">` is not valid HTML, and a bar over no steps says nothing.
  def test_a_flow_with_no_steps_draws_no_bar
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :horizontal))

    assert_no_selector(".workflow-steps-progress")
    assert_selector("ol.workflow-steps-list")
  end

  def test_the_vertical_variant_never_draws_the_bar
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "A", state: :success)
    end
    assert_no_selector(".workflow-steps-progress")
  end

  def test_asking_for_the_bar_on_the_vertical_variant_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new(progress: true)) do |c|
        c.with_step(title: "A", state: :success)
      end
    end

    assert_includes(error.message, "progress: true needs orientation: :horizontal")
  end

  # `progress: false` asks for nothing, so there is nothing to refuse.
  def test_turning_the_bar_off_on_the_vertical_variant_is_allowed
    render_inline(Bali::WorkflowSteps::Component.new(progress: false)) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_selector("ol.workflow-steps-vertical")
    assert_no_selector(".workflow-steps-progress")
  end

  def test_the_renamed_variant_keyword_raises_pointing_at_orientation
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new(variant: :horizontal))
    end
    assert_includes(error.message, "`variant:` was renamed to `orientation:`")
  end

  def test_an_unknown_orientation_raises_with_the_valid_names
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new(orientation: :sideways))
    end

    assert_includes(error.message, "unknown orientation :sideways")
    assert_includes(error.message, ":horizontal")
  end

  private

  def render_horizontal(&block)
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :horizontal), &block)
  end
end
