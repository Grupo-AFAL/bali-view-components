// BPMN 2.0 structure and readability (B01–B11), drawn from the OMG
// specification, bpmnlint and the Camunda modeling guidelines; warnings, the
// more opinionated ones off by default.
import { isArtifactLike, edgeType } from '../../catalog.js'
import { wordsOf, isInfinitive } from '../../wording.js'
import { words, kind, isDecision, each } from '../helpers.js'
import { ARTIFACT_KEYS, INSTANTIATING_GATEWAY_KEYS, ASSOCIATION, DECISION_KEYS, MESSAGE_FLOW, SEQUENCE_FLOW, byKind, byType } from '../applies.js'

export const STRUCTURE_RULES = [
  {
    id: 'B01',
    section: 'gateways',
    severity: 'warning',
    appliesTo: byType('event_based_gateway'),
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
    appliesTo: MESSAGE_FLOW,
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
    appliesTo: ASSOCIATION,
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
    appliesTo: ARTIFACT_KEYS,
    source: 'BPMN 2.0 §8.4.13 (sequence flows join flow nodes)',
    check: (_doc, ctx) => ctx.flows.flatMap((e) => [ctx.byId.get(String(e.source)), ctx.byId.get(String(e.target))])
      .filter((n) => n && isArtifactLike(n))
      .map((n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B05',
    section: 'intermediate_events',
    severity: 'warning',
    appliesTo: byKind(['intermediate_catch_event', 'intermediate_throw_event'], ['link']),
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
    appliesTo: byKind(['end_event'], ['error', 'cancel']),
    source: 'BPMN 2.0 §10.5.3 (error and cancel end events need a boundary to catch them)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'end_event' && (kind(n) === 'error' || kind(n) === 'cancel'), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B07',
    section: 'gateways',
    severity: 'warning',
    appliesTo: byType('complex_gateway'),
    source: 'bpmnlint: no-complex-gateway',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'complex_gateway', (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B08',
    section: 'start_events',
    severity: 'warning',
    appliesTo: byKind(['start_event'], [null]),
    source: 'bpmnlint: single-blank-start-event',
    check: (_doc, ctx) => ctx.nodes.filter((n) => n.type === 'start_event' && !kind(n)).slice(1).map((n) => ({ element_id: n.id }))
  },
  {
    id: 'B09',
    section: 'sequence_flows',
    severity: 'warning',
    appliesTo: SEQUENCE_FLOW,
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
    appliesTo: INSTANTIATING_GATEWAY_KEYS,
    source: 'BPMN 2.0 §10.6.6 (instantiating event-based gateway)',
    check: (_doc, ctx) => each(ctx.nodes, (n) => n.type === 'event_based_gateway' && n.instantiate && ctx.inc(n).length > 0, (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
  },
  {
    id: 'B11',
    section: 'decisions',
    criteria: ['COM-13', 'DEC-01'],
    severity: 'warning',
    appliesTo: DECISION_KEYS,
    // A decision (exclusive, Yes/No or inclusive split) is phrased as a
    // question, and is no activity: a question that starts with a verb in
    // the infinitive ("Authorize request?") still names work.
    source: 'Camunda modeling guidelines: label exclusive gateways as questions; BPMN 2.0, AFAL COM-13; AFAL DEC-01',
    check: (_doc, ctx) => ctx.nodes.filter((n) => isDecision(ctx, n) && words(n.name)).flatMap((n) => {
      const vars = { name: ctx.name(n) }
      if (isInfinitive(wordsOf(n.name)[0], ctx.verbs())) return [{ element_id: n.id, key: 'verb', vars }]
      return /\?\s*$/.test(String(n.name).trim()) ? [] : [{ element_id: n.id, vars }]
    })
  }
]
