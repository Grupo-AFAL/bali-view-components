// Property tests: random editing sessions from fixed seeds. After EVERY
// operation (followed by the incremental arrangement the editor runs) the
// hard layout constraints must hold. A failure prints the seed and the
// shortest sequence of operations that still reproduces it.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import * as ops from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { arrange, gapsLeftBy } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { measure } from '../../../app/components/bali/bpmn_editor/model/layoutQuality.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { layoutLanes, nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { isActivity, isGateway } from '../../../app/components/bali/bpmn_editor/model/catalog.js'

const SEQUENCES = Number(process.env.BPMN_SEQUENCES || 200)
const STEPS = Number(process.env.BPMN_STEPS || 30)
// As in the editor: the local arrangement resolves overlaps instead of refusing them.
const POLICY = { ...ops.DEFAULT_POLICY, noOverlap: false }
const NAMES = { task: 'Task', gateway: 'Decision?', start: 'Begin', end: 'Done', event: 'Wait', sub_process: 'Sub' }
const LABELS = { yes: 'Yes', no: 'No' }

function rng (seed) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6D2B79F5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const pick = (random, list) => list[Math.floor(random() * list.length)]

export function seedDoc (orientation) {
  return normalize({
    version: 1,
    orientation,
    lanes: [
      { id: 'l1', name: 'Customer', kind: 'external', order: 1 },
      { id: 'l2', name: 'Sales', order: 2 },
      { id: 'l3', name: 'Billing', order: 3 }
    ],
    nodes: [
      { id: 'c1', type: 'task', lane_id: 'l1', name: 'Place order' },
      { id: 's', type: 'start_event', lane_id: 'l2', name: 'Order in' },
      { id: 't', type: 'task', lane_id: 'l2', name: 'Check order' },
      { id: 'e', type: 'end_event', lane_id: 'l3', name: 'Order done' }
    ],
    edges: [
      { id: 'm', type: 'message_flow', source: 'c1', target: 's' },
      { id: 'f1', source: 's', target: 't' }, { id: 'f2', source: 't', target: 'e' }
    ]
  })
}

const TYPES = [{ type: 'task' }, { type: 'exclusive_gateway' }, { type: 'parallel_gateway' }, { type: 'intermediate_catch_event', event_definition: { kind: 'timer' } }, { type: 'end_event' }, { type: 'user_task' }]

// One random operation, described so it can be replayed: [name, ...args].
function randomOp (random, doc) {
  const nodes = doc.nodes
  const kind = random()
  if (kind < 0.35 && nodes.length) {
    return ['append', pick(random, nodes).id, pick(random, TYPES), pick(random, ['right', 'right', 'down', 'up', 'left'])]
  }
  if (kind < 0.5 && doc.edges.length) {
    const edge = pick(random, doc.edges.filter((e) => !e.type || e.type === 'sequence_flow'))
    return edge ? ['insert', edge.id, pick(random, [{ type: 'task' }, { type: 'exclusive_gateway' }])] : ['noop']
  }
  if (kind < 0.6) {
    const layout = layoutLanes(doc)
    const entry = pick(random, layout.entries)
    const along = layout.header + 40 + random() * (layout.length - 80)
    const across = entry.offset + 20 + random() * (entry.size - 40)
    const point = layout.axis.main === 'y' ? { x: along, y: across } : { x: across, y: along }
    return ['drop', pick(random, TYPES), Math.round(point.x), Math.round(point.y)]
  }
  if (kind < 0.7 && nodes.length > 3) return ['delete', pick(random, nodes).id]
  if (kind < 0.8 && nodes.length) {
    const layout = layoutLanes(doc)
    const node = pick(random, nodes)
    const entry = pick(random, layout.entries)
    const box = nodeBox(node)
    const center = layout.axis.main === 'y' ? box.cy : box.cx
    const delta = entry.offset + entry.size / 2 - center
    return ['move', node.id, layout.axis.main === 'y' ? { x: 0, y: Math.round(delta) } : { x: Math.round(delta), y: 0 }]
  }
  if (kind < 0.9) {
    // A branch or a loop: from a gateway to any node, or back to a gateway.
    const gateways = nodes.filter(isGateway)
    if (!gateways.length) return ['noop']
    return random() < 0.5
      ? ['connect', pick(random, gateways).id, pick(random, nodes).id, 'sequence_flow']
      : ['connect', pick(random, nodes.filter((n) => isActivity(n) || isGateway(n))).id, pick(random, gateways).id, 'sequence_flow']
  }
  const external = nodes.filter((n) => n.lane_id === 'l1')
  const internal = nodes.filter((n) => n.lane_id !== 'l1' && (isActivity(n) || n.type === 'start_event'))
  if (external.length && internal.length) return ['connect', pick(random, external).id, pick(random, internal).id, 'message_flow']
  return ['noop']
}

