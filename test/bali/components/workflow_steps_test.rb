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

  # A host writes "the comment, if there is one" by deciding inside the block,
  # and ViewComponent's `content?` is true for any block whatever it renders.
  # An empty container is not an invisible one — it carries `mt-1` — so every
  # step without a comment grew by a margin over nothing.
  def test_a_block_that_renders_nothing_draws_no_comment_container
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal", state: :success) { "" }
    end
    assert_no_selector(".workflow-step-comment")
  end

  # Whitespace is its own case: `content?` is true here as well, and it is
  # `blank?` inside `present?` — not emptiness — that drops the container. A
  # condition narrowed to a bare emptiness check on the capture would still
  # pass the test above and fail this one.
  def test_a_block_of_only_whitespace_draws_no_comment_container
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal", state: :success) { "\n      \n" }
    end
    assert_no_selector(".workflow-step-comment")
  end

  # The whitespace an ERB block leaves around real content must not read as
  # blank — the fix has to drop the empty container, not the working one.
  def test_a_block_padded_with_whitespace_still_renders_its_comment
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Legal", state: :error) { "\n  Rejected: missing appendix B.\n" }
    end
    assert_selector(".workflow-step-comment", text: "Rejected: missing appendix B.")
  end

  # Every assertion above names a selector, so all of them stay green while the
  # template leaks prose as text — which is exactly what a malformed ERB comment
  # in it does. This one reads the body instead: a step with no block says its
  # title and nothing else.
  def test_a_step_without_a_block_says_its_title_and_nothing_else
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Submitted", state: :success)
    end
    assert_equal "Submitted", page.find(".workflow-step-body").text.squish
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

  # The other half of the same contract, and the one with no net until now:
  # every keyword this component does not declare reaches the root as a plain
  # HTML attribute. What is pinned here is that contract, not any one spelling
  # — declaring a keyword that a host is already passing turns live markup into
  # an ArgumentError with every other test still green, and this is the test
  # that notices. `style:` is the example because it is the one name a host
  # writes on purpose; the day this component wants a semantic `style:` enum
  # like its siblings, this test is the checklist of what that costs, not a
  # veto.
  def test_undeclared_keywords_reach_the_root_as_html_attributes
    render_inline(
      Bali::WorkflowSteps::Component.new(style: "max-width:40rem", title: "Approval chain")
    ) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_selector('ol.workflow-steps[style="max-width:40rem"]')
    assert_selector('ol.workflow-steps[title="Approval chain"]')
  end

  def test_undeclared_keywords_reach_the_horizontal_root_too
    render_inline(
      Bali::WorkflowSteps::Component.new(orientation: :horizontal, style: "max-width:40rem",
                                         title: "Approval chain")
    ) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_selector('div.workflow-steps.workflow-steps-horizontal[style="max-width:40rem"]')
    assert_selector('div.workflow-steps.workflow-steps-horizontal[title="Approval chain"]')
  end

  # The six global strings are deliberately generic, and a host that overrides
  # `states.error` to "Discarded" changes it for every other flow in the app.
  # This is the per-step hatch, shaped like `Bali::BooleanIcon`'s `label:`.
  def test_a_step_can_name_its_own_state_for_a_screen_reader
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "Not taken")
    end
    assert_selector(".workflow-step-marker .sr-only", text: "Not taken", visible: :all)
  end

  # ActionView emits every key that is not `data`/`aria` verbatim, so an
  # undeclared `state_label:` printed itself on the `<li>` as an invalid
  # attribute and changed nothing a screen reader hears.
  def test_the_state_label_does_not_leak_as_an_html_attribute
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "Not taken")
    end
    assert_no_selector("li.workflow-step[state_label]", visible: :all)
  end

  def test_a_step_without_a_state_label_keeps_the_translated_name
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped)
    end
    assert_selector(".workflow-step-marker .sr-only", text: "Skipped", visible: :all)
  end

  # `nil` means "not given"; anything else is the accessible name the host
  # asked for, empty string included. `.presence ||` would quietly hand back
  # "Skipped" to a host that asked for silence. Same rule as
  # `Bali::BooleanIcon#label`, pinned there too.
  #
  # What is pinned is the ANNOUNCEMENT, not the markup: nothing is read out.
  # Today that is an empty `sr-only` span, which contributes no node to the
  # accessibility tree; a later cleanup that renders no span at all keeps this
  # test green, which is the point — the rule is about what a screen reader
  # says, and only a fallback to "Skipped" should turn it red.
  def test_an_empty_state_label_is_taken_literally
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "")
    end

    assert_equal "", announced_states.join
  end

  # The one thing a host can put in that span is a string it built itself.
  def test_a_state_label_is_escaped_like_any_other_host_string
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "<b>Not</b> taken")
    end

    assert_no_selector(".workflow-step-marker .sr-only b", visible: :all)
    assert_equal "<b>Not</b> taken", announced_states.first
  end

  # The label is the step's, not the flow's: two steps in the same state read
  # differently when the host says so.
  def test_the_state_label_only_touches_its_own_step
    render_inline(Bali::WorkflowSteps::Component.new) do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "Not taken")
      c.with_step(title: "Pilot", state: :skipped)
    end

    assert_equal [ "Not taken", "Skipped" ], announced_states
  end

  private

  # What a screen reader would read out for each step's state, in document
  # order. Reading the text rather than asserting the span exists keeps these
  # tests about the announcement — see `test_an_empty_state_label_...`.
  def announced_states
    page.all(".workflow-step-marker .sr-only", visible: :all).map { |node| node.text(:all) }
  end

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

  # The shape where the `sr-only` name is the ONLY state information there is:
  # the dot carries no number, so a reader who cannot see colour has nothing
  # else to go on. The per-step hatch has to reach it.
  def test_a_horizontal_step_can_name_its_own_state
    render_horizontal do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "Not taken")
      c.with_step(title: "Pilot", state: :skipped)
    end

    labels = page.all(".workflow-step-marker .sr-only", visible: :all).map { |node| node.text(:all) }
    assert_equal [ "Not taken", "Skipped" ], labels
  end

  # The scroll hatch is the rail's alone: the cards wrap instead of
  # overflowing, so a tab stop here would be a stop on something that never
  # scrolls.
  def test_the_horizontal_list_is_not_a_focusable_scroll_region
    render_horizontal do |c|
      c.with_step(title: "Submitted", state: :success)
    end

    assert_no_selector("ol.workflow-steps-list[tabindex]")
    assert_no_selector("ol.workflow-steps-list[aria-label]")
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

