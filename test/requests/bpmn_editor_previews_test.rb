# frozen_string_literal: true

require "test_helper"

class BpmnEditorPreviewsTest < ActionDispatch::IntegrationTest
  %w[default vertical large empty].each do |preview|
    define_method("test_the_#{preview}_preview_renders_the_island_and_its_loader_metas") do
      get "/lookbook/preview/bali/bpmn_editor/#{preview}"

      assert_response :ok
      assert_select "[data-controller='bpmn-editor'][data-bpmn-editor-data-value]", { minimum: 1 }
      assert_select "meta[name='bali-bpmn-editor-js']", { minimum: 1 }
    end
  end

  def test_the_large_preview_carries_more_than_fifty_activities
    get "/lookbook/preview/bali/bpmn_editor/large"

    document = JSON.parse(css_select("[data-bpmn-editor-data-value]").first["data-bpmn-editor-data-value"])
    assert_operator document.fetch("nodes").count { |n| n["type"] == "task" }, :>, 50
  end
end
