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
// A rule never blocks saving: issues are what "Finalize" checks. The blocks
// that stop an edit on the spot are blockPolicy() below.
import { isActivity, isGateway, isEvent, isArtifactLike, isFlowNode, edgeType } from './catalog.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from './geometry.js'

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

function context (doc, config, t) {
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
  return {
    doc,
    nodes,
    byId,
    flows,
    layout: layoutLanes(doc),
    inc: (node) => incoming.get(String(node.id)) || [],
    out: (node) => outgoing.get(String(node.id)) || [],
    option: (key, fallback) => ruleOption(config, key, fallback),
    list: (key) => (t && t.words ? t.words(key) : []),
    name: (node) => (node && String(node.name || '').trim()) || (t ? t('unnamed') : ''),
    yes: words(t ? t('label_yes') : 'yes'),
    no: words(t ? t('label_no') : 'no')
  }
}

// ── catalogue ──────────────────────────────────────────────────────────────

const each = (list, test, build) => list.filter(test).map(build)

export const CATALOG = [
  {
    id: 'R01',
    severity: 'error',
    source: 'bpmnlint: fake-join; Method and Style',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isActivity(n) && ctx.inc(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R02',
    severity: 'error',
    source: 'bpmnlint: no-implicit-split; Method and Style',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isActivity(n) && ctx.out(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R03',
    severity: 'error',
    source: 'Method and Style: label the gates of a split; bpmnlint: conditional-flows',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => (n.type === 'exclusive_gateway' || n.type === 'inclusive_gateway') && isSplit(ctx, n) && ctx.out(n).some((e) => !words(e.label)),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R04',
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
    severity: 'error',
    source: 'Method and Style: a parallel or inclusive split is merged by a gateway of its type',
    check: (_doc, ctx) => each(ctx.nodes, (n) => {
      if ((n.type !== 'parallel_gateway' && n.type !== 'inclusive_gateway') || !isSplit(ctx, n)) return false
      const seen = new Set()
      const stack = ctx.out(n).map((e) => String(e.target))
      while (stack.length) {
        const id = stack.pop()
        if (seen.has(id)) continue
        seen.add(id)
        const next = ctx.byId.get(id)
        if (!next) continue
        if (next.type === n.type && ctx.inc(next).length > 1) return false
        for (const e of ctx.out(next)) stack.push(String(e.target))
      }
      return true
    }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R06',
    severity: 'error',
    source: 'Camunda modeling guidelines: name start events after their trigger',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'start_event' && generic(n.name, ctx.list('generic_start_names')), (n) => ({ element_id: n.id }))
  },
  {
    id: 'R07',
    severity: 'error',
    source: 'Camunda modeling guidelines: name end events after the end state',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'end_event' && generic(n.name, ctx.list('generic_end_names')), (n) => ({ element_id: n.id }))
  },
  {
    // A merging gateway carries no decision to describe, so it is exempt.
    id: 'R08',
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => (isEvent(n) || (isGateway(n) && !isJoin(ctx, n))) && words(n.name) && !words(n.documentation),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    // bpmnlint's label-required, minus merging gateways: the guidelines leave joins unnamed.
    id: 'R09',
    severity: 'error',
    source: 'bpmnlint: label-required',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isFlowNode(n) && !(isGateway(n) && isJoin(ctx, n)) && !words(n.name), (n) => ({ element_id: n.id }))
  },
  {
    id: 'R10',
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => each(ctx.doc.lanes || [],
      (l) => !ctx.nodes.some((n) => String(n.lane_id) === String(l.id) && isActivity(n)),
      (l) => ({ element_id: l.id, vars: { name: l.name || '' } }))
  },
  {
    id: 'R11',
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'sub_process' && !(n.reference && n.reference.id), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R12',
    severity: 'error',
    source: 'bpmnlint: start-event-required, end-event-required',
    check: (_doc, ctx) => (ctx.nodes.some((n) => n.type === 'start_event') && ctx.nodes.some((n) => n.type === 'end_event') ? [] : [{ element_id: null }])
  },
  {
    // A link catch has no incoming flow and a link throw no outgoing one by
    // design (BPMN 2.0 §10.5.5). An external participant is another process
    // drawn as a lane: a message flow is how its elements connect.
    id: 'R13',
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
    severity: 'error',
    source: 'bpmnlint: no-gateway-join-fork',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isGateway(n) && ctx.inc(n).length > 1 && ctx.out(n).length > 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R15',
    severity: 'warning',
    source: 'bpmnlint: superfluous-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isGateway(n) && ctx.inc(n).length === 1 && ctx.out(n).length === 1, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R16',
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
    severity: 'warning',
    source: 'Camunda modeling guidelines: activities as verb + object',
    check: (_doc, ctx) => {
      const verbs = ctx.list('vague_verbs')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && verbs.includes(words(n.name)), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'R18',
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
    severity: 'warning',
    source: 'Method and Style: hierarchical modelling',
    check: (_doc, ctx) => {
      const count = ctx.nodes.filter(isActivity).length
      return count > ctx.option('max_activities', 25) ? [{ element_id: null, vars: { count } }] : []
    }
  },
  {
    id: 'R20',
    severity: 'error',
    source: '#1489 (optional)',
    check: (_doc, ctx) => {
      const min = ctx.option('min_activities', 2)
      return ctx.nodes.filter(isActivity).length < min ? [{ element_id: null, vars: { count: min } }] : []
    }
  },
  {
    id: 'R21',
    severity: 'error',
    source: '#1489',
    check: (_doc, ctx) => {
      const min = ctx.option('min_lanes', 2)
      const current = (ctx.doc.lanes || []).length
      return current < min ? [{ element_id: null, vars: { count: min, current } }] : []
    }
  },
  {
    id: 'R22',
    severity: 'error',
    source: 'Camunda modeling guidelines: name lanes after their role',
    check: (_doc, ctx) => each(ctx.doc.lanes || [], (l) => !words(l.name) || generic(l.name, ctx.list('generic_lane_names')), (l) => ({ element_id: l.id }))
  },
  {
    id: 'R23',
    severity: 'error',
    source: 'Camunda modeling guidelines: specific names',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => (isActivity(n) && generic(n.name, ctx.list('generic_task_names'))) || (isGateway(n) && generic(n.name, ctx.list('generic_gateway_names'))),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'R24',
    severity: 'error',
    source: 'BPMN 2.0 §10.5.2 and §10.5.3',
    check: (_doc, ctx) => [
      ...each(ctx.nodes, (n) => n.type === 'start_event' && ctx.inc(n).length > 0, (n) => ({ element_id: n.id, key: 'in', vars: { name: ctx.name(n) } })),
      ...each(ctx.nodes, (n) => n.type === 'end_event' && ctx.out(n).length > 0, (n) => ({ element_id: n.id, key: 'out', vars: { name: ctx.name(n) } }))
    ]
  },
  {
    id: 'R25',
    severity: 'error',
    source: 'BPMN 2.0 §8.4.13 (sourceRef and targetRef)',
    check: (_doc, ctx) => each(ctx.doc.edges || [], (e) => !ctx.byId.has(String(e.source)) || !ctx.byId.has(String(e.target)), (e) => ({ element_id: e.id }))
  },
  {
    id: 'R26',
    severity: 'error',
    source: 'BPMN 2.0 §10.8 (lanes partition the flow elements)',
    check: (_doc, ctx) => (ctx.layout.entries.length
      ? each(ctx.nodes, (n) => isFlowNode(n) && !insideLane(ctx.layout, n), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
      : [])
  },
  {
    id: 'B01',
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
    severity: 'warning',
    source: 'BPMN 2.0 §8.4.13 (sequence flows join flow nodes)',
    check: (_doc, ctx) => ctx.flows.flatMap((e) => [ctx.byId.get(String(e.source)), ctx.byId.get(String(e.target))])
      .filter((n) => n && isArtifactLike(n))
      .map((n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B05',
    severity: 'warning',
    source: 'BPMN 2.0 §10.5.5; bpmnlint: link-event',
    check: (_doc, ctx) => {
      const links = ctx.nodes.filter((n) => kind(n) === 'link')
      return each(links, (n) => !links.some((m) => m.type !== n.type && words(m.name) === words(n.name)), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'B06',
    severity: 'warning',
    source: 'BPMN 2.0 §10.5.3 (error and cancel end events need a boundary to catch them)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'end_event' && (kind(n) === 'error' || kind(n) === 'cancel'), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B07',
    severity: 'warning',
    source: 'bpmnlint: no-complex-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'complex_gateway', (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B08',
    severity: 'warning',
    source: 'bpmnlint: single-blank-start-event',
    check: (_doc, ctx) => ctx.nodes.filter((n) => n.type === 'start_event' && !kind(n)).slice(1).map((n) => ({ element_id: n.id }))
  },
  {
    id: 'B09',
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
    severity: 'warning',
    source: 'BPMN 2.0 §10.6.6 (instantiating event-based gateway)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'event_based_gateway' && n.instantiate && ctx.inc(n).length > 0, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B11',
    severity: 'warning',
    source: 'Camunda modeling guidelines: label exclusive gateways as questions',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'exclusive_gateway' && isSplit(ctx, n) && words(n.name) && !/\?\s*$/.test(String(n.name).trim()), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  }
]

// Rules on by default: the issue's standard catalogue and the BPMN structure
// rules. Off: the issue's optional ones (R12, R14–R17, R19), R04 and R20 (domain
// conventions) and the stylistic B07 and B11.
export const DEFAULT_ENABLED = new Set([
  'R01', 'R02', 'R03', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R13', 'R18', 'R21',
  'R22', 'R23', 'R24', 'R25', 'R26', 'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B08', 'B09', 'B10'
])

export function isRuleOn (config, id) {
  const disabled = (config && config.disabled) || []
  const enabled = (config && config.enabled) || []
  if (disabled.includes(id)) return false
  return DEFAULT_ENABLED.has(id) || enabled.includes(id) || registry.has(id)
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
    id: rule.id, source: rule.source, title: rule.title, on: isRuleOn(config, rule.id), severity: severityOf(config, rule)
  }))
}

// Issues of a document: [{ rule, element_id, severity, message, source }].
export function evaluate (doc, config = {}, t = null) {
  const ctx = context(doc, config, t)
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
    noOverlap: isRuleOn(config, 'R18'),
    insideLane: isRuleOn(config, 'R26'),
    minLanes: isRuleOn(config, 'R21') ? ruleOption(config, 'min_lanes', 2) : 0,
    messageFlowParticipants: isRuleOn(config, 'B02'),
    associationArtifact: isRuleOn(config, 'B03'),
    noSequenceOnArtifacts: isRuleOn(config, 'B04')
  }
}