# The rail is the third shape: one row of numbered circles joined by
# connectors, the label under each. `orientation:` is the axis because it is
# the only keyword this component validates — every other spelling (`style:`,
# `shape:`, `layout:`) is a live HTML passthrough to the root today, so taking
# one would have turned working markup into an ArgumentError.
class BaliWorkflowStepsRailTest < ComponentTestCase
  def test_the_rail_is_a_third_orientation_with_its_own_root_class
    render_rail do |c|
      c.with_step(title: "Capture", state: :success)
    end

    assert_selector("div.workflow-steps.workflow-steps-rail")
    assert_no_selector(".workflow-steps-horizontal")
    assert_no_selector(".workflow-steps-vertical")
  end

  # Same wrapper as the quick flow: a div around `ol.workflow-steps-list`, so
  # the optional N/M header has a line to sit on above the row.
  def test_the_rail_wraps_its_list_the_way_the_quick_flow_does
    render_rail do |c|
      c.with_step(title: "Capture", state: :success)
      c.with_step(title: "Triage", state: :current)
    end

    assert_selector("div.workflow-steps > ol.workflow-steps-list > li.workflow-step", count: 2)
  end

  # The rail's marker is the vertical shape's numbered circle, not the quick
  # flow's dot: the number is what makes nine steps in a row readable as an
  # order rather than a row of lights.
  def test_the_rail_numbers_its_markers_instead_of_drawing_dots
    render_rail do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :current)
      c.with_step(title: "C", state: :pending)
    end

    assert_no_selector(".workflow-step-dot")
    assert_equal(%w[1 2 3], circle_texts)
  end

  def test_the_rail_keeps_the_skipped_step_out_of_the_numbering
    render_rail do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :skipped)
      c.with_step(title: "C", state: :pending)
    end
    assert_equal([ "1", "", "2" ], circle_texts)
  end

  # The connectors are the rail. They are also what replaces the N/M bar: each
  # one arrives coloured at the step that owns the verdict, exactly as in the
  # vertical shape.
  def test_the_rail_draws_a_connector_between_each_pair_of_steps
    render_rail do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :error)
      c.with_step(title: "C", state: :pending)
    end

    assert_selector(".workflow-step-connector", count: 2)
    assert_selector("li:nth-child(1) .workflow-step-connector.bg-error")
    assert_selector("li:nth-child(2) .workflow-step-connector.bg-base-300")
    assert_no_selector("li:last-child .workflow-step-connector")
  end

  # Measured before building it: all four horizontal call sites in the fleet
  # pass `progress: false`. In the rail the connectors already say how far the
  # flow got, so the bar starts off and a host that wants it says so.
  def test_the_rail_draws_no_bar_by_default
    render_rail do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :pending)
    end
    assert_no_selector(".workflow-steps-progress")
  end

  def test_the_rail_can_opt_into_the_bar
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :rail, progress: true)) do |c|
      c.with_step(title: "A", state: :success)
      c.with_step(title: "B", state: :pending)
    end

    assert_selector('.workflow-steps-progress progress.progress[value="1"][max="2"]')
    assert_selector(".workflow-steps-count", text: "1/2")
  end

  def test_the_rail_announces_the_state_like_every_other_shape
    render_rail do |c|
      c.with_step(title: "Evaluation", state: :skipped, state_label: "Not taken")
      c.with_step(title: "Legal review", state: :error)
    end

    assert_selector("li:nth-child(1) .workflow-step-marker .sr-only", text: "Not taken", visible: :all)
    assert_selector("li:nth-child(2) .workflow-step-marker .sr-only", text: "Rejected", visible: :all)
  end

  def test_html_attributes_land_on_the_rail_root
    render_inline(
      Bali::WorkflowSteps::Component.new(orientation: :rail, class: "funnel",
                                         style: "max-width:60rem", data: { testid: "rail" })
    ) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_selector('div.workflow-steps.workflow-steps-rail.funnel[data-testid="rail"][style="max-width:60rem"]')
  end

  # The rail hides nothing the caller passed: a narrow column is a reason not
  # to pass a comment, not a reason for the component to drop one.
  def test_the_rail_renders_the_same_step_body_as_the_other_shapes
    render_rail do |c|
      c.with_step(title: "Legal review", state: :error,
                  assignee: "Ana Gutiérrez", date: "Jul 4, 2026") { "Missing appendix B." }
    end

    assert_selector(".workflow-step-title", text: "Legal review")
    assert_selector(".workflow-step-assignee", text: "Ana Gutiérrez")
    assert_selector(".workflow-step-date", text: "Jul 4, 2026")
    assert_selector(".workflow-step-comment", text: "Missing appendix B.")
  end

  # WCAG 2.1.1. The rail is the one shape that can overflow — measured at
  # 400px with nine steps, `list.scrollWidth 864 > clientWidth 336` — and a
  # scroll container with no focusable descendant is content a keyboard user
  # cannot reach at all. `docs/guides/accessibility.md` prescribes
  # `tabindex="0"` plus a name for exactly this.
  #
  # No `role=`: measured in the browser, `role="region"` (or `"group"`) on an
  # `<ol>` REPLACES its `list` role, so the reader stops being told how many
  # steps there are. `<ol tabindex="0" aria-label="...">` snapshots as
  # `list "Workflow steps"` — focusable, named, still a list.
  def test_the_rail_list_is_reachable_by_keyboard_and_named
    render_rail do |c|
      c.with_step(title: "Capture", state: :success)
    end

    assert_selector('ol.workflow-steps-list[tabindex="0"]')
    assert_selector("ol.workflow-steps-list[aria-label]")
    assert_no_selector("ol.workflow-steps-list[role]")
  end

  def test_the_rail_scroll_region_is_named_from_the_locale
    I18n.with_locale(:es) do
      render_rail do |c|
        c.with_step(title: "Captura", state: :success)
      end
    end

    assert_selector(%(ol.workflow-steps-list[aria-label="#{I18n.t('bali_view.workflow_steps.rail_label', locale: :es)}"]))
  end

  # `progress: false` is what the four horizontal call sites in the fleet
  # write today; migrating one to the rail must not turn it into an error.
  def test_the_rail_accepts_an_explicit_progress_false
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :rail, progress: false)) do |c|
      c.with_step(title: "A", state: :success)
    end

    assert_selector("div.workflow-steps.workflow-steps-rail")
    assert_no_selector(".workflow-steps-progress")
  end

  def test_the_orientation_error_names_all_three_shapes
    error = assert_raises(ArgumentError) do
      render_inline(Bali::WorkflowSteps::Component.new(orientation: :sideways))
    end

    assert_includes(error.message, ":vertical")
    assert_includes(error.message, ":horizontal")
    assert_includes(error.message, ":rail")
  end

  private

  def render_rail(&block)
    render_inline(Bali::WorkflowSteps::Component.new(orientation: :rail), &block)
  end

  def circle_texts
    page.all(".workflow-step-circle", visible: :all).map { |node| node.text.strip }
  end
