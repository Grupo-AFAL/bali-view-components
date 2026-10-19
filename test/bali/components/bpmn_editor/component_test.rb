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

  def test_without_an_id_each_editor_gets_its_own
    ids = 2.times.map do
      render_inline(component)
      island["id"]
    end

    assert_match(/\Abpmn-editor-\h{8}\z/, ids.first)
    assert_not_equal ids.first, ids.last
  end

  # The orientation has one source, the document; the host only locks it.
  def test_the_host_can_lock_the_documents_orientation
    render_inline(component(lock_orientation: true))
    assert_equal "true", island["data-bpmn-editor-lock-orientation-value"]

    render_inline(component)
    assert_equal "false", island["data-bpmn-editor-lock-orientation-value"]
  end

  def test_the_pending_issues_panel_can_open_on_load
    render_inline(component)
    assert_equal "false", island["data-bpmn-editor-open-issues-value"]

    render_inline(component(open_issues: true))
    assert_equal "true", island["data-bpmn-editor-open-issues-value"]
  end

  def test_external_lanes_can_be_turned_off_and_take_their_legend_entries_along
    render_inline(component)
    assert_equal "true", island["data-bpmn-editor-external-lanes-value"]
    assert_includes JSON.parse(island["data-bpmn-editor-legend-value"]).pluck("key"), "external_lane"

    render_inline(component(external_lanes: false))
    assert_equal "false", island["data-bpmn-editor-external-lanes-value"]
    assert_equal %w[task sub_process issue], JSON.parse(island["data-bpmn-editor-legend-value"]).pluck("key")
  end

  def test_the_layout_is_compact_on_a_landscape_letter_page_unless_the_host_says_otherwise
    render_inline(component)
    assert_equal "compact", island["data-bpmn-editor-layout-value"]
    assert_equal({ "width" => 8.5, "height" => 11, "orientation" => "landscape" }, JSON.parse(island["data-bpmn-editor-page-value"]))

    render_inline(component(layout: :straight, page: { width: 8.27, height: 11.69, orientation: :portrait }))
    assert_equal "straight", island["data-bpmn-editor-layout-value"]
    assert_equal({ "width" => 8.27, "height" => 11.69, "orientation" => "portrait" }, JSON.parse(island["data-bpmn-editor-page-value"]))
  end

  def test_an_unknown_layout_or_a_malformed_page_raises
    assert_includes assert_raises(ArgumentError) { component(layout: :tidy) }.message, ":tidy"
    assert_includes assert_raises(ArgumentError) { component(page: { width: 0 }) }.message, "page width"
    assert_includes assert_raises(ArgumentError) { component(page: { orientation: :sideways }) }.message, "sideways"
    assert_includes assert_raises(ArgumentError) { component(page: { margin: 1 }) }.message, ":margin"
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

  # The options count lanes and activities; the island compares them as numbers.
  def test_rule_options_are_positive_integers
    [ 0, -1, "3", 2.5, nil ].each do |value|
      error = assert_raises(ArgumentError) { component(rules: { options: { min_lanes: value } }) }
      assert_includes error.message, "min_lanes must be a positive integer"
    end
  end

  def test_field_schemas_are_validated
    render_inline(component(fields: { nodes: { task: [ { key: :duration, label: "Duration", type: :number } ] },
                                      lanes: [ { key: "notes", label: "Notes", type: "textarea" } ] }))

    fields = JSON.parse(island["data-bpmn-editor-fields-value"])
    assert_equal "number", fields.dig("nodes", "task", 0, "type")
    assert_equal "textarea", fields.dig("lanes", 0, "type")

    assert_raises(ArgumentError) { component(fields: { lanes: [ { key: "x", label: "X", type: "date" } ] }) }
    assert_raises(ArgumentError) { component(fields: { nodes: { task: [ { label: "No key" } ] } }) }
    assert_includes assert_raises(ArgumentError) { component(fields: { edges: [] }) }.message, ":edges"
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

  # Lookbook builds the component inside `I18n.with_locale` and renders it
  # after the block returns; the previews pass no `i18n:`.
  def test_the_strings_follow_the_locale_the_component_was_built_in
    built = I18n.with_locale(:es) { component }
    render_inline(built)

    assert_equal "Elementos", JSON.parse(island["data-bpmn-editor-i18n-value"]).fetch("palette_title")
  end

  # `data:` is the document, so HTML data attributes cannot ride along.
  def test_extra_options_land_on_the_wrapper
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
      review: { tags: [ { key: :keep, label: "Keep", color: "#16a34a" } ],
                compare_with: { document: payload.merge(nodes: [ { id: "n1", type: "task" } ]), label: "v1.0" } }
    ))

    island = page.find(".bali-bpmn-editor")
    assert_equal "Supplier payments", island["data-bpmn-editor-name-value"]
    assert_equal "Draft", island["data-bpmn-editor-watermark-value"]
    review = JSON.parse(island["data-bpmn-editor-review-value"])
    assert_equal "keep", review.dig("tags", 0, "key")
    assert_equal [ "v1.0", "n1" ], [ review.dig("compare_with", 0, "label"), review.dig("compare_with", 0, "document", "nodes", 0, "id") ]
  end

  def test_a_comparison_document_is_validated_like_data
    assert_raises(Bali::BpmnEditor::Data::InvalidError) do
      Bali::BpmnEditor::Component.new(data: payload, review: { compare_with: { document: { orientation: "diagonal" } } })
    end
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, review: { tags: [ { key: "x" } ] }) }
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, review: { notes: [] }) }
  end
