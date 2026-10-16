// AFAL's guidelines (Criterios BPMN Rev.01, origin «Lineamiento AFAL»): rules
// a host that follows AFAL's matrix adds; BPMN 2.0 does not ask for them. They
// reach the editor only through the optional package
// `bali-view-components/bpmn-editor/afal-rules`, which registers them
// (registerBpmnRule): the central catalogue never lists them.
import { isActivity, isBinaryDecision } from '../catalog.js'
import { pageFit } from '../page.js'
import { plain, wordsOf, startsWith, contains, isInfinitive, isNominal, actionsIn, sameParticipant } from '../wording.js'
import { words, isDecision, each } from './helpers.js'
import { END_KEYS, LANE, SEQUENCE_FLOW, TASK_KEYS, byType } from './applies.js'

export const AFAL_RULES = [
  {
    // A return to an earlier point (a back edge) lands on a merging XOR placed
    // before the first repeated activity — never on the activity itself nor
    // on an AND.
    id: 'COM-22',
    section: 'gateways',
    criteria: ['ACT-13', 'COM-22', 'EST-04'],
    severity: 'error',
    appliesTo: SEQUENCE_FLOW,
    source: 'AFAL ACT-13, COM-22, EST-04',
    check: (_doc, ctx) => [...ctx.structure.back].flatMap((e) => {
      const target = ctx.byId.get(String(e.target))
      if (!target || (target.type === 'exclusive_gateway' && !isBinaryDecision(target) && ctx.inc(target).length > 1)) return []
      return [{ element_id: e.id, vars: { name: ctx.name(target) } }]
    })
  },
  {
    id: 'EVF-04',
    section: 'end_events',
    criteria: ['EVF-04'],
    severity: 'error',
    appliesTo: END_KEYS,
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
    severity: 'error',
    appliesTo: byType('sub_process'),
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
    // The diagram on its sheet: legible when its 11 px text prints at 6 pt or
    // more (model/page.js). A warning — a large process may not fit, and the
    // compact layout or a split into related procedures is the way out.
    id: 'VIS-02',
    section: 'layout',
    criteria: ['VIS-02', 'VIS-08'],
    severity: 'warning',
    appliesTo: LANE,
    source: 'AFAL VIS-02; AFAL VIS-08',
    check: (doc, ctx) => {
      if (!(doc.nodes || []).length) return []
      const fit = pageFit(doc, ctx.page)
      return fit.fits ? [] : [{ element_id: null, vars: { scale: Math.round(fit.scale * 100), min: Math.round(fit.minScale * 100) } }]
    }
  },
  {
    // Infinitive + object ("Validate the documents"), not a noun phrase
    // ("Validation of documents").
    id: 'ACT-02',
    section: 'activities',
    criteria: ['ACT-02'],
    severity: 'warning',
    appliesTo: TASK_KEYS,
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
    severity: 'warning',
    appliesTo: TASK_KEYS,
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
    severity: 'warning',
    appliesTo: TASK_KEYS,
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
    severity: 'warning',
    appliesTo: TASK_KEYS,
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
    severity: 'warning',
    appliesTo: TASK_KEYS,
    source: 'AFAL ACT-10, ACT-11, ACT-12',
    check: (_doc, ctx) => {
      const verbs = ctx.plainList('decision_verbs')
      return each(ctx.nodes, (n) => isActivity(n) && n.type !== 'sub_process' && startsWith(n.name, verbs) && ctx.out(n).length > 0 &&
        !ctx.out(n).some((e) => { const next = ctx.byId.get(String(e.target)); return next && isDecision(ctx, next) }),
      (n) => ({ element_id: n.id, vars: { name: ctx.name(n) } }))
    }
  },
  {
    id: 'LAN-08',
    section: 'lanes',
    criteria: ['LAN-08'],
    severity: 'warning',
    appliesTo: LANE,
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