export function apply (doc, op) {
  const [name, ...args] = op
  let result = null
  if (name === 'append') result = ops.appendNode(doc, args[0], args[1], args[2], { policy: POLICY, names: NAMES, labels: LABELS })
  if (name === 'insert') result = ops.insertOnEdge(doc, args[0], args[1], (() => { const r = routeAll(doc).get(String(args[0])); return r ? r.label : { x: 0, y: 0 } })(), { policy: POLICY, names: NAMES })
  if (name === 'drop') result = ops.createNode(doc, args[0], { x: args[1], y: args[2] }, { policy: POLICY, names: NAMES })
  if (name === 'delete') result = ops.deleteElements(doc, { nodeIds: [args[0]] }, { policy: POLICY })
  if (name === 'move') result = ops.moveNodes(doc, [args[0]], args[1], { policy: POLICY })
  if (name === 'connect') result = ops.connect(doc, args[0], args[1], { type: args[2], policy: POLICY, labels: LABELS })
  if (!result || result.error) return doc
  return arrange(result.doc, { before: doc })
}

// A hard constraint broken, or a deletion that left a stretch wider than a
// column empty in every lane.
function violation (before, doc) {
  const m = measure(doc)
  const gaps = gapsLeftBy(before, doc)
  if (gaps.length) return { ...m, details: [['gapLeftByDelete', ...gaps.map((g) => `${Math.round(g.from)}–${Math.round(g.to)}`)]] }
  return m.hard ? m : null
}

function run (orientation, sequence) {
  let doc = seedDoc(orientation)
  for (let i = 0; i < sequence.length; i++) {
    const before = doc
    doc = apply(doc, sequence[i])
    const failed = violation(before, doc)
    if (failed) return { index: i, failed, doc }
  }
  return null
}

// Drops operations one at a time while the run still fails.
function shrink (orientation, sequence) {
  let current = sequence
  let changed = true
  while (changed) {
    changed = false
    for (let i = 0; i < current.length; i++) {
      const candidate = [...current.slice(0, i), ...current.slice(i + 1)]
      if (run(orientation, candidate)) { current = candidate; changed = true; break }
    }
  }
  return current
}

for (const orientation of ['horizontal', 'vertical']) {
  test(`${SEQUENCES / 2} random editing sessions (${orientation}) keep every hard constraint`, () => {
    for (let seed = 1; seed <= SEQUENCES / 2; seed++) {
      const random = rng(seed * (orientation === 'horizontal' ? 1 : 7919))
      let doc = seedDoc(orientation)
      const sequence = []
      for (let step = 0; step < STEPS; step++) {
        const op = randomOp(random, doc)
        sequence.push(op)
        const before = doc
        doc = apply(doc, op)
        const failed = violation(before, doc)
        if (failed) {
          const minimal = shrink(orientation, sequence)
          const replay = run(orientation, minimal)
          assert.fail(`seed ${seed} (${orientation}) breaks a hard constraint at step ${step}.\n` +
            `minimal sequence: ${JSON.stringify(minimal)}\n` +
            `violations: ${JSON.stringify((replay || { failed }).failed.details.slice(0, 6))}`)
        }
      }
    }
  })
}
