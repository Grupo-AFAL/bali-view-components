// The rules of AFAL's BPMN criteria matrix (Criterios BPMN Rev.01) that the
// matrix grounds in BPMN 2.0, named after a criterion code. `criteria` lists
// the codes a rule covers and `section` the matrix's chapter, which the
// «Rules» dialog groups by. The AFAL-only guidelines are not here: they ship
// in the optional bpmn-editor/afal-rules package (rules/afal.js).
import { isGateway, isFlowNode, isBinaryDecision, paletteKeyFor } from '../../catalog.js'
import { wordsOf, contains, isInfinitive } from '../../wording.js'
import { words, isJoin, isSplit, kind, CLOSING, externalLanes, each, say } from '../helpers.js'
import { END_KEYS, FLOW_NODE_KEYS, GATEWAY_KEYS, NODE_KEYS, START_KEYS, YES_NO_KEYS, byKind, byType } from '../applies.js'

export const CRITERIA_RULES = [
  {
    // Each merge closes the split that opened its paths with the matching
    // gateway: Yes/No → XOR, XOR → XOR, OR → OR, AND → AND. The opening is
    // the merge's immediate dominator (flowStructure.js); a merge on a
    // rework loop is COM-22's.
    id: 'COM-19',
    section: 'gateways',
    criteria: ['COM-15', 'COM-16', 'COM-17', 'COM-18', 'COM-19'],
    severity: 'error',
    appliesTo: GATEWAY_KEYS,
    source: 'ORG COM-15; BPMN 2.0, ORG COM-16, COM-17, COM-19; BPMN 2.0 COM-18',
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
    appliesTo: GATEWAY_KEYS,
    source: 'BPMN 2.0, ORG COM-20',
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
    appliesTo: byType('parallel_gateway'),
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
    appliesTo: YES_NO_KEYS,
    source: 'ORG COM-02, COM-07',
    check: (_doc, ctx) => each(ctx.nodes, (n) => isBinaryDecision(n) && !isJoin(ctx, n) && ctx.out(n).length !== 2, (n) => ({ element_id: n.id, vars: { name: ctx.name(n), count: ctx.out(n).length } }))
  },
  {
    id: 'DEC-03',
    section: 'decisions',
    criteria: ['DEC-03'],
    severity: 'warning',
    appliesTo: YES_NO_KEYS,
    source: 'ORG DEC-03',
    check: (_doc, ctx) => each(ctx.nodes,
      (n) => isBinaryDecision(n) && ctx.out(n).length === 2 && ctx.out(n).every((e) => words(e.label)) &&
        !ctx.out(n).every((e) => [ctx.yes, ctx.no].includes(words(e.label))),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n), yes: say(ctx, 'label_yes'), no: say(ctx, 'label_no') } }))
  },
  {
    // Every cycle has a way out: some element of it leads outside it.
    id: 'EST-05',
    section: 'structure',
    criteria: ['EST-05'],
    severity: 'error',
    appliesTo: FLOW_NODE_KEYS,
    source: 'BPMN 2.0, ORG EST-05',
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
    appliesTo: FLOW_NODE_KEYS,
    source: 'BPMN 2.0, ORG EST-01, EVF-01; ORG EST-02, SEC-04',
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
    // A diagram brought in with elements the host's palette does not offer.
    id: 'VIS-10',
    section: 'layout',
    criteria: ['EVM-01', 'VIS-10'],
    severity: 'error',
    appliesTo: NODE_KEYS,
    source: 'ORG EVM-01; BPMN 2.0, ORG VIS-10',
    check: (_doc, ctx) => (ctx.allowed
      ? each(ctx.nodes, (n) => { const key = paletteKeyFor(n); return key && !ctx.allowed.has(key) }, (n) => ({ element_id: n.id, vars: { name: ctx.name(n), kind: say(ctx, `palette_${paletteKeyFor(n)}`) } }))
      : [])
  },
  {
    // A start, end or conditional event names a fact or a state, not an action.
    id: 'EVI-03',
    section: 'start_events',
    criteria: ['EVI-03', 'EVF-03', 'EVM-09'],
    severity: 'warning',
    appliesTo: [...START_KEYS, ...END_KEYS, ...byKind(['intermediate_catch_event'], ['conditional'])],
    source: 'BPMN 2.0, ORG EVI-03, EVF-03, EVM-09',
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
    appliesTo: byKind(['start_event'], [null]),
    source: 'BPMN 2.0, ORG EVI-05',
    check: (_doc, ctx) => {
      const periodic = ctx.plainList('periodic_words')
      return each(ctx.nodes, (n) => n.type === 'start_event' && !kind(n) && contains(n.name, periodic), (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  }
]
