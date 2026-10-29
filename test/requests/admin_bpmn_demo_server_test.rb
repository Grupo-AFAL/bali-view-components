# frozen_string_literal: true

require "test_helper"

# The playground's demonstration switches on the dummy's endpoints
# (Admin::ProcessFlows::DemoServer), the import drawer and the host-event
# buttons. Dummy-only: a host writes none of this.
class AdminBpmnDemoServerTest < ActionDispatch::IntegrationTest
  setup do
    @flow = ProcessFlow.reset!("Sample invoice horizontal (en)", BpmnSampleFlows.invoice(locale: :en))
  end

  def diagram(**query) = "/admin/process_flows/#{@flow.id}/diagram?#{query.to_query}"
  def finalization(**query) = "/admin/process_flows/#{@flow.id}/finalization?#{query.to_query}"
  def body_for(version = @flow.version) = { diagram: @flow.to_diagram.except(:issues, :status_label), version: version }

  def test_conflict_answers_409_without_saving
    put diagram(server: "conflict"), params: body_for, as: :json

    assert_response :conflict
    assert_equal 1, @flow.reload.version
  end

  def test_error_answers_422_with_messages
    put diagram(server: "error", locale: "en"), params: body_for, as: :json

    assert_response :unprocessable_entity
    assert_match(/could not be saved/, response.parsed_body["errors"].first)
  end

  def test_reject_save_answers_422_with_messages_and_issues_without_saving
    put diagram(server: "reject_save", locale: "en"), params: body_for, as: :json

    assert_response :unprocessable_entity
    assert_match(/could not be saved/, response.parsed_body["errors"].first)
    assert_equal "APP-DEMO-2", response.parsed_body["issues"].find { |issue| issue["element_id"] }["rule"]
    assert_equal 1, @flow.reload.version
  end

  def test_issues_come_back_with_the_document
    get diagram(server: "issues", locale: "en"), as: :json

    assert_includes response.parsed_body["issues"].pluck("rule"), "APP-DEMO-1"
    get diagram, as: :json
    assert_not_includes response.parsed_body["issues"].pluck("rule"), "APP-DEMO-1"
  end

  def test_reject_finalize_answers_422_with_issues_and_the_new_version
    post finalization(server: "reject_finalize", locale: "en"), params: body_for, as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["issues"].pluck("rule"), "APP-DEMO-2"
    assert_equal 2, response.parsed_body["version"]
    assert_nil @flow.reload.finalized_at
  end

  def test_the_import_drawer_answers_the_reload_for_the_editor_it_names
    get "/admin/process_flows/#{@flow.id}/import/new", params: { editor_id: "flow_bpmn", locale: "en" }
    assert_response :ok
    assert_select "input[type=file]"
    assert_select "input[name=editor_id][value=flow_bpmn]"

    post "/admin/process_flows/#{@flow.id}/import", params: { editor_id: "flow_bpmn", locale: "en" }, as: :turbo_stream
    assert_select "turbo-stream[action=bali_bpmn_event][event=reload][target=flow_bpmn]"
    assert_equal 2, @flow.reload.version
  end

  def test_the_host_event_buttons_answer_through_the_helpers
    post "/admin/process_flows/#{@flow.id}/host_event", params: { event: "reload", editor_id: "host_first_bpmn" }, as: :turbo_stream
    assert_select "turbo-stream[event=reload][target=host_first_bpmn]"

    post "/admin/process_flows/#{@flow.id}/host_event",
         params: { event: "reference_created", editor_id: "host_first_bpmn", client_node_id: "sp" }, as: :turbo_stream
    tag = css_select("turbo-stream[event=reference-created]").first
    assert_equal "sp", JSON.parse(tag["detail"])["client_node_id"]
  end
end
