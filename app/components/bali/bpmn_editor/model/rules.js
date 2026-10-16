// Rule engine of the editor: each rule has an id, a default severity, a
// source, and a `check(doc, ctx)` that returns the offending elements. The
// host turns rules on and off, changes their severity and rewrites their
// messages (Bali::BpmnEditor::Component `rules:`), registers its own from JS
// (`registerBpmnRule`) or sends `issues` computed on the server.
//
// R01–R26 keep the numbering of the issue's catalogue (#1489) so a host can
// name them. B01–B11 are BPMN 2.0 structure and readability rules drawn from
// the OMG specification, bpmnlint and the Camunda modeling guidelines; they are
// warnings, and the more opinionated ones are off by default.
//
// The rules named after a criterion code (COM-19, ACT-02…) come from AFAL's
// BPMN criteria matrix (Criterios BPMN Rev.01); `criteria` lists the codes a
// rule covers and `section` the matrix's chapter, which the «Rules» dialog
// groups by. Those the matrix grounds in BPMN 2.0 are on by default; the ones
// that are AFAL guidelines only (`afal: true`) are off until the host turns
// them on, one by one or all at once with `enabled: ['afal']`.
//
// A rule never blocks saving: issues are what "Finalize" checks. The blocks
// that stop an edit on the spot are blockPolicy() below.
import { isActivity, isGateway, isArtifactLike, isFlowNode, isBinaryDecision, edgeType, paletteKeyFor } from './catalog.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from './geometry.js'
import { flowStructure } from './flowStructure.js'
import { plain, wordsOf, startsWith, contains, isInfinitive, isNominal, actionsIn, sameParticipant } from './wording.js'

const registry = new Map()

export function registerBpmnRule (rule) {
  if (!rule || !rule.id || typeof rule.check !== 'function') {
    throw new Error('registerBpmnRule needs { id, severity, check(doc, context) }')
  }
  registry.set(String(rule.id), { severity: 'error', source: 'app', ...rule, id: String(rule.id) })
}

export const unregisterBpmnRule = (id) => registry.delete(String(id))
export const registeredRules = () => [...registry.values()]

// ── helpers ────────────────────────────────────────────────────────────────

const sequence = (edges) => edges.filter((e) => edgeType(e) === 'sequence_flow')
const words = (name) => String(name || '').trim().toLowerCase()
const isJoin = (ctx, node) => ctx.inc(node).length > 1 && ctx.out(node).length <= 1
const isSplit = (ctx, node) => ctx.out(node).length > 1
const kind = (node) => node.event_definition && node.event_definition.kind
// A name like "Lane 3" or "New activity" — a word from the generic list,
// optionally followed by a number.
function generic (name, list) {
  const n = words(name).replace(/\s*\d+$/, '').trim()
  return n !== '' && list.includes(n)
}

// A splitting gateway that takes a decision (exclusive, inclusive, Yes/No).
const isDecision = (ctx, node) => (node.type === 'exclusive_gateway' || node.type === 'inclusive_gateway') && isSplit(ctx, node)
// The gateway a split's paths must close with (COM-19); null when the
// matrix sets none (complex gateway).
const CLOSING = { exclusive_gateway: 'exclusive_gateway', inclusive_gateway: 'inclusive_gateway', parallel_gateway: 'parallel_gateway', event_based_gateway: 'exclusive_gateway' }
// Elements of an external participant: another process, joined by message flows.
const externalLanes = (ctx) => new Set((ctx.doc.lanes || []).filter((l) => l.kind === 'external').map((l) => String(l.id)))

function context (doc, config, t, options = {}) {
  const nodes = doc.nodes || []
  const byId = new Map(nodes.map((n) => [String(n.id), n]))
  const flows = sequence(doc.edges || [])
  const incoming = new Map()
  const outgoing = new Map()
  for (const e of flows) {
    if (!byId.has(String(e.source)) || !byId.has(String(e.target))) continue
    if (!outgoing.has(String(e.source))) outgoing.set(String(e.source), [])
    if (!incoming.has(String(e.target))) incoming.set(String(e.target), [])
    outgoing.get(String(e.source)).push(e)
    incoming.get(String(e.target)).push(e)
  }
  let structure = null
  const list = (key) => (t && t.words ? t.words(key) : [])
  const plainList = (key) => list(key).map(plain).filter(Boolean)
  return {
    doc,
    nodes,
    byId,
    flows,
    layout: layoutLanes(doc),
    inc: (node) => incoming.get(String(node.id)) || [],
    out: (node) => outgoing.get(String(node.id)) || [],
    option: (key, fallback) => ruleOption(config, key, fallback),
    list,
    plainList,
    verbs: () => ({ verbs: plainList('action_verbs'), endings: plainList('infinitive_endings'), exceptions: plainList('not_infinitives') }),
    name: (node) => (node && String(node.name || '').trim()) || (t ? t('unnamed') : ''),
    translate: (key) => (t ? t(key) : key),
    gatewayKind: (node) => (t ? t(isBinaryDecision(node) ? 'palette_binary_decision' : `palette_${node.type}`) : node.type),
    yes: words(t ? t('label_yes') : 'yes'),
    no: words(t ? t('label_no') : 'no'),
    // Palette keys the host allows; null when it restricts nothing.
    allowed: options.allowed || null,
    get structure () { return structure || (structure = flowStructure(this)) }
  }
}

