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

export const FIXTURES = { invoice, rework, parallel, large, partners }
