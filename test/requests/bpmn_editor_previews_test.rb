# frozen_string_literal: true

require "test_helper"

class BpmnEditorPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEW = "/lookbook/preview/bali/bpmn_editor"

  def island
    css_select("[data-controller='bpmn-editor']").first
  end

  def island_value(name)
    JSON.parse(island["data-bpmn-editor-#{name}-value"])
  end

  %w[default playground host_integration configured review catalog pair].each do |preview|
    define_method("test_the_#{preview}_preview_renders_the_island_and_its_loader_metas") do
      get "#{PREVIEW}/#{preview}"

      assert_response :ok
      assert_select "[data-controller='bpmn-editor'][data-bpmn-editor-data-value]", { minimum: 1 }
      assert_select "meta[name='bali-bpmn-editor-js']", { minimum: 1 }
    end
  end

  # Every value of every select the playground offers renders (no 500).
  {
    sample: %w[invoice empty rework parallel partners large],
    orientation: %w[horizontal vertical],
    palette: %w[descriptive analytic full],
    layout: %w[compact straight],
    page: Bali::BpmnEditor::Preview::PAGES.keys,
    rule_severity: Bali::BpmnEditor::Preview::RULE_PRESETS.keys,
    server: Admin::ProcessFlows::DemoServer::MODES,
    theme: %w[light dark],
    locale: %w[es en]
  }.each do |param, values|
    define_method("test_the_playground_renders_every_#{param}") do
      values.each do |value|
        get "#{PREVIEW}/playground", params: { param => value }
        assert_response :ok, "#{param}=#{value}"
        assert_select "[data-controller='bpmn-editor']", { count: 1 }, "#{param}=#{value}"
      end
    end
  end

  def test_the_playground_starts_each_sample_from_its_own_clean_record
    get "#{PREVIEW}/playground", params: { sample: "rework", locale: "en" }
    rework = ProcessFlow.find_by!(name: "Sample rework horizontal (en)")
    rework.update!(document: { lanes: [ { id: "x", name: "Leftover" } ] }, version: 14)

    get "#{PREVIEW}/playground", params: { sample: "invoice", locale: "en" }
    assert_equal 14, rework.reload.version, "another sample's record is left alone"

    get "#{PREVIEW}/playground", params: { sample: "rework", locale: "en", fresh: false }
    assert_equal 14, rework.reload.version, "fresh off keeps the edits"

    get "#{PREVIEW}/playground", params: { sample: "rework", locale: "en" }
    assert_equal 1, rework.reload.version
    assert_equal "Requester", rework.document["lanes"].first["name"]
    assert_equal "true", island["data-bpmn-editor-editable-value"]
    assert_equal "/admin/process_flows/#{rework.id}/diagram?locale=en", island_value("urls")["save"]
  end

  def test_the_playground_hands_its_options_to_the_component
    get "#{PREVIEW}/playground", params: { layout: "straight", page: "a4_portrait", lock_orientation: true,
                                           external_lanes: false, autosave: false, rule_severity: "strict",
                                           server: "conflict", theme: "dark", name: "Supplier payments" }

    assert_equal "straight", island["data-bpmn-editor-layout-value"]
    assert_equal({ "width" => 8.27, "height" => 11.69, "orientation" => "portrait" }, island_value("page"))
    assert_equal "true", island["data-bpmn-editor-lock-orientation-value"]
    assert_equal "false", island["data-bpmn-editor-external-lanes-value"]
    assert_equal "false", island["data-bpmn-editor-autosave-value"]
    assert_includes island_value("rules")["enabled"], "R17"
    assert_match(/server=conflict/, island_value("urls")["save"])
    assert_select "[data-theme='dark'] [data-controller='bpmn-editor']"
    assert_equal "Supplier payments", island["data-bpmn-editor-name-value"]
  end

  # The dummy's own data (the procedures to place, the server's issues) follows
  # the preview's locale too.
  def test_the_dummy_data_follows_the_locale
    get "#{PREVIEW}/playground", params: { locale: "en" }
    labels = island_value("data")["stencil"].map { |item| item.dig("reference", "label") }
    assert_equal [ "Bank reconciliation", "Payment scheduling" ], labels
    assert_match(/locale=en/, island_value("urls")["references"])

    get "#{PREVIEW}/playground", params: { locale: "en", sample: "rework" }
    assert_equal "The flow has no user task.", island_value("data")["issues"].first["message"]

    get "#{PREVIEW}/playground", params: { locale: "es" }
    assert_equal [ "Conciliación bancaria", "Programación de pagos" ],
                 island_value("data")["stencil"].map { |item| item.dig("reference", "label") }
  end

  def test_the_optional_rule_package_loads_only_with_its_toggle
    get "#{PREVIEW}/playground"
    assert_select "meta[name='bali-bpmn-editor-js'][content*='bpmn-editor-island-with-rules']", count: 0

    get "#{PREVIEW}/playground", params: { optional_rules: true }
    assert_select "meta[name='bali-bpmn-editor-js'][content*='bpmn-editor-island-with-rules']", count: 1
  end

  def test_the_host_integration_preview_has_the_console_the_buttons_and_the_locked_editor
    get "#{PREVIEW}/host_integration"

    assert_select "[data-controller='bpmn-host-console'] [data-testid='bpmn-host-console']"
    assert_select "[data-testid='bpmn-host-reload']"
    assert_select "[data-testid='bpmn-host-reference']"
    assert_select "[data-testid='bpmn-host-locked']"
    locked = css_select("#host_locked_bpmn").first
    assert_equal "false", locked["data-bpmn-editor-editable-value"]
    assert_select "[role='tabpanel'] [data-controller='bpmn-editor']", count: 2
  end

  def test_the_review_preview_saves_notes_only_when_editable
    get "#{PREVIEW}/review"
    assert_equal({}, island_value("urls"))

    get "#{PREVIEW}/review", params: { editable: true }
    assert_equal "true", island["data-bpmn-editor-editable-value"]
    assert_predicate island_value("urls")["save"], :present?
    assert_equal 2, island_value("data")["annotations"].size
  end

  def test_the_catalog_preview_draws_every_element_the_palette_creates_twice
    get "#{PREVIEW}/catalog"

    ids = island_value("data")["nodes"].pluck("id")
    tools = %w[lane sequence_flow message_flow association]
    (Bali::BpmnEditor::Palette::KEYS - tools).each do |key|
      assert_includes ids, key
      assert_includes ids, "icon-#{key}"
    end
  end

  def test_the_configured_preview_hands_over_palette_notes_and_legend_on_its_own_record
    get "#{PREVIEW}/configured"

    assert ProcessFlow.exists?(name: "Configured (es)")
    palette = island_value("palette")
    assert_equal "disabled", palette["items"].find { |i| i["key"] == "complex_gateway" }["state"]
    assert_predicate palette["items"].find { |i| i["key"] == "signal_event" }["note"], :present?
    assert_includes island_value("legend").pluck("key"), "rework"
  end

  def test_the_large_sample_carries_more_than_fifty_activities
    get "#{PREVIEW}/playground", params: { sample: "large" }

    assert_operator island_value("data").fetch("nodes").count { |n| n["type"] == "task" }, :>, 50
  end
end
