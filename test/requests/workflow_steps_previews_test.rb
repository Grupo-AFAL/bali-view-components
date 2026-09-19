# frozen_string_literal: true

require "test_helper"

# A `preview.rb` that names a sibling constant unqualified resolves under
# `bin/rails runner` and 500s over the request path after a `reload!`
# (`Module.nesting`; see `.claude/CLAUDE.md`). Component tests render classes,
# not previews, so only a request test catches it.
class WorkflowStepsPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[default horizontal rail progress decision_pattern provisional_route].freeze

  def test_every_workflow_steps_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/workflow_steps/#{name}"
      assert_response :ok, "/lookbook/preview/bali/workflow_steps/#{name} did not render"
      assert_select ".workflow-steps", { minimum: 1 },
        "/lookbook/preview/bali/workflow_steps/#{name} rendered without the component"
    end
  end

  # All four shapes come out of the same root class, so a preview that renders
  # is no proof it rendered the shape it documents.
  def test_each_preview_renders_the_shape_it_documents
    { "default" => "ol.workflow-steps.workflow-steps-vertical",
      "horizontal" => "div.workflow-steps.workflow-steps-horizontal",
      "rail" => "div.workflow-steps.workflow-steps-rail",
      "progress" => "div.workflow-steps.workflow-steps-progress-rail" }.each do |name, selector|
      get "/lookbook/preview/bali/workflow_steps/#{name}"
      assert_response :ok
      assert_select selector, { minimum: 1 }, "#{name} did not render #{selector}"
    end
  end

  # The rail's `<ol>` is its own scroll container and holds nothing focusable,
  # so without `tabindex` the overflowed steps are unreachable by keyboard.
  def test_the_rail_preview_keeps_its_scroll_container_reachable
    get "/lookbook/preview/bali/workflow_steps/rail"
    assert_response :ok
    assert_select "ol.workflow-steps-list[tabindex='0'][aria-label]", { minimum: 1 }
  end

  # The shape and the N/M bar share the word `progress`, and the preview takes
  # both: `?progress=true` must reach the bar, not the orientation.
  def test_the_progress_preview_toggles_the_bar_without_losing_the_shape
    get "/lookbook/preview/bali/workflow_steps/progress"
    assert_response :ok
    assert_select ".workflow-steps-progress-rail .workflow-steps-progress", false,
      "the progress shape drew the N/M bar unasked"

    get "/lookbook/preview/bali/workflow_steps/progress", params: { progress: true }
    assert_response :ok
    assert_select ".workflow-steps-progress-rail .workflow-steps-progress", { minimum: 1 }
  end

  # The nine circles of the funnel: five connectors primary, then three grey.
  # The preview is where the derived rule is on show, so it is where a change
  # to it has to be seen.
  def test_the_progress_preview_stops_its_coloured_run_at_the_current_step
    get "/lookbook/preview/bali/workflow_steps/progress"
    assert_response :ok

    assert_select ".workflow-steps-progress-rail" do |shapes|
      connectors = shapes.first.css(".workflow-step-connector")
      colors = connectors.map { |node| node["class"][/bg-\S+/] }
      assert_equal (%w[bg-primary] * 5) + (%w[bg-base-300] * 3), colors
    end
  end

  def test_the_rail_preview_toggles_the_progress_bar
    get "/lookbook/preview/bali/workflow_steps/rail"
    assert_response :ok
    assert_select ".workflow-steps-rail .workflow-steps-progress", false,
      "the rail drew the N/M bar unasked"

    get "/lookbook/preview/bali/workflow_steps/rail", params: { progress: true }
    assert_response :ok
    assert_select ".workflow-steps-rail .workflow-steps-progress", { minimum: 1 }
  end
end