// ── catalogue ──────────────────────────────────────────────────────────────

const each = (list, test, build) => list.filter(test).map(build)

export const CATALOG = [
  {
    id: 'R01',
    section: 'sequence_flows',
    criteria: ['SEC-05', 'COM-14'],
    severity: 'error',
    source: 'bpmnlint: fake-join; Method and Style',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isActivity(n) && ctx.inc(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R02',
    section: 'gateways',
    criteria: ['COM-01'],
    severity: 'error',
    source: 'bpmnlint: no-implicit-split; Method and Style',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isActivity(n) && ctx.out(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R03',
    section: 'decisions',
    criteria: ['COM-07', 'COM-09', 'DEC-02'],
    severity: 'error',
    source: 'Method and Style: label the gates of a split; bpmnlint: conditional-flows',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => (n.type === 'exclusive_gateway' || n.type === 'inclusive_gateway') && isSplit(ctx, n) && ctx.out(n).some((e) => !words(e.label)),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R04',
    section: 'gateways',
    criteria: ['COM-02'],
    severity: 'error',
    source: '#1489 (optional)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => {
      if (n.type !== 'exclusive_gateway' || ctx.out(n).length <= 2) return false
      const labels = ctx.out(n).map((e) => words(e.label))
      return labels.includes(ctx.yes) && labels.includes(ctx.no)
    }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R05',
    section: 'gateways',
    criteria: ['COM-17', 'COM-18', 'COM-21'],
    severity: 'error',
    // Only paths that meet again need a merge: a branch that ends in an end
    // event has finished (COM-21). A merge of the wrong type is COM-19's.
    source: 'Method and Style: a parallel or inclusive split is merged by a gateway of its type; AFAL COM-21',
    check: (_doc, ctx) => each(ctx.nodes, (n) => {
      if ((n.type !== 'parallel_gateway' && n.type !== 'inclusive_gateway') || !isSplit(ctx, n)) return false
      const reached = ctx.structure.forwardOut(n).map((e) => ctx.structure.reach(String(e.target)))
      const meeting = new Set()
      reached.forEach((set, i) => { for (const id of set) if (reached.some((other, j) => j !== i && other.has(id))) meeting.add(id) })
      if (!meeting.size) return false
      return ![...meeting].some((id) => { const m = ctx.byId.get(id); return m && isGateway(m) && ctx.structure.forwardIn(m).length > 1 })
    }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R06',
    section: 'start_events',
    criteria: ['EVI-02'],
    severity: 'error',
    source: 'Camunda modeling guidelines: name start events after their trigger',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'start_event' && generic(n.name, ctx.list('generic_start_names')), (n) => ({ element_id: n.id }))
  },
  {
    id: 'R07',
    section: 'end_events',
    criteria: ['EVF-02'],
    severity: 'error',
    source: 'Camunda modeling guidelines: name end events after the end state',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'end_event' && generic(n.name, ctx.list('generic_end_names')), (n) => ({ element_id: n.id }))
  },
  {
    // A message or timer event names the communication or the term it waits
    // for (EVM-04, EVM-06), not just its kind. No description is required of
    // any element: a decision's criterion is its name (R09, B11 — COM-08).
    id: 'R08',
    section: 'intermediate_events',
    criteria: ['EVM-04', 'EVM-06'],
    severity: 'error',
    source: 'AFAL EVM-04; BPMN 2.0, AFAL EVM-06',
    check: (_doc, ctx) => {
      const generics = ctx.plainList('generic_event_names')
      return each(ctx.nodes,
        (n) => (n.type === 'intermediate_catch_event' || n.type === 'intermediate_throw_event') && ['message', 'timer'].includes(kind(n)) &&
          words(n.name) && generics.includes(wordsOf(n.name).join(' ')),
        (n) => ({ element_id: n.id, key: kind(n), vars: { name: ctx.name(n) } }))
    }
  },
  {
    // bpmnlint's label-required, minus merging gateways: the guidelines leave joins unnamed.
    id: 'R09',
    section: 'decisions',
    criteria: ['COM-06', 'COM-08', 'DEC-01'],
    severity: 'error',
    source: 'bpmnlint: label-required',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isFlowNode(n) && !(isGateway(n) && isJoin(ctx, n)) && !words(n.name), (n) => ({ element_id: n.id }))
  },
  {
    id: 'R10',
    section: 'lanes',
    criteria: ['LAN-07'],
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => each(ctx.doc.lanes || [],
      (l) => !ctx.nodes.some((n) => String(n.lane_id) === String(l.id) && isActivity(n)),
      (l) => ({ element_id: l.id, vars: { name: l.name || '' } }))
  },
  {
    id: 'R11',
    section: 'subprocesses',
    criteria: ['SUB-01'],
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'sub_process' && !(n.reference && n.reference.id), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R12',
    section: 'start_events',
    criteria: ['EVI-01'],
    severity: 'error',
    source: 'bpmnlint: start-event-required, end-event-required',
    check: (_doc, ctx) => (ctx.nodes.some((n) => n.type === 'start_event') && ctx.nodes.some((n) => n.type === 'end_event') ? [] : [{ element_id: null }])
  },
  {
    // A link catch has no incoming flow and a link throw no outgoing one by
    // design (BPMN 2.0 §10.5.5). An external participant is another process
    // drawn as a lane: a message flow is how its elements connect.
    id: 'R13',
    section: 'sequence_flows',
    criteria: ['SEC-02'],
    severity: 'error',
    source: 'bpmnlint: no-disconnected',
    check: (_doc, ctx) => {
      const found = []
      const external = new Set((ctx.doc.lanes || []).filter((l) => l.kind === 'external').map((l) => String(l.id)))
      const messaged = new Set((ctx.doc.edges || []).filter((e) => edgeType(e) === 'message_flow').flatMap((e) => [String(e.source), String(e.target)]))
      for (const n of ctx.nodes) {
        if (!isFlowNode(n)) continue
        if (external.has(String(n.lane_id)) && messaged.has(String(n.id))) continue
        const link = kind(n) === 'link'
        if (n.type !== 'start_event' && !(link && n.type === 'intermediate_catch_event') && !ctx.inc(n).length) found.push({ element_id: n.id, key: 'in', vars: { name: ctx.name(n) } })
        if (n.type !== 'end_event' && !(link && n.type === 'intermediate_throw_event') && !ctx.out(n).length) found.push({ element_id: n.id, key: 'out', vars: { name: ctx.name(n) } })
      }
      return found
    }
  },
  {
    id: 'R14',
    section: 'gateways',
    severity: 'error',
    source: 'bpmnlint: no-gateway-join-fork',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isGateway(n) && ctx.inc(n).length > 1 && ctx.out(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R15',
    section: 'gateways',
    severity: 'warning',
    source: 'bpmnlint: superfluous-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isGateway(n) && ctx.inc(n).length === 1 && ctx.out(n).length === 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R16',
    section: 'activities',
    criteria: ['ACT-06'],
    severity: 'warning',
    source: 'Method and Style: distinct activity names',
    check: (_doc, ctx) => {
      const groups = new Map()
      for (const n of ctx.nodes) {
        if (!isActivity(n) || n.type === 'sub_process' || !words(n.name)) continue
        const key = words(n.name)
        if (!groups.has(key)) groups.set(key, [])
        groups.get(key).push(n)
      }
      return [...groups.values()].filter((g) => g.length > 1).flatMap((g) => g.slice(1).map((n) => ({ element_id: n.id, vars: { name: ctx.name(n) } })))
    }
  },
  {
    id: 'R17',
    section: 'activities',
    criteria: ['ACT-02'],
    severity: 'warning',
    source: 'Camunda modeling guidelines: activities as verb + object',
    check: (_doc, ctx) => {
      const verbs = ctx.list('vague_verbs')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && verbs.includes(words(n.name)), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'R18',
    section: 'layout',
    criteria: ['VIS-07'],
    severity: 'error',
    source: '#1489 (legibility)',
    check: (_doc, ctx) => {
      const found = []
      const solid = ctx.nodes.filter((n) => n.type !== 'group')
      for (let i = 0; i < solid.length; i++) {
        for (let j = i + 1; j < solid.length; j++) {
          if (boxesOverlap(nodeBox(solid[i]), nodeBox(solid[j]), -2)) { found.push({ element_id: solid[i].id, vars: { name: ctx.name(solid[i]) } }); break }
        }
      }
      return found
    }
  },
  {
    id: 'R19',
    section: 'structure',
    severity: 'warning',
    source: 'Method and Style: hierarchical modelling',
    check: (_doc, ctx) => {
      const count = ctx.nodes.filter(isActivity).length
      return count > ctx.option('max_activities', 25) ? [{ element_id: null, vars: { count } }] : []
    }
  },
  {
    id: 'R20',
    section: 'structure',
    severity: 'error',
    source: '#1489 (optional)',
    check: (_doc, ctx) => {
      const min = ctx.option('min_activities', 2)
      return ctx.nodes.filter(isActivity).length < min ? [{ element_id: null, vars: { count: min } }] : []
    }
  },
  {
    id: 'R21',
    section: 'lanes',
    criteria: ['LAN-09'],
    severity: 'error',
    // Lanes that take part: an empty lane is no second participant (LAN-09).
    source: '#1489; AFAL LAN-09',
    check: (_doc, ctx) => {
      const min = ctx.option('min_lanes', 2)
      const current = (ctx.doc.lanes || []).filter((l) => ctx.nodes.some((n) => isActivity(n) && String(n.lane_id) === String(l.id))).length
      return current < min ? [{ element_id: null, vars: { count: min, current } }] : []
    }
  },
  {
    id: 'R22',
    section: 'lanes',
    criteria: ['LAN-02'],
    severity: 'error',
    source: 'Camunda modeling guidelines: name lanes after their role',
    check: (_doc, ctx) => each(ctx.doc.lanes || [], (l) => !words(l.name) || generic(l.name, ctx.list('generic_lane_names')), (l) => ({ element_id: l.id }))
  },
  {
    id: 'R23',
    section: 'activities',
    criteria: ['ACT-03'],
    severity: 'error',
    source: 'Camunda modeling guidelines: specific names',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => (isActivity(n) && generic(n.name, ctx.list('generic_task_names'))) || (isGateway(n) && generic(n.name, ctx.list('generic_gateway_names'))),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R24',
    section: 'start_events',
    criteria: ['EVI-06', 'EVF-05'],
    severity: 'error',
    source: 'BPMN 2.0 §10.5.2 and §10.5.3',
    check: (_doc, ctx) => [
      ...each(ctx.nodes, (n) => n.type === 'start_event' && ctx.inc(n).length > 0, (n) => ({ element_id: n.id, key: 'in', vars: { name: ctx.name(n) } })),
      ...each(ctx.nodes, (n) => n.type === 'end_event' && ctx.out(n).length > 0, (n) => ({ element_id: n.id, key: 'out', vars: { name: ctx.name(n) } }))
    ]
  },
  {
    id: 'R25',
    section: 'sequence_flows',
    criteria: ['SEC-02'],
    severity: 'error',
    source: 'BPMN 2.0 §8.4.13 (sourceRef and targetRef)',
    check: (_doc, ctx) => each(ctx.doc.edges || [], (e) => !ctx.byId.has(String(e.source)) || !ctx.byId.has(String(e.target)), (e) => ({ element_id: e.id }))
  },
  {
    id: 'R26',
    section: 'lanes',
    criteria: ['LAN-06'],
    severity: 'error',
    source: 'BPMN 2.0 §10.8 (lanes partition the flow elements)',
    check: (_doc, ctx) => (ctx.layout.entries.length
      ? each(ctx.nodes, (n) => isFlowNode(n) && !insideLane(ctx.layout, n), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
      : [])
  },
  {
    id: 'B01',
    section: 'gateways',
    severity: 'warning',
    source: 'BPMN 2.0 §10.6.6; bpmnlint: event-based-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => {
      if (n.type !== 'event_based_gateway') return false
      const targets = ctx.out(n).map((e) => ctx.byId.get(String(e.target)))
      return targets.length < 2 || targets.some((m) => !m || !(m.type === 'intermediate_catch_event' || m.type === 'receive_task'))
    }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B02',
    section: 'external',
    severity: 'warning',
    source: 'BPMN 2.0 §9.3 (message flow joins two participants)',
    check: (_doc, ctx) => {
      const participant = (node) => {
        const lane = (ctx.doc.lanes || []).find((l) => String(l.id) === String(node.lane_id))
        return lane && lane.kind === 'external' ? `external:${lane.id}` : 'process'
      }
      return (ctx.doc.edges || []).filter((e) => edgeType(e) === 'message_flow').flatMap((e) => {
        const source = ctx.byId.get(String(e.source))
        const target = ctx.byId.get(String(e.target))
        return source && target && participant(source) === participant(target) ? [{ element_id: e.id, vars: { name: ctx.name(source) } }] : []
      })
    }
  },
  {
    id: 'B03',
    section: 'artifacts',
    severity: 'warning',
    source: 'BPMN 2.0 §7.6 (associations link artifacts)',
    check: (_doc, ctx) => (ctx.doc.edges || []).filter((e) => edgeType(e) === 'association').flatMap((e) => {
      const source = ctx.byId.get(String(e.source))
      const target = ctx.byId.get(String(e.target))
      return source && target && !isArtifactLike(source) && !isArtifactLike(target) ? [{ element_id: e.id }] : []
    })
  },
  {
    id: 'B04',
    section: 'artifacts',
    severity: 'warning',
    source: 'BPMN 2.0 §8.4.13 (sequence flows join flow nodes)',
    check: (_doc, ctx) => ctx.flows.flatMap((e) => [ctx.byId.get(String(e.source)), ctx.byId.get(String(e.target))])
      .filter((n) => n && isArtifactLike(n))
      .map((n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B05',
    section: 'intermediate_events',
    severity: 'warning',
    source: 'BPMN 2.0 §10.5.5; bpmnlint: link-event',
    check: (_doc, ctx) => {
      const links = ctx.nodes.filter((n) => kind(n) === 'link')
      return each(links, (n) => !links.some((m) => m.type !== n.type && words(m.name) === words(n.name)), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'B06',
    section: 'end_events',
    severity: 'warning',
    source: 'BPMN 2.0 §10.5.3 (error and cancel end events need a boundary to catch them)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'end_event' && (kind(n) === 'error' || kind(n) === 'cancel'), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B07',
    section: 'gateways',
    severity: 'warning',
    source: 'bpmnlint: no-complex-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'complex_gateway', (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B08',
    section: 'start_events',
    severity: 'warning',
    source: 'bpmnlint: single-blank-start-event',
    check: (_doc, ctx) => ctx.nodes.filter((n) => n.type === 'start_event' && !kind(n)).slice(1).map((n) => ({ element_id: n.id }))
  },
  {
    id: 'B09',
    section: 'sequence_flows',
    severity: 'warning',
    source: 'bpmnlint: no-duplicate-sequence-flows',
    check: (_doc, ctx) => {
      const seen = new Set()
      return ctx.flows.flatMap((e) => {
        const key = `${e.source}>${e.target}`
        if (seen.has(key)) return [{ element_id: e.id }]
        seen.add(key)
        return []
      })
    }
  },
  {
    id: 'B10',
    section: 'gateways',
    severity: 'warning',
    source: 'BPMN 2.0 §10.6.6 (instantiating event-based gateway)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'event_based_gateway' && n.instantiate && ctx.inc(n).length > 0, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B11',
    section: 'decisions',
    criteria: ['COM-13', 'DEC-01'],
    severity: 'warning',
    // A decision (exclusive, Yes/No or inclusive split) is phrased as a
    // question, and is no activity: a question that starts with a verb in
    // the infinitive ("Authorize request?") still names work.
    source: 'Camunda modeling guidelines: label exclusive gateways as questions; BPMN 2.0, AFAL COM-13; AFAL DEC-01',
    check: (_doc, ctx) => ctx.nodes.filter((n) => isDecision(ctx, n) && words(n.name)).flatMap((n) => {
      const vars = { name: ctx.name(n) }
      if (isInfinitive(wordsOf(n.name)[0], ctx.verbs())) return [{ element_id: n.id, key: 'verb', vars }]
      return /\?\s*$/.test(String(n.name).trim()) ? [] : [{ element_id: n.id, vars }]
    })
  },

  // ── AFAL criteria matrix: structure ─────────────────────────────────────
  {
    // Each merge closes the split that opened its paths with the matching
    // gateway: Yes/No → XOR, XOR → XOR, OR → OR, AND → AND. The opening is
    // the merge's immediate dominator (flowStructure.js); a merge on a
    // rework loop is COM-22's.
    id: 'COM-19',
    section: 'gateways',
    criteria: ['COM-15', 'COM-16', 'COM-17', 'COM-18', 'COM-19'],
    severity: 'error',
    source: 'AFAL COM-15; BPMN 2.0, AFAL COM-16, COM-17, COM-19; BPMN 2.0 COM-18',
    check: (_doc, ctx) => ctx.nodes.filter((n) => isGateway(n) && ctx.structure.forwardIn(n).length > 1).flatMap((join) => {
      const opening = ctx.structure.opening(join)
      const expected = opening && CLOSING[opening.type]
      if (!expected || join.type === expected) return []
      return [{ element_id: join.id, vars: { name: ctx.name(join), kind: ctx.gatewayKind(join), opening: ctx.name(opening), expected: say(ctx, `palette_${expected}`) } }]
    })
  },
  {
    // Nested splits close from the inside out: one branch of the outer split
    // reaches its merge through ONE connection; two mean an inner split whose
    // paths skipped their own merge.
    id: 'COM-20',
    section: 'gateways',
    criteria: ['COM-20'],
    severity: 'error',
    source: 'BPMN 2.0, AFAL COM-20',
    check: (_doc, ctx) => ctx.nodes.filter((n) => isGateway(n) && ctx.structure.forwardIn(n).length > 1).flatMap((join) => {
      const opening = ctx.structure.opening(join)
      if (!opening) return []
      const branches = ctx.structure.forwardOut(opening).map((e) => ctx.structure.reach(String(e.target), String(join.id)))
      const used = new Map()
      for (const e of ctx.structure.forwardIn(join)) {
        branches.forEach((reached, i) => {
          if (String(e.source) === String(opening.id) ? String(ctx.structure.forwardOut(opening)[i].id) === String(e.id) : reached.has(String(e.source))) {
            used.set(i, (used.get(i) || 0) + 1)
          }
        })
      }
      return [...used.values()].some((count) => count > 1) ? [{ element_id: join.id, vars: { name: ctx.name(join), opening: ctx.name(opening) } }] : []
    })
  },
  {
    id: 'COM-12',
    section: 'gateways',
    criteria: ['COM-12'],
    severity: 'error',
    source: 'BPMN 2.0 COM-12',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'parallel_gateway' && isSplit(ctx, n) && ctx.out(n).some((e) => words(e.label)), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    // The Yes/No decision has exactly two ways out (COM-02); R03 asks for
    // their labels (COM-07).
    id: 'COM-02',
    section: 'gateways',
    criteria: ['COM-02', 'COM-07'],
    severity: 'error',
    source: 'AFAL COM-02, COM-07',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isBinaryDecision(n) && !isJoin(ctx, n) && ctx.out(n).length !== 2, (n) => ({ element_id: n.id, vars: { name: ctx.name(n), count: ctx.out(n).length } }))
  },
  {
    id: 'DEC-03',
    section: 'decisions',
    criteria: ['DEC-03'],
    severity: 'warning',
    source: 'AFAL DEC-03',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => isBinaryDecision(n) && ctx.out(n).length === 2 && ctx.out(n).every((e) => words(e.label)) &&
        !ctx.out(n).every((e) => [ctx.yes, ctx.no].includes(words(e.label))),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n), yes: say(ctx, 'label_yes'), no: say(ctx, 'label_no') } }))
  },
  {
    // A return to an earlier point (a back edge) lands on a merging XOR placed
    // before the first repeated activity — never on the activity itself nor
    // on an AND.
    id: 'COM-22',
    section: 'gateways',
    criteria: ['ACT-13', 'COM-22', 'EST-04'],
    afal: true,
    severity: 'error',
    source: 'AFAL ACT-13, COM-22, EST-04',
    check: (_doc, ctx) => [...ctx.structure.back].flatMap((e) => {
      const target = ctx.byId.get(String(e.target))
      if (!target || (target.type === 'exclusive_gateway' && !isBinaryDecision(target) && ctx.inc(target).length > 1)) return []
      return [{ element_id: e.id, vars: { name: ctx.name(target) } }]
    })
  },
  {
    // Every cycle has a way out: some element of it leads outside it.
    id: 'EST-05',
    section: 'structure',
    criteria: ['EST-05'],
    severity: 'error',
    source: 'BPMN 2.0, AFAL EST-05',
    check: (_doc, ctx) => ctx.structure.cycles().flatMap((members) => {
      const inside = new Set(members)
      const exits = ctx.flows.some((e) => inside.has(String(e.source)) && !inside.has(String(e.target)))
      if (exits) return []
      const first = ctx.nodes.find((n) => inside.has(String(n.id)))
      return [{ element_id: first.id, vars: { name: ctx.name(first) } }]
    })
  },
  {
    // Every element on the way from a start event to an end event: none that
    // no start reaches, none that reaches no end. Disconnected elements are
    // R13's; an external participant's elements are another process.
    id: 'EST-01',
    section: 'structure',
    criteria: ['EST-01', 'EST-02', 'SEC-04', 'EVF-01'],
    severity: 'error',
    source: 'BPMN 2.0, AFAL EST-01, EVF-01; AFAL EST-02, SEC-04',
    check: (_doc, ctx) => {
      const starts = ctx.nodes.filter((n) => n.type === 'start_event')
      const ends = ctx.nodes.filter((n) => n.type === 'end_event')
      if (!starts.length || !ends.length) return []
      const walk = (from, step) => {
        const seen = new Set(from.map((n) => String(n.id)))
        const stack = [...seen]
        while (stack.length) {
          const id = stack.pop()
          for (const next of step(id)) if (!seen.has(next)) { seen.add(next); stack.push(next) }
        }
        return seen
      }
      const links = (id, forward) => {
        const node = ctx.byId.get(id)
        if (!node || kind(node) !== 'link') return []
        const pair = forward ? 'intermediate_catch_event' : 'intermediate_throw_event'
        return ctx.nodes.filter((m) => m.type === pair && kind(m) === 'link' && words(m.name) === words(node.name)).map((m) => String(m.id))
      }
      const fromStart = walk(starts, (id) => [...ctx.out(ctx.byId.get(id)).map((e) => String(e.target)), ...links(id, true)])
      const toEnd = walk(ends, (id) => [...ctx.inc(ctx.byId.get(id)).map((e) => String(e.source)), ...links(id, false)])
      const external = externalLanes(ctx)
      return each(ctx.nodes, (n) => isFlowNode(n) && !external.has(String(n.lane_id)) &&
        (n.type === 'start_event' || ctx.inc(n).length) && (n.type === 'end_event' || ctx.out(n).length) &&
        (!fromStart.has(String(n.id)) || !toEnd.has(String(n.id))),
      (n) => ({ element_id: n.id, key: fromStart.has(String(n.id)) ? 'end' : 'start', vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'EVF-04',
    section: 'end_events',
    criteria: ['EVF-04'],
    afal: true,
    severity: 'error',
    source: 'AFAL EVF-04',
    check: (_doc, ctx) => {
      const seen = new Set()
      return ctx.nodes.filter((n) => n.type === 'end_event' && words(n.name)).flatMap((n) => {
        const key = wordsOf(n.name).join(' ')
        if (!seen.has(key)) { seen.add(key); return [] }
        return [{ element_id: n.id, vars: { name: ctx.name(n) } }]
      })
    }
  },
  {
    // The related procedure states what it receives and what it hands back,
    // and the two differ (SUB-07).
    id: 'SUB-05',
    section: 'subprocesses',
    criteria: ['SUB-05', 'SUB-06', 'SUB-07'],
    afal: true,
    severity: 'error',
    source: 'AFAL SUB-05, SUB-06, SUB-07',
    check: (_doc, ctx) => ctx.nodes.filter((n) => n.type === 'sub_process').flatMap((n) => {
      const vars = { name: ctx.name(n) }
      const found = []
      if (ctx.inc(n).some((e) => !words(e.label))) found.push({ element_id: n.id, key: 'in', vars })
      if (ctx.out(n).some((e) => !words(e.label))) found.push({ element_id: n.id, key: 'out', vars })
      const ins = new Set(ctx.inc(n).map((e) => plain(e.label)).filter(Boolean))
      if (!found.length && ctx.out(n).some((e) => ins.has(plain(e.label)))) found.push({ element_id: n.id, key: 'same', vars })
      return found
    })
  },
  {
    // A diagram brought in with elements the host's palette does not offer.
    id: 'VIS-10',
    section: 'layout',
    criteria: ['EVM-01', 'VIS-10'],
    severity: 'error',
    source: 'AFAL EVM-01; BPMN 2.0, AFAL VIS-10',
    check: (_doc, ctx) => (ctx.allowed
      ? each(ctx.nodes, (n) => { const key = paletteKeyFor(n); return key && !ctx.allowed.has(key) }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n), kind: say(ctx, `palette_${paletteKeyFor(n)}`) } }))
      : [])
  },

  // ── AFAL criteria matrix: wording (warnings; the word lists are i18n) ────
  {
    // Infinitive + object ("Validate the documents"), not a noun phrase
    // ("Validation of documents").
    id: 'ACT-02',
    section: 'activities',
    criteria: ['ACT-02'],
    afal: true,
    severity: 'warning',
    source: 'AFAL ACT-02',
    check: (_doc, ctx) => {
      const lists = ctx.verbs()
      const nominal = ctx.plainList('nominal_endings')
      return each(ctx.nodes, (n) => {
        if (!isActivity(n) || n.type === 'sub_process' || !words(n.name)) return false
        const [first, ...rest] = wordsOf(n.name)
        return !rest.length || isNominal(first, nominal) || (lists.endings.length > 0 && !isInfinitive(first, lists))
      }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    // Receiving or passing information on is a transition, not work.
    id: 'ACT-07',
    section: 'activities',
    criteria: ['ACT-01', 'ACT-07', 'ACT-08'],
    afal: true,
    severity: 'warning',
    source: 'AFAL ACT-01, ACT-07, ACT-08',
    check: (_doc, ctx) => {
      const verbs = ctx.plainList('transition_verbs')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && startsWith(n.name, verbs), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'ACT-09',
    section: 'activities',
    criteria: ['ACT-09'],
    afal: true,
    severity: 'warning',
    source: 'AFAL ACT-09',
    check: (_doc, ctx) => {
      const phrases = ctx.plainList('continuous_phrases')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && startsWith(n.name, phrases), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    // A vague phrase (ACT-03), a screen instruction (ACT-04), or several
    // actions in one box (ACT-05).
    id: 'ACT-03',
    section: 'activities',
    criteria: ['ACT-03', 'ACT-04', 'ACT-05'],
    afal: true,
    severity: 'warning',
    source: 'AFAL ACT-03, ACT-04, ACT-05',
    check: (_doc, ctx) => {
      const vague = ctx.plainList('vague_phrases')
      const operative = ctx.plainList('operative_phrases')
      const conjunctions = ctx.plainList('conjunctions')
      const lists = ctx.verbs()
      return ctx.nodes.filter((n) => isActivity(n) && n.type !== 'sub_process' && words(n.name)).flatMap((n) => {
        const vars = { name: ctx.name(n) }
        if (contains(n.name, vague)) return [{ element_id: n.id, key: 'vague', vars }]
        if (contains(n.name, operative)) return [{ element_id: n.id, key: 'operative', vars }]
        if (actionsIn(n.name, lists, conjunctions) > 1) return [{ element_id: n.id, key: 'several', vars }]
        return []
      })
    }
  },
  {
    // Validating, reviewing, approving produce a result: a decision follows.
    id: 'ACT-10',
    section: 'activities',
    criteria: ['ACT-10', 'ACT-11', 'ACT-12'],
    afal: true,
    severity: 'warning',
    source: 'AFAL ACT-10, ACT-11, ACT-12',
    check: (_doc, ctx) => {
      const verbs = ctx.plainList('decision_verbs')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && startsWith(n.name, verbs) && ctx.out(n).length > 0 &&
        !ctx.out(n).some((e) => { const next = ctx.byId.get(String(e.target)); return next && isDecision(ctx, next) }),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    // A start, end or conditional event names a fact or a state, not an action.
    id: 'EVI-03',
    section: 'start_events',
    criteria: ['EVI-03', 'EVF-03', 'EVM-09'],
    severity: 'warning',
    source: 'BPMN 2.0, AFAL EVI-03, EVF-03, EVM-09',
    check: (_doc, ctx) => {
      const lists = ctx.verbs()
      return each(ctx.nodes,
        (n) => (n.type === 'start_event' || n.type === 'end_event' || (n.type === 'intermediate_catch_event' && kind(n) === 'conditional')) &&
          words(n.name) && isInfinitive(wordsOf(n.name)[0], lists),
        (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'EVI-05',
    section: 'start_events',
    criteria: ['EVI-05'],
    severity: 'warning',
    source: 'BPMN 2.0, AFAL EVI-05',
    check: (_doc, ctx) => {
      const periodic = ctx.plainList('periodic_words')
      return each(ctx.nodes, (n) => n.type === 'start_event' && !kind(n) && contains(n.name, periodic), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'LAN-08',
    section: 'lanes',
    criteria: ['LAN-08'],
    afal: true,
    severity: 'warning',
    source: 'AFAL LAN-08',
    check: (_doc, ctx) => {
      const lanes = (ctx.doc.lanes || []).filter((l) => words(l.name))
      return lanes.flatMap((lane, i) => {
        const twin = lanes.slice(0, i).find((other) => sameParticipant(other.name, lane.name))
        return twin ? [{ element_id: lane.id, vars: { name: lane.name, other: twin.name } }] : []
      })
    }
  }
]

// A translated string inside a check (the context carries no translator).
function say (ctx, key) {
  return ctx.translate ? ctx.translate(key) : key
}

// Rules on by default: the issue's standard catalogue, the BPMN structure
// rules and the matrix rules grounded in BPMN 2.0. Off: the issue's optional
// ones (R14, R15, R17, R19), R04 and R20 (domain conventions), the stylistic
// B07, and the AFAL-only guidelines (`afal: true`).
export const DEFAULT_ENABLED = new Set([
  'R01', 'R02', 'R03', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R12', 'R13', 'R16', 'R18', 'R21',
  'R22', 'R23', 'R24', 'R25', 'R26', 'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B08', 'B09', 'B10', 'B11',
  'COM-19', 'COM-20', 'COM-12', 'COM-02', 'DEC-03', 'EST-05', 'EST-01', 'VIS-10', 'EVI-03', 'EVI-05'
])

// `enabled: ['afal']` turns on every AFAL-only guideline at once.
export const AFAL_RULES = new Set(CATALOG.filter((rule) => rule.afal).map((rule) => rule.id))

export function isRuleOn (config, id) {
  const disabled = (config && config.disabled) || []
  const enabled = (config && config.enabled) || []
  if (disabled.includes(id)) return false
  return DEFAULT_ENABLED.has(id) || enabled.includes(id) || (enabled.includes('afal') && AFAL_RULES.has(id)) || registry.has(id)
}

export function ruleOption (config, key, fallback) {
  const value = config && config.options && config.options[key]
  return value == null ? fallback : Number(value)
}

export function severityOf (config, rule) {
  const override = config && config.severities && config.severities[rule.id]
  return override === 'warning' || override === 'error' ? override : rule.severity
}

// Every rule the editor knows, built-in and registered, with its state.
export function ruleList (config) {
  return [...CATALOG, ...registeredRules()].map((rule) => ({
    id: rule.id,
    source: rule.source,
    title: rule.title,
    section: rule.section || 'app',
    criteria: rule.criteria || [],
    on: isRuleOn(config, rule.id),
    severity: severityOf(config, rule)
  }))
}

// Issues of a document: [{ rule, element_id, severity, message, source }].
// `options.allowed`: the palette keys the host enables (VIS-10).
export function evaluate (doc, config = {}, t = null, options = {}) {
  const ctx = context(doc, config, t, options)
  const messages = (config && config.messages) || {}
  const found = []
  for (const rule of [...CATALOG, ...registeredRules()]) {
    if (!isRuleOn(config, rule.id)) continue
    const severity = severityOf(config, rule)
    let hits = []
    try {
      hits = rule.check(doc, ctx) || []
    } catch (error) {
      // A host rule that throws must not take the editor down with it.
      if (typeof console !== 'undefined') console.error(`bpmn rule ${rule.id} failed`, error)
      continue
    }
    for (const hit of hits) {
      const vars = hit.vars || {}
      const custom = messages[rule.id]
      const key = hit.key ? `rule_${rule.id}_${hit.key}` : `rule_${rule.id}`
      let message = hit.message
      if (!message && custom) message = interpolate(custom, vars)
      if (!message && t) message = t(key, vars)
      found.push({
        rule: rule.id,
        element_id: hit.element_id == null ? null : String(hit.element_id),
        severity: hit.severity || severity,
        message: message || rule.id,
        source: 'client'
      })
    }
  }
  return found
}

function interpolate (template, vars) {
  return Object.entries(vars).reduce((text, [name, value]) => text.replaceAll(`%{${name}}`, () => String(value)), String(template))
}

// Issues computed by the server (the document's `issues`) next to the
// client's. Server rules the client also knows are not repeated, and an issue
// about an element deleted since the last save is gone with it.
export function mergeIssues (client, server, doc = null) {
  const seen = new Set(client.map((i) => `${i.rule}:${i.element_id}`))
  const exists = doc
    ? new Set([...(doc.nodes || []), ...(doc.edges || []), ...(doc.lanes || [])].map((e) => String(e.id)))
    : null
  const fromServer = (server || []).filter((i) => !seen.has(`${i.rule}:${i.element_id ?? null}`))
    .filter((i) => !exists || i.element_id == null || exists.has(String(i.element_id))).map((i) => ({
      rule: String(i.rule), element_id: i.element_id == null ? null : String(i.element_id), severity: i.severity === 'warning' ? 'warning' : 'error', message: i.message || String(i.rule), source: 'server'
    }))
  return [...client, ...fromServer]
}

// Element id → the worst severity on it, for the canvas markers.
export function issuesByElement (issues) {
  const map = new Map()
  for (const issue of issues) {
    if (issue.element_id == null) continue
    if (map.get(issue.element_id) !== 'error') map.set(issue.element_id, issue.severity)
  }
  return map
}

export const hasErrors = (issues) => issues.some((i) => i.severity === 'error')

// What the editor refuses on the spot, derived from the rules that are on:
// turning a rule off also lifts the block that enforces it.
export function blockPolicy (config) {
  return {
    oneInOneOut: isRuleOn(config, 'R01') || isRuleOn(config, 'R02'),
    // The editor's local arrangement moves the next elements along instead
    // of refusing an overlap; R18 still reports one the host's data brings.
    noOverlap: false,
    insideLane: isRuleOn(config, 'R26'),
    minLanes: isRuleOn(config, 'R21') ? ruleOption(config, 'min_lanes', 2) : 0,
    messageFlowParticipants: isRuleOn(config, 'B02'),
    associationArtifact: isRuleOn(config, 'B03'),
    noSequenceOnArtifacts: isRuleOn(config, 'B04')
  }
}
