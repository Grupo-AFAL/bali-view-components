# frozen_string_literal: true

require "test_helper"

# The dummy's notes endpoint for a read-only diagram (`annotatable:`,
# urls[:annotations], docs/api/bpmn-editor.md): only the notes change, under
# the same version check as the diagram's save.
class AdminBpmnAnnotationsTest < ActionDispatch::IntegrationTest
  setup do
    @flow = ProcessFlow.create!(name: "Annotated payments",
                                document: BpmnSampleFlows.invoice.except(:version, :status_label))
  end

  def annotations_path = "/admin/process_flows/#{@flow.id}/annotations"
  def note(text) = { id: "a1", target_id: "t1", number: 1, text: text, tag: "question" }

  def test_put_with_the_current_version_saves_the_notes_and_answers_the_document
    nodes = @flow.document["nodes"]

    put annotations_path, params: { annotations: [ note("Who signs?") ], version: 1 }, as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 2, body["version"]
    assert_equal [ "Who signs?" ], body["annotations"].pluck("text")
    assert_equal nodes.size, body["nodes"].size, "the complete document comes back"
    @flow.reload
    assert_equal "Who signs?", @flow.document["annotations"].first["text"]
    assert_equal nodes, @flow.document["nodes"], "nothing but the notes changed"
  end

  def test_an_empty_list_deletes_every_note
    @flow.update!(document: @flow.document.merge("annotations" => [ note("Old") ]))

    put annotations_path, params: { annotations: [], version: 1 }, as: :json

    assert_response :ok
    assert_empty @flow.reload.document["annotations"]
  end

  def test_a_stale_version_is_a_conflict_and_saves_nothing
    put annotations_path, params: { annotations: [ note("Late") ], version: 7 }, as: :json

    assert_response :conflict
    assert_nil @flow.reload.document["annotations"]
    assert_equal 1, @flow.version
  end

  def test_a_note_without_an_id_is_unprocessable
    put annotations_path, params: { annotations: [ note("No id").except(:id) ], version: 1 }, as: :json

    assert_response :unprocessable_entity
    assert_match(/annotation requires an id/, response.parsed_body["errors"].first)
    assert_equal 1, @flow.reload.version
  end
end
