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
    return doc if orientation == "horizontal"

    # Vertical: no coordinates, so the island lays it out on load.
    doc.merge(nodes: doc[:nodes].map { |node| node.except(:x, :y) })
  end

  # A long purchasing flow: `activities` tasks across four lanes with a
  # decision every `every` steps, no coordinates (laid out on load).
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
      lane = "l#{(i % 4) + 1}"
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
end
