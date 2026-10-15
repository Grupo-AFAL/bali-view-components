# frozen_string_literal: true

require "test_helper"

class BaliBpmnEditorComponentTest < ComponentTestCase
  def payload
    {
      version: 3,
      lanes: [ { id: "l1", name: "Accounts", order: 1, size: 180 } ],
      nodes: [ { id: "n1", type: "task", lane_id: "l1", name: "Validate invoice", x: 80, y: 40 } ],
      edges: []
    }
  end

  def component(**overrides)
    Bali::BpmnEditor::Component.new(data: payload, **overrides)
  end

  def island
    page.find(".bali-bpmn-editor")
  end

  def test_the_component_element_is_the_islands_mount_point
    render_inline(component(id: "flow_bpmn"))

    assert_equal "bpmn-editor", island["data-controller"]
    assert_equal "flow_bpmn", island["id"]
    assert_equal "Validate invoice", JSON.parse(island["data-bpmn-editor-data-value"]).dig("nodes", 0, "name")
  end

  def test_the_placeholder_and_noscript_render_inside_the_mount
    render_inline(component)

    assert_selector("[data-controller='bpmn-editor'] .bali-bpmn-editor-mount .bali-bpmn-editor-skeleton[aria-busy='true']")
    assert_includes page.find("noscript", visible: :all).native.to_html, "needs JavaScript"
    assert_no_text("Validate invoice")
  end

  def test_the_noscript_notice_is_translated
    I18n.with_locale(:es) { render_inline(component) }

    assert_includes page.find("noscript", visible: :all).native.to_html, "necesita JavaScript"
  end

  def test_without_a_save_url_it_is_a_viewer_even_when_editable
    render_inline(component(editable: true))

    assert_equal "false", island["data-bpmn-editor-editable-value"]
  end

  def test_editable_with_a_save_url
    render_inline(component(editable: true, urls: { save: "/flows/1/diagram" }))

    assert_equal "true", island["data-bpmn-editor-editable-value"]
    assert_equal({ "save" => "/flows/1/diagram" }, JSON.parse(island["data-bpmn-editor-urls-value"]))
  end

  def test_auto_arrange_is_on_unless_the_host_turns_it_off
    render_inline(component)
    assert_equal "true", island["data-bpmn-editor-auto-arrange-value"]

    render_inline(component(auto_arrange: false))
    assert_equal "false", island["data-bpmn-editor-auto-arrange-value"]
  end

  def test_an_unknown_url_key_raises
    error = assert_raises(ArgumentError) { component(urls: { safe: "/typo" }) }
    assert_includes error.message, ":safe"
  end

  def test_the_palette_defaults_to_the_descriptive_preset
    render_inline(component)

    keys = JSON.parse(island["data-bpmn-editor-palette-value"]).fetch("items").pluck("key")
    assert_equal Bali::BpmnEditor::Palette::DESCRIPTIVE.sort, keys.sort
  end

  def test_rules_are_normalized_and_validated
    render_inline(component(rules: { disabled: %i[R17], severities: { R16: :warning },
                                     options: { min_lanes: 3 } }))

    rules = JSON.parse(island["data-bpmn-editor-rules-value"])
    assert_equal [ "R17" ], rules["disabled"]
    assert_equal({ "R16" => "warning" }, rules["severities"])
    assert_equal({ "min_lanes" => 3 }, rules["options"])

    assert_raises(ArgumentError) { component(rules: { severities: { R16: :fatal } }) }
    assert_raises(ArgumentError) { component(rules: { options: { max_lanes: 3 } }) }
    assert_raises(ArgumentError) { component(rules: { disable: [ "R1" ] }) }
  end

  def test_field_schemas_are_validated
    render_inline(component(node_fields: { task: [ { key: :duration, label: "Duration", type: :number } ] },
                            lane_fields: [ { key: "notes", label: "Notes", type: "textarea" } ]))

    assert_equal "number", JSON.parse(island["data-bpmn-editor-node-fields-value"]).dig("task", 0, "type")
    assert_equal "textarea", JSON.parse(island["data-bpmn-editor-lane-fields-value"]).dig(0, "type")

    assert_raises(ArgumentError) { component(lane_fields: [ { key: "x", label: "X", type: "date" } ]) }
    assert_raises(ArgumentError) { component(node_fields: { task: [ { label: "No key" } ] }) }
  end

  def test_the_legend_takes_additions_and_removals
    render_inline(component(legend: { remove: %i[external_task], add: [ { key: "rework", label: "Rework", swatch: "issue" } ] }))

    keys = JSON.parse(island["data-bpmn-editor-legend-value"]).pluck("key")
    assert_equal %w[task sub_process external_lane issue rework], keys
  end

  def test_the_legend_can_be_hidden_and_rejects_unknown_swatches
    render_inline(component(legend: false))

    assert_equal [], JSON.parse(island["data-bpmn-editor-legend-value"])
    assert_raises(ArgumentError) { component(legend: [ { key: "x", label: "X", swatch: "rainbow" } ]) }
    assert_raises(ArgumentError) { component(legend: [ { key: "x", label: "X", swatch: "color" } ]) }
  end

  def test_it_serves_the_island_strings_in_the_current_locale
    I18n.with_locale(:es) { render_inline(component) }

    assert_equal "Elementos", JSON.parse(island["data-bpmn-editor-i18n-value"]).fetch("palette_title")
  end

  def test_extra_options_land_on_the_wrapper_but_data_does_not
    render_inline(component(class: "h-full", aria: { label: "Flow" }))

    assert_includes island[:class], "h-full"
    assert_equal "Flow", island["aria-label"]
  end
end

class BaliBpmnEditorComponentOutputsTest < ComponentTestCase
  def payload = { lanes: [], nodes: [], edges: [] }

  def test_name_watermark_tags_and_comparison_reach_the_island
    render_inline(Bali::BpmnEditor::Component.new(
      data: payload, name: "Supplier payments", watermark: "Draft",
      annotation_tags: [ { key: :keep, label: "Keep", color: "#16a34a" } ],
      compare_with: { document: payload.merge(nodes: [ { id: "n1", type: "task" } ]), label: "v1.0" }
    ))

    island = page.find(".bali-bpmn-editor")
    assert_equal "Supplier payments", island["data-bpmn-editor-name-value"]
    assert_equal "Draft", island["data-bpmn-editor-watermark-value"]
    assert_equal "keep", JSON.parse(island["data-bpmn-editor-annotation-tags-value"]).dig(0, "key")
    compare = JSON.parse(island["data-bpmn-editor-compare-value"])
    assert_equal [ "v1.0", "n1" ], [ compare["label"], compare.dig("document", "nodes", 0, "id") ]
  end

  def test_a_comparison_document_is_validated_like_data
    assert_raises(Bali::BpmnEditor::Data::InvalidError) do
      Bali::BpmnEditor::Component.new(data: payload, compare_with: { document: { orientation: "diagonal" } })
    end
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, annotation_tags: [ { key: "x" } ]) }
  end
end
