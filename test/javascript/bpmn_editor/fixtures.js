// Reference flows for the layout quality checks and the Lookbook previews.
// The hand-made ones live in test/fixtures/bpmn_editor/samples.json, which
// the dummy's BpmnSampleFlows reads too: every name is { en, es }, and the
// tests take the English one. `invoice` is positioned by hand; the others
// carry no coordinates and are laid out by the code under test.
import fs from 'node:fs'

const SAMPLES = JSON.parse(fs.readFileSync(new URL('../../fixtures/bpmn_editor/samples.json', import.meta.url), 'utf8'))

// A sample with its { en, es } texts in one locale.
export function localized (doc, locale = 'en') {
  const pick = (v) => (v && typeof v === 'object' && !Array.isArray(v) ? v[locale] : v)
  return {
    ...doc,
    ...(doc.status_label ? { status_label: pick(doc.status_label) } : {}),
    lanes: doc.lanes.map((l) => ({ ...l, name: pick(l.name) })),
    nodes: doc.nodes.map((n) => ({ ...n, ...(n.name != null ? { name: pick(n.name) } : {}), ...(n.documentation ? { documentation: pick(n.documentation) } : {}) })),
    edges: doc.edges.map((e) => ({ ...e, ...(e.label ? { label: pick(e.label) } : {}) }))
  }
}

const sample = (name) => () => localized(structuredClone(SAMPLES[name]))
export const invoice = sample('invoice')
export const rework = sample('rework')
export const parallel = sample('parallel')
export const partners = sample('partners')
export const samples = () => SAMPLES

// The long purchasing flow: runs of steps per lane, a decision every six
// steps. Generated, so tests can ask for any size; the 60-activity one the
// previews draw is stored in samples.json (`large`), checked equal to this.
// `localized: true` gives { en, es } texts, as samples.json keeps them.
export function large (activities = 60, every = 6, { localized: both = false } = {}) {
  const say = (en, es) => (both ? { en, es } : en)
  const lanes = [['Requester', 'Solicitante'], ['Purchasing', 'Compras'], ['Warehouse', 'Almacén'], ['Finance', 'Finanzas']]
    .map(([en, es], i) => ({ id: `l${i + 1}`, name: say(en, es), order: i + 1 }))
  const nodes = [{ id: 'start', type: 'start_event', lane_id: 'l1', name: say('Need detected', 'Necesidad detectada') }]
  const edges = []
  let previous = 'start'
  for (let step = 1; step <= activities; step++) {
    const lane = `l${(Math.floor((step - 1) / 5) % 4) + 1}`
    nodes.push({ id: `t${step}`, type: 'task', lane_id: lane, name: say(`Purchase step ${step}`, `Paso ${step} de la compra`) })
    edges.push({ id: `f${step}`, source: previous, target: `t${step}`, ...(previous.startsWith('g') ? { label: say('Yes', 'Sí') } : {}) })
    previous = `t${step}`
    if (step % every === 0 && step < activities) {
      nodes.push({ id: `g${step}`, type: 'exclusive_gateway', lane_id: lane, name: say(`Step ${step} approved?`, `¿Paso ${step} aprobado?`) })
      nodes.push({ id: `x${step}`, type: 'end_event', lane_id: lane, name: say(`Cancelled at ${step}`, `Compra cancelada en el paso ${step}`) })
      edges.push({ id: `f${step}-g`, source: `t${step}`, target: `g${step}` }, { id: `f${step}-no`, source: `g${step}`, target: `x${step}`, label: say('No', 'No') })
      previous = `g${step}`
    }
  }
  nodes.push({ id: 'end', type: 'end_event', lane_id: 'l4', name: say('Purchase closed', 'Compra cerrada') })
  edges.push({ id: 'f-end', source: previous, target: 'end' })
  return { version: 1, lanes, nodes, edges }
}

// «Alta de proveedor» as built in the demo video: three lanes, ten steps, a
// Yes/No decision whose «No» returns through a merge, a message flow.
export function supplierOnboarding () {
  const node = (id, type, lane, name, extra = {}) => ({ id, type, lane_id: lane, name, ...extra })
  return {
    version: 1,
    orientation: 'horizontal',
    lanes: [{ id: 'p', name: 'Proveedor', kind: 'external', order: 1 }, { id: 's', name: 'Solicitante', order: 2 }, { id: 'c', name: 'Compras', order: 3 }],
    nodes: [
      node('n1', 'start_event', 's', 'Necesidad de un proveedor'), node('n2', 'task', 's', 'Enviar solicitud de alta'),
      node('x', 'exclusive_gateway', 'c', ''), node('n3', 'task', 'c', 'Revisar documentación'),
      node('g', 'exclusive_gateway', 'c', '¿Documentación completa?', { marker_visible: false }), node('n4', 'task', 'c', 'Registrar proveedor'),
      node('n5', 'task', 'c', 'Avisar al solicitante'), node('e', 'end_event', 'c', 'Proveedor registrado'),
      node('n6', 'task', 'c', 'Solicitar corrección'), node('n7', 'task', 'p', 'Enviar documentos')
    ],
    edges: [
      { id: 'f1', source: 'n1', target: 'n2' }, { id: 'f2', source: 'n2', target: 'x' }, { id: 'f3', source: 'x', target: 'n3' },
      { id: 'f4', source: 'n3', target: 'g' }, { id: 'f5', source: 'g', target: 'n4', label: 'Sí' }, { id: 'f6', source: 'n4', target: 'n5' },
      { id: 'f7', source: 'n5', target: 'e' }, { id: 'f8', source: 'g', target: 'n6', label: 'No' }, { id: 'f9', source: 'n6', target: 'x' },
      { id: 'm', source: 'n7', target: 'n3', type: 'message_flow' }
    ]
  }
}

export const FIXTURES = { invoice, rework, parallel, large, partners }
