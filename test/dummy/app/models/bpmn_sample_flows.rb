# frozen_string_literal: true

# Synthetic documents for the Lookbook previews, the dummy app's seed and
# the tests. Content, not code: generic business flows, in English and
# Spanish.
module BpmnSampleFlows
  module_function

  # The hand-made flows and the 60-activity one live in
  # test/fixtures/bpmn_editor/samples.json, which the JS layout tests read too
  # (test/javascript/bpmn_editor/fixtures.js): one copy of each flow. Every
  # text is { en, es }.
  SAMPLES_PATH = Bali::Engine.root.join("test/fixtures/bpmn_editor/samples.json")
  SAMPLES = %w[invoice rework parallel partners large].freeze
  EMPTY = { version: 1, orientation: "horizontal", pool: { x: 0, y: 0 }, lanes: [], nodes: [], edges: [] }.freeze

  def samples
    @samples ||= JSON.parse(File.read(SAMPLES_PATH))
  end

  # `name` in `locale`. Without `positioned:` the coordinates go, and the
  # island lays the flow out on load (the layout it is given).
  def sample(name, locale: I18n.locale, positioned: false)
    return EMPTY.deep_dup if name.to_s == "empty"

    raise ArgumentError, "unknown sample #{name.inspect}; expected #{SAMPLES.inspect}" unless SAMPLES.include?(name.to_s)

    doc = localize(samples.fetch(name.to_s), locale.to_s).deep_symbolize_keys
    doc[:nodes] = doc[:nodes].map { |node| node.except(:x, :y) } unless positioned
    { version: 1, orientation: "horizontal", pool: { x: 0, y: 0 } }.merge(doc)
  end

  def localize(value, locale)
    case value
    when Hash
      return value[locale] || value["en"] if value.keys.sort == %w[en es]

      value.transform_values { |v| localize(v, locale) }
    when Array then value.map { |v| localize(v, locale) }
    else value
    end
  end

  # Accounts payable: an external supplier lane, a decision with Yes/No
  # branches, a message flow and an annotation.
  def invoice(orientation: "horizontal", version: 1, locale: :es)
    sample("invoice", locale: locale).merge(orientation: orientation, version: version)
  end

  # A long purchasing flow: 60 tasks in runs of five per lane over four lanes,
  # a decision every six steps.
  def large(locale: :es)
    sample("large", locale: locale).merge(status_label: locale.to_s == "en" ? "Draft" : "Borrador")
  end

  def event(type, kind)
    kind == "none" ? { type: type } : { type: type, event_definition: { kind: kind } }
  end

  # Every element the palette creates, mirroring PALETTE_ITEMS
  # (app/components/bali/bpmn_editor/model/catalog.js), each drawn twice: at
  # the size its palette icon draws it (NodeIcon's box, shapes.jsx iconBox,
  # 28 px) and at its canvas size, named with its palette label. One row per
  # palette group. test/requests/bpmn_editor_previews_test.rb checks it lists
  # every node item of Bali::BpmnEditor::Palette::KEYS.
  CATALOG = {
    "activities" => {
      "task" => { type: "task" }, "user_task" => { type: "user_task" }, "service_task" => { type: "service_task" },
      "send_task" => { type: "send_task" }, "receive_task" => { type: "receive_task" },
      "script_task" => { type: "script_task" }, "business_rule_task" => { type: "business_rule_task" },
      "manual_task" => { type: "manual_task" },
      "sub_process" => { type: "sub_process", reference: { id: "catalog", label: "Subproceso" } }
    },
    "gateways" => {
      "binary_decision" => { type: "exclusive_gateway", marker_visible: false },
      "exclusive_gateway" => { type: "exclusive_gateway" }, "parallel_gateway" => { type: "parallel_gateway" },
      "inclusive_gateway" => { type: "inclusive_gateway" }, "complex_gateway" => { type: "complex_gateway" },
      "event_based_gateway" => { type: "event_based_gateway" },
      "event_based_start_gateway" => { type: "event_based_gateway", instantiate: true },
      "parallel_event_based_gateway" => { type: "event_based_gateway", instantiate: true, event_gateway_type: "parallel" }
    },
    "artifacts" => {
      "text_annotation" => { type: "text_annotation" }, "group" => { type: "group" },
      "data_object" => { type: "data_object" }, "data_collection" => { type: "data_collection" },
      "data_input" => { type: "data_input" }, "data_output" => { type: "data_output" }, "data_store" => { type: "data_store" }
    },
    "start_events" => %w[none timer message conditional signal multiple parallel_multiple].to_h do |kind|
      [ kind == "none" ? "start_event" : "#{kind}_start_event", event("start_event", kind) ]
    end,
    "intermediate_events" => {
      "timer_event" => event("intermediate_catch_event", "timer"), "message_event" => event("intermediate_catch_event", "message"),
      "message_throw_event" => event("intermediate_throw_event", "message"),
      "escalation_event" => event("intermediate_throw_event", "escalation"),
      "compensation_event" => event("intermediate_throw_event", "compensation"),
      "conditional_event" => event("intermediate_catch_event", "conditional"),
      "link_event" => event("intermediate_catch_event", "link"), "link_throw_event" => event("intermediate_throw_event", "link"),
      "signal_event" => event("intermediate_catch_event", "signal"), "signal_throw_event" => event("intermediate_throw_event", "signal"),
      "multiple_event" => event("intermediate_catch_event", "multiple"),
      "parallel_multiple_event" => event("intermediate_catch_event", "parallel_multiple")
    },
    "end_events" => %w[none message error cancel compensation signal terminate multiple escalation].to_h do |kind|
      [ kind == "none" ? "end_event" : "#{kind}_end_event", event("end_event", kind) ]
    end
  }.freeze

  SIZES = { "activity" => [ 150, 64 ], "gateway" => [ 50, 50 ], "event" => [ 36, 36 ], "text_annotation" => [ 130, 50 ],
            "group" => [ 240, 150 ], "data_store" => [ 50, 48 ], "data" => [ 36, 48 ] }.freeze

  def size_of(attrs)
    type = attrs[:type]
    return SIZES["activity"] if type.end_with?("task") || type == "sub_process"
    return SIZES["gateway"] if type.end_with?("gateway")
    return SIZES["event"] if type.end_with?("event")
    SIZES[type] || SIZES["data"]
  end

  # NodeIcon's box at 28 px (shapes.jsx iconBox).
  def icon_size_of(attrs)
    type = attrs[:type]
    return [ 28, 21 ] if type.end_with?("task") || %w[sub_process group].include?(type)
    return [ 20, 28 ] if type.start_with?("data_")
    return [ 24, 24 ] if type == "text_annotation"
    [ 28, 28 ]
  end

  def catalog(labels)
    nodes = []
    CATALOG.values.each_with_index do |items, row|
      items.each_with_index do |(key, attrs), column|
        width, height = size_of(attrs)
        icon_width, icon_height = icon_size_of(attrs)
        middle = 60 + (row * 200) + 60
        left = 40 + (column * 280)
        nodes << attrs.merge(id: "icon-#{key}", name: "", x: left, y: middle - (icon_height / 2), width: icon_width, height: icon_height)
        # A group frames others, sized by the user: a smaller one keeps the row compact.
        width, height = 180, 100 if attrs[:type] == "group"
        canvas = attrs[:type] == "group" ? { width: width, height: height } : {}
        nodes << attrs.merge(id: key, name: labels["palette_#{key}"], x: left + 50, y: middle - (height / 2), **canvas)
      end
    end
    { version: 1, lanes: [], nodes: nodes, edges: [] }
  end
end
