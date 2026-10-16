# frozen_string_literal: true

# Synthetic documents for the Lookbook previews, the dummy app's seed and
# the tests. Content, not code: the names are what a Spanish-speaking
# host shows, so they are written in Spanish.
module BpmnSampleFlows
  module_function

  # Accounts payable: an external supplier lane, a decision with Yes/No
  # branches, a message flow and an annotation. Positioned by hand.
  def invoice(orientation: "horizontal", version: 1)
    doc = {
      version: version,
      orientation: orientation,
      status_label: "Borrador v0.3",
      pool: { x: 0, y: 0 },
      lanes: [
        { id: "l1", name: "Proveedor", kind: "external", order: 1, size: 160 },
        { id: "l2", name: "Cuentas por pagar", kind: "internal", order: 2, size: 180 },
        { id: "l3", name: "Tesorería", kind: "internal", order: 3, size: 160 }
      ],
      nodes: [
        { id: "p1", type: "task", lane_id: "l1", name: "Emitir factura", x: 70, y: 48 },
        { id: "s1", type: "start_event", lane_id: "l2", name: "Factura recibida",
          event_definition: { kind: "message" }, x: 127, y: 232,
          documentation: "Llega por el portal de proveedores." },
        { id: "t1", type: "user_task", lane_id: "l2", name: "Validar factura", x: 220, y: 218 },
        { id: "g1", type: "exclusive_gateway", lane_id: "l2", name: "¿La factura es válida?", x: 430, y: 225 },
        { id: "e2", type: "end_event", lane_id: "l2", name: "Fin", x: 600, y: 232 },
        { id: "t3", type: "task", lane_id: "l3", name: "Registrar pago", x: 530, y: 388 },
        { id: "t4", type: "service_task", lane_id: "l3", name: "Programar transferencia", x: 740, y: 388 },
        { id: "e1", type: "end_event", lane_id: "l3", name: "Pago realizado", x: 960, y: 402,
          documentation: "La transferencia queda programada en el banco." },
        { id: "a1", type: "text_annotation", name: "Revisar RFC, montos y orden de compra", x: 300, y: 30 }
      ],
      edges: [
        { id: "m1", type: "message_flow", source: "p1", target: "s1" },
        { id: "f1", source: "s1", target: "t1" },
        { id: "f2", source: "t1", target: "g1" },
        { id: "f3", source: "g1", target: "t3", label: "Sí" },
        { id: "f4", source: "g1", target: "e2", label: "No" },
        { id: "f5", source: "t3", target: "t4" },
        { id: "f6", source: "t4", target: "e1" },
        { id: "as1", type: "association", source: "a1", target: "t1" }
      ]
    }
    # No coordinates: the island lays the flow out on load, the same way every
    # time, in either orientation.
    doc.merge(nodes: doc[:nodes].map { |node| node.except(:x, :y) })
  end

  # A long purchasing flow: `activities` tasks in runs of five per lane over
  # four lanes, a decision every `every` steps, no coordinates (laid out on load).
  def large(activities: 60, every: 6)
    lanes = [ "Solicitante", "Compras", "Almacén", "Finanzas" ].each_with_index.map do |name, i|
      { id: "l#{i + 1}", name: name, kind: "internal", order: i + 1 }
    end
    nodes = [ { id: "start", type: "start_event", lane_id: "l1", name: "Necesidad detectada",
                documentation: "Cualquier área puede iniciar la compra." } ]
    edges = []
    previous = "start"
    activities.times do |i|
      step = i + 1
      lane = "l#{((i / 5) % 4) + 1}"
      nodes << { id: "t#{step}", type: "task", lane_id: lane, name: "Paso #{step} de la compra" }
      edges << { id: "f#{step}", source: previous, target: "t#{step}",
                 label: previous.start_with?("g") ? "Sí" : nil }.compact
      previous = "t#{step}"
      next unless (step % every).zero? && step < activities

      nodes << { id: "g#{step}", type: "exclusive_gateway", lane_id: lane, name: "¿Paso #{step} aprobado?",
                 documentation: "Lo decide el responsable del carril." }
      nodes << { id: "x#{step}", type: "end_event", lane_id: lane, name: "Compra cancelada en el paso #{step}",
                 documentation: "Se notifica al solicitante." }
      edges << { id: "f#{step}-g", source: "t#{step}", target: "g#{step}" }
      edges << { id: "f#{step}-no", source: "g#{step}", target: "x#{step}", label: "No" }
      previous = "g#{step}"
    end
    nodes << { id: "end", type: "end_event", lane_id: "l4", name: "Compra cerrada",
               documentation: "El pago quedó registrado." }
    edges << { id: "f-end", source: previous, target: "end" }
    { version: 1, orientation: "horizontal", status_label: "Borrador", lanes: lanes, nodes: nodes, edges: edges }
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