end

# BPMN-50: what an app embedding several diagrams needs — selection it
# controls, a minimal chrome, notes on a read-only diagram, no rules, and a
# comparison of two different flows. All optional: without them the island
# receives exactly what it did before.
class BaliBpmnEditorComponentEmbeddingTest < ComponentTestCase
  def payload = { lanes: [], nodes: [ { id: "n1", type: "sub_process", name: "Billing" } ], edges: [] }
  def island = page.find(".bali-bpmn-editor")

  def render_with(**options)
    render_inline(Bali::BpmnEditor::Component.new(data: payload, **options))
  end

  NEW_VALUES = %w[selected-id chrome min-zoom annotatable validate badges badge-toggle badge-toggle-label wheel-zoom].freeze

  def test_without_the_new_options_none_of_their_values_is_rendered
    render_with

    NEW_VALUES.each { |name| assert_nil island["data-bpmn-editor-#{name}-value"], name }
    refute_includes island[:class], "h-full"
  end

  def test_the_app_selects_a_node_on_load
    render_with(selected_id: :n1)

    assert_equal "n1", island["data-bpmn-editor-selected-id-value"]
  end

  def test_the_minimal_chrome_fills_its_container
    render_with(chrome: :minimal, min_zoom: 0.15)

    assert_equal "minimal", island["data-bpmn-editor-chrome-value"]
    assert_equal "0.15", island["data-bpmn-editor-min-zoom-value"]
    assert_includes island[:class], "h-full"
    assert_selector(".bali-bpmn-editor-mount.h-full .bali-bpmn-editor-skeleton.h-full")
  end

  def test_chrome_and_min_zoom_are_validated
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, chrome: :compact) }
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, min_zoom: 0) }
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, min_zoom: "0.2") }
    error = assert_raises(ArgumentError) do
      Bali::BpmnEditor::Component.new(data: payload, chrome: :minimal, editable: true, urls: { save: "/d" })
    end
    assert_match(/read-only/, error.message)
  end

  def test_notes_on_a_read_only_diagram_need_their_endpoint
    render_with(annotatable: true, urls: { annotations: "/flows/1/annotations", diagram: "/flows/1/diagram" })

    assert_equal "true", island["data-bpmn-editor-annotatable-value"]
    assert_equal "false", island["data-bpmn-editor-editable-value"]
    assert_equal "/flows/1/annotations", JSON.parse(island["data-bpmn-editor-urls-value"])["annotations"]
  end

  def test_annotatable_has_no_effect_without_the_endpoint_or_while_editing
    render_with(annotatable: true)
    assert_nil island["data-bpmn-editor-annotatable-value"]

    render_with(annotatable: true, editable: true, urls: { save: "/d", annotations: "/a" })
    assert_nil island["data-bpmn-editor-annotatable-value"]
  end

  def test_badges_and_their_switch_reach_the_island_only_when_off
    render_with(badges: false, badge_toggle: false)

    assert_equal "false", island["data-bpmn-editor-badges-value"]
    assert_equal "false", island["data-bpmn-editor-badge-toggle-value"]

    render_with(badges: true, badge_toggle: true)
    assert_nil island["data-bpmn-editor-badges-value"]
    assert_nil island["data-bpmn-editor-badge-toggle-value"]
  end

  def test_badges_is_a_boolean
    [ nil, "false", 0, :off ].each do |value|
      error = assert_raises(ArgumentError, value.inspect) { Bali::BpmnEditor::Component.new(data: payload, badges: value) }
      assert_match(/badges must be true or false/, error.message)
    end
  end

  def test_badge_toggle_takes_the_apps_label
    render_with(badge_toggle: "  Mostrar estatus ")

    assert_equal "Mostrar estatus", island["data-bpmn-editor-badge-toggle-label-value"]
    assert_nil island["data-bpmn-editor-badge-toggle-value"]
  end

  def test_badge_toggle_is_true_false_or_a_short_label
    max = Bali::BpmnEditor::Component::BADGE_TOGGLE_MAX
    render_with(badge_toggle: "x" * max)
    assert_equal "x" * max, island["data-bpmn-editor-badge-toggle-label-value"]

    [ nil, 0, :off, "", "   ", "x" * (max + 1) ].each do |value|
      error = assert_raises(ArgumentError, value.inspect) { Bali::BpmnEditor::Component.new(data: payload, badge_toggle: value) }
      assert_match(/badge_toggle must be true, false or a label of at most #{max} characters/, error.message)
    end
  end

  def test_wheel_zoom_crosses_only_when_not_auto
    render_with(wheel_zoom: :auto)
    assert_nil island["data-bpmn-editor-wheel-zoom-value"]
    render_with(wheel_zoom: "auto")
    assert_nil island["data-bpmn-editor-wheel-zoom-value"]
    render_with(wheel_zoom: true)
    assert_equal "true", island["data-bpmn-editor-wheel-zoom-value"]
    render_with(wheel_zoom: false)
    assert_equal "false", island["data-bpmn-editor-wheel-zoom-value"]
  end

  def test_wheel_zoom_rejects_anything_else
    [ nil, "true", "false", :on, 1 ].each do |value|
      error = assert_raises(ArgumentError, value.inspect) { Bali::BpmnEditor::Component.new(data: payload, wheel_zoom: value) }
      assert_match(/wheel_zoom must be :auto, true or false/, error.message)
    end
  end

  def test_rules_false_reaches_the_island_as_its_own_flag
    render_with(rules: false)

    assert_equal "false", island["data-bpmn-editor-validate-value"]
    assert_equal "{}", island["data-bpmn-editor-rules-value"]
  end

  def test_the_structure_profile_travels_as_a_profile
    render_with(rules: :structure)

    assert_equal({ "profile" => "structure" }, JSON.parse(island["data-bpmn-editor-rules-value"]))
    assert_nil island["data-bpmn-editor-validate-value"]
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, rules: :strict) }
  end

  def test_two_different_flows_compare_by_name
    render_with(review: { compare_with: { document: payload, label: "Customer onboarding", match: :name } })

    assert_equal "name", JSON.parse(island["data-bpmn-editor-review-value"]).dig("compare_with", 0, "match")
  end

  def test_the_comparison_matches_automatically_unless_told_otherwise_and_rejects_anything_else
    render_with(review: { compare_with: { document: payload, label: "v1" } })
    assert_equal "auto", JSON.parse(island["data-bpmn-editor-review-value"]).dig("compare_with", 0, "match")

    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, review: { compare_with: { document: payload, match: :position } }) }
    assert_raises(ArgumentError) { Bali::BpmnEditor::Component.new(data: payload, review: { compare_with: { document: payload, mode: :overlay } }) }
  end

  def test_several_comparisons_reach_the_island_as_a_list_one_as_a_list_of_one
    render_with(review: { compare_with: [ { document: payload, label: "v1", match: :id },
                                          { document: payload, label: "Another process", match: :name } ] })
    list = JSON.parse(island["data-bpmn-editor-review-value"])["compare_with"]
    assert_equal [ %w[v1 id], [ "Another process", "name" ] ], list.map { |c| [ c["label"], c["match"] ] }

    assert_raises(Bali::BpmnEditor::Data::InvalidError) do
      Bali::BpmnEditor::Component.new(data: payload, review: { compare_with: [ { document: payload }, { document: { orientation: "diagonal" } } ] })
    end
  end
end