end

# The rail shares the vertical shape's numbered circle and the quick flow's
# N/M header, so three rules moved out of their per-shape blocks and into the
# root `.workflow-steps` block rather than being duplicated. That move is what
# the whole "the default shape is untouched" claim rests on, and the repo has
# no rendering tests for CSS: nothing else in the suite notices if someone
# files one of them back under a shape, or adds a second declaration that
# shadows it.
#
# This reads the source, so it proves placement, not paint. What it cannot see
# — cascade, layer, a host stylesheet — was measured in the browser against
# the v3.4.0 server instead, and that measurement is in the PR, not here.
class BaliWorkflowStepsStylesheetTest < ActiveSupport::TestCase
  STYLESHEET = Bali::Engine.root.join("app/components/bali/workflow_steps/index.css")

  # Declared once, in the root block: the two shapes that draw a numbered
  # circle (vertical, rail) and the two that carry the header (horizontal,
  # rail) would otherwise each need a copy.
  SHARED_RULES = %w[
    .workflow-step-circle
    .workflow-steps-progress
    .workflow-steps-count
  ].freeze

  def test_the_shared_rules_live_in_the_root_block_exactly_once
    SHARED_RULES.each do |selector|
      assert_equal [ ".workflow-steps" ], blocks_declaring(selector),
        "#{selector} debe estar declarado una sola vez y dentro del bloque raíz `.workflow-steps`"
    end
  end

  # Each shape sizes the marker itself, in its own top-level block.
  # `.workflow-steps-horizontal .workflow-step-marker` boxes it into 1.5rem for
  # its dot, which would crush the rail's 2rem circle: the rail having its own
  # root class rather than being "horizontal plus a modifier" is the only thing
  # keeping that rule away from it. The order is the other half — the rail
  # block is written after the horizontal one on purpose, since same
  # specificity in the same layer is settled by source order.
  def test_each_shape_declares_its_own_marker_rule_in_source_order
    assert_equal %w[.workflow-steps-vertical .workflow-steps-horizontal .workflow-steps-rail],
                 blocks_declaring(".workflow-step-marker")
  end

  private

  # The top-level blocks that declare `selector` as a nested rule. The sheet is
  # one nested rule per shape block, two spaces of indent, which is what this
  # reads; a reformat that breaks the shape shows up as an empty result, not a
  # false pass.
  def blocks_declaring(selector)
    current = nil

    File.readlines(STYLESHEET).filter_map do |line|
      if (top = line[/\A(\.[\w-]+)\s*\{/, 1])
        current = top
        nil
      elsif line[/\A {2}(\.[\w-]+)\s*\{/, 1] == selector
        current
      end
    end
  end
end
