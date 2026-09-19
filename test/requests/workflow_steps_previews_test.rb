# frozen_string_literal: true

require "test_helper"

# A `preview.rb` that names a sibling constant unqualified resolves under
# `bin/rails runner` and 500s over the request path after a `reload!`
# (`Module.nesting`; see `.claude/CLAUDE.md`). Component tests render classes,
# not previews, so only a request test catches it.
class WorkflowStepsPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[default horizontal rail decision_pattern provisional_route].freeze

  def test_every_workflow_steps_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/workflow_steps/#{name}"
      assert_response :ok, "/lookbook/preview/bali/workflow_steps/#{name} did not render"
      assert_select ".workflow-steps", { minimum: 1 },
        "/lookbook/preview/bali/workflow_steps/#{name} rendered without the component"
    end
  end

  # All three shapes come out of the same root class, so a preview that renders
  # is no proof it rendered the shape it documents.
  def test_each_preview_renders_the_shape_it_documents
    { "default" => "ol.workflow-steps.workflow-steps-vertical",
      "horizontal" => "div.workflow-steps.workflow-steps-horizontal",
      "rail" => "div.workflow-steps.workflow-steps-rail" }.each do |name, selector|
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
