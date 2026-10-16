// The issue's catalogue (#1489): R01–R26, numbered as the issue lists them so
// a host can name them in `rules:`.
import { isActivity, isGateway, isFlowNode, edgeType } from '../../catalog.js'
import { insideLane, nodeBox, boxesOverlap } from '../../geometry.js'
import { wordsOf } from '../../wording.js'
import { words, isJoin, isSplit, kind, generic, each } from '../helpers.js'

export const ISSUE_RULES = [
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
  }
]
