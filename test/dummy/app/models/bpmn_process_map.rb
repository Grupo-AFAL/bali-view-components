# frozen_string_literal: true

# Synthetic documents for the «split view» and «compare flows» previews: a
# map of processes whose boxes the app colours, and the flow behind every
# box but the faded one. Content, not code — generic onboarding flows, in English and
# Spanish. The colours, badges and what they mean are this dummy app's, as
# they would be any host's: Bali only draws them.
module BpmnProcessMap
  module_function

  def text(locale, en, es) = locale.to_s == "en" ? en : es

  # What the map's colours say, for its legend (`swatch: "color"`).
  def colors
    { current: "#16a34a", review: "#E9A23B", draft: "#2563eb" }
  end

  def legend(locale)
    [
      { key: "map_current", label: text(locale, "Current version", "Versión vigente"), swatch: "color", color: colors[:current] },
      { key: "map_review", label: text(locale, "Under review", "En revisión"), swatch: "color", color: colors[:review] },
      { key: "map_draft", label: text(locale, "Draft", "Borrador"), swatch: "color", color: colors[:draft] },
      { key: "map_dimmed", label: text(locale, "Faded: no flow drawn yet", "Atenuado: aún sin flujo dibujado"),
        swatch: "color", color: "#9ca3af" }
    ]
  end

  # The boxes of the map: [id, lane, en, es, look, flow behind it].
  BOXES = [
    [ "b1", "m1", "Customer onboarding", "Alta de cliente", :draft, "customer" ],
    [ "b2", "m1", "Billing", "Facturación", :current, "billing" ],
    [ "b3", "m2", "Supplier onboarding", "Alta de proveedor", :current, "supplier" ],
    [ "b4", "m2", "Supplier payments", "Pago a proveedores", :review, "payments" ],
    [ "b5", "m3", "Bank reconciliation", "Conciliación bancaria", :dimmed, nil ],
    [ "b6", "m3", "Financial close", "Cierre contable", :current, "close" ],
    [ "b7", "m3", "Manage insurance and claims for company fixed assets",
      "Gestión de seguros y siniestros de activos fijos", :review, "close" ]
  ].freeze

  # Each box links somewhere real; the split view takes the click over
  # (`bali-bpmn:open-reference`, preventDefault), so it only selects.
  def map(locale:, reference_url:)
    lanes = [ [ "m1", "Sales", "Comercial" ], [ "m2", "Purchasing", "Abastecimiento" ], [ "m3", "Finance", "Finanzas" ] ]
            .each_with_index.map { |(id, en, es), i| { id: id, name: text(locale, en, es), kind: "internal", order: i + 1, size: 240 } }
    nodes = BOXES.map do |id, lane, en, es, look, flow|
      name = text(locale, en, es)
      { id: id, type: "sub_process", lane_id: lane, name: name,
        reference: { id: id, label: name, url: reference_url.call(id) }, appearance: appearance(look, locale, flow) }
    end
    edges = [ %w[e1 b1 b2], %w[e2 b3 b4], %w[e3 b4 b5], %w[e4 b2 b6], %w[e5 b5 b6], %w[e6 b6 b7] ]
            .map { |id, source, target| { id: id, source: source, target: target } }
    { version: 1, orientation: "vertical", pool: { x: 0, y: 0 }, lanes: lanes, nodes: nodes, edges: edges }
  end

  def appearance(look, locale, flow)
    case look
    when :current then { color: colors[:current], badge: text(locale, "Current", "Vigente") }
    when :review then { color: colors[:review], badge: text(locale, "Under review", "En revisión") }
    when :draft then { color: colors[:draft], badge: text(locale, "Draft", "Borrador") }
    when :dimmed then { dimmed: true, badge: flow ? nil : text(locale, "No flow", "Sin flujo") }.compact
    end
  end

  # The boxes as the split view's detail names them: id, name, lane name and
  # the flow behind it (nil for the faded one).
  def boxes(locale)
    lanes = map(locale: locale, reference_url: ->(_) { "" })[:lanes].to_h { |lane| [ lane[:id], lane[:name] ] }
    BOXES.map { |id, lane, en, es, _look, flow| { id: id, name: text(locale, en, es), lane: lanes[lane], flow: flow } }
  end

  # The flows behind the boxes as records, so their review notes are saved:
  # { key => [{ number:, flow: ProcessFlow }] }, newest version first. `fresh`
  # puts every one back to its sample (the preview, on each load); otherwise
  # the record as the notes left it.
  def flow_records(locale, fresh: false)
    flows(locale).to_h do |key, versions|
      [ key, versions.each_with_index.map do |doc, i|
        number = versions.size - i
        name = "Split view #{key} v#{number} (#{locale})"
        { number: number, flow: (ProcessFlow.find_by(name: name) unless fresh) || ProcessFlow.reset!(name, doc) }
      end ]
    end
  end

  # The flows behind the boxes, each with its versions, newest first.
  def flows(locale)
    {
      "supplier" => [ supplier(locale), supplier(locale, version: 1) ],
      "payments" => [ BpmnSampleFlows.invoice(locale: locale), payments_v1(locale) ],
      "customer" => [ customer(locale) ],
      "billing" => [ billing(locale) ],
      "close" => [ financial_close(locale) ]
    }
  end

  # Short flows, so each box of the map has one to open.
  def billing(locale)
    t = ->(en, es) { text(locale, en, es) }
    lanes = [
      { id: "l1", name: t.("Billing", "Facturación"), kind: "internal", order: 1, size: 160 },
      { id: "l2", name: t.("Collections", "Cobranza"), kind: "internal", order: 2, size: 160 },
      { id: "l3", name: t.("Customer", "Cliente"), kind: "external", order: 3, size: 120 }
    ]
    nodes = [
      { id: "s1", type: "start_event", lane_id: "l1", name: t.("Order delivered", "Pedido entregado") },
      { id: "t1", type: "service_task", lane_id: "l1", name: t.("Issue the invoice", "Emitir factura") },
      { id: "t2", type: "send_task", lane_id: "l1", name: t.("Send the invoice", "Enviar factura") },
      { id: "g1", type: "exclusive_gateway", marker_visible: false, lane_id: "l2", name: t.("Paid on time?", "¿Pagó a tiempo?") },
      { id: "t3", type: "task", lane_id: "l2", name: t.("Apply the payment", "Aplicar el pago") },
      { id: "t4", type: "send_task", lane_id: "l2", name: t.("Send a reminder", "Enviar recordatorio") },
      { id: "e1", type: "end_event", lane_id: "l2", name: t.("Invoice paid", "Factura pagada") },
      { id: "e2", type: "end_event", lane_id: "l2", name: t.("Sent to collections", "Turnada a cobranza") },
      { id: "x1", type: "task", lane_id: "l3", name: t.("Pay the invoice", "Pagar la factura") }
    ]
    edges = [
      { id: "f1", source: "s1", target: "t1" }, { id: "f2", source: "t1", target: "t2" },
      { id: "f3", source: "t2", target: "g1" },
      { id: "f4", source: "g1", target: "t3", label: t.("Yes", "Sí") }, { id: "f5", source: "g1", target: "t4", label: "No" },
      { id: "f6", source: "t3", target: "e1" }, { id: "f7", source: "t4", target: "e2" },
      { id: "m1", source: "t2", target: "x1", type: "message_flow" }
    ]
    { version: 1, orientation: "horizontal", pool: { x: 0, y: 0 }, lanes: lanes, nodes: nodes, edges: edges }
  end

  def financial_close(locale)
    t = ->(en, es) { text(locale, en, es) }
    lanes = [
      { id: "l1", name: t.("Accounting", "Contabilidad"), kind: "internal", order: 1, size: 160 },
      { id: "l2", name: t.("Controller", "Contraloría"), kind: "internal", order: 2, size: 160 }
    ]
    nodes = [
      { id: "s1", type: "start_event", event_definition: { kind: "timer" }, lane_id: "l1", name: t.("Month end", "Fin de mes") },
      { id: "t1", type: "task", lane_id: "l1", name: t.("Reconcile accounts", "Conciliar cuentas") },
      { id: "t2", type: "task", lane_id: "l1", name: t.("Post adjustments", "Registrar ajustes") },
      { id: "t3", type: "user_task", lane_id: "l2", name: t.("Review the statements", "Revisar estados financieros") },
      { id: "e1", type: "end_event", lane_id: "l2", name: t.("Close approved", "Cierre aprobado") }
    ]
    edges = [
      { id: "f1", source: "s1", target: "t1" }, { id: "f2", source: "t1", target: "t2" },
      { id: "f3", source: "t2", target: "t3" }, { id: "f4", source: "t3", target: "e1" }
    ]
    { version: 1, orientation: "horizontal", pool: { x: 0, y: 0 }, lanes: lanes, nodes: nodes, edges: edges }
  end

  def payments_v1(locale)
    doc = BpmnSampleFlows.invoice(locale: locale)
    doc[:nodes] = doc[:nodes].reject { |n| n[:id] == "t4" }
    doc[:edges] = doc[:edges].reject { |e| e[:source] == "t4" || e[:target] == "t4" } +
                  [ { id: "v1", source: "t3", target: "e1" } ]
    doc
  end

  # Supplier and customer onboarding share most of their steps and their
  # first two lanes; each has two steps of its own, and the third lane differs.
  def supplier(locale, version: 2)
    doc = onboarding(locale,
                     lane: [ "Purchasing", "Compras" ], external: [ "Supplier", "Proveedor" ],
                     own: [ [ "Validate tax details", "Validar datos fiscales", "task" ],
                            [ "Send documents", "Enviar documentos", "task" ] ],
                     register: "task")
    return doc if version == 2

    doc[:nodes] = doc[:nodes].reject { |n| n[:id] == "x1" }
    doc[:edges] = doc[:edges].reject { |e| e[:source] == "x1" || e[:target] == "x1" } + [ { id: "v1", source: "g1", target: "t3", label: text(locale, "Yes", "Sí") } ]
    doc
  end

  # Same steps, but registered by a service, and the requester notified by
  # the requester's own lane: a step moved to another lane.
  def customer(locale)
    doc = onboarding(locale,
                     lane: [ "Credit", "Crédito y cobranza" ], external: [ "Customer", "Cliente" ],
                     own: [ [ "Assess credit", "Evaluar crédito", "user_task" ],
                            [ "Sign the contract", "Firmar contrato", "task" ] ],
                     register: "service_task")
    doc[:nodes] = doc[:nodes].map { |n| n[:id] == "t5" ? n.merge(lane_id: "l1") : n }
    recreated(doc, prefix: "c")
  end

  # A third flow for the comparison selector: fewer steps in common.
  def employee(locale)
    doc = onboarding(locale,
                     lane: [ "Human resources", "Recursos humanos" ], external: [ "Candidate", "Candidato" ],
                     own: [ [ "Check references", "Verificar referencias", "task" ],
                            [ "Sign the contract", "Firmar contrato", "task" ] ],
                     register: "task")
    doc[:nodes] = doc[:nodes].map do |n|
      n[:id] == "t5" ? n.merge(name: text(locale, "Welcome the new hire", "Dar la bienvenida")) : n
    end
    recreated(doc, prefix: "e")
  end

  def onboarding(locale, lane:, external:, own:, register:)
    t = ->(en, es) { text(locale, en, es) }
    lanes = [
      { id: "l1", name: t.("Requester", "Solicitante"), kind: "internal", order: 1, size: 160 },
      { id: "l2", name: t.("Control desk", "Mesa de control"), kind: "internal", order: 2, size: 220 },
      { id: "l3", name: t.(*lane), kind: "internal", order: 3, size: 160 },
      { id: "l4", name: t.(*external), kind: "external", order: 4, size: 140 }
    ]
    nodes = [
      { id: "s1", type: "start_event", lane_id: "l1", name: t.("Request received", "Solicitud recibida") },
      { id: "t1", type: "user_task", lane_id: "l2", name: t.("Review documents", "Revisar documentación") },
      { id: "g1", type: "exclusive_gateway", marker_visible: false, lane_id: "l2", name: t.("Documents complete?", "¿Documentación completa?") },
      { id: "t2", type: "task", lane_id: "l2", name: t.("Request a correction", "Solicitar corrección") },
      { id: "x1", type: own[0][2], lane_id: "l3", name: t.(own[0][0], own[0][1]) },
      { id: "t3", type: register, lane_id: "l2", name: t.("Register in the system", "Registrar en el sistema") },
      { id: "t5", type: "send_task", lane_id: "l2", name: t.("Notify the requester", "Notificar al solicitante") },
      { id: "e1", type: "end_event", lane_id: "l2", name: t.("Onboarding completed", "Alta completada") },
      { id: "x2", type: own[1][2], lane_id: "l4", name: t.(own[1][0], own[1][1]) }
    ]
    edges = [
      { id: "f1", source: "s1", target: "t1" }, { id: "f2", source: "t1", target: "g1" },
      { id: "f3", source: "g1", target: "x1", label: t.("Yes", "Sí") }, { id: "f4", source: "g1", target: "t2", label: "No" },
      { id: "f5", source: "x1", target: "t3" }, { id: "f6", source: "t3", target: "t5" }, { id: "f7", source: "t5", target: "e1" },
      { id: "m1", source: "t2", target: "x2", type: "message_flow" }
    ]
    { version: 1, orientation: "horizontal", pool: { x: 0, y: 0 }, lanes: lanes, nodes: nodes, edges: edges }
  end

  # The same document with every id recreated, as an app that rebuilds its
  # records on import would hand it back — and as another process's records
  # are: their ids mean nothing to this one's.
  def recreated(doc, prefix: "r")
    ids = doc[:nodes].each_with_index.to_h { |n, i| [ n[:id], "#{prefix}#{i + 1}" ] }
    lanes = doc[:lanes].each_with_index.to_h { |l, i| [ l[:id], "#{prefix}l#{i + 1}" ] }
    doc.merge(
      lanes: doc[:lanes].map { |l| l.merge(id: lanes[l[:id]]) },
      nodes: doc[:nodes].map { |n| n.merge(id: ids[n[:id]], lane_id: lanes[n[:lane_id]]) },
      edges: doc[:edges].each_with_index.map { |e, i| e.merge(id: "#{prefix}e#{i + 1}", source: ids[e[:source]], target: ids[e[:target]]) }
    )
  end
end
