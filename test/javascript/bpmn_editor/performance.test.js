// What keeps editing a large flow fast: the compact layout arranges only the
// candidates that can decide it, and a document is routed once — again
// neither when the editor draws what arrange settled on, nor per keystroke of
// a rename that moves nothing.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { FIXTURES, large } from './fixtures.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { arrange, place } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { pageFit } from '../../../app/components/bali/bpmn_editor/model/page.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { routeAfresh, sameRouting } from '../../../app/components/bali/bpmn_editor/model/router.js'
import { updateNode, updateEdge } from '../../../app/components/bali/bpmn_editor/model/operations.js'

const median = (run) => {
  run()
  const runs = []
  for (let i = 0; i < 5; i++) {
    const started = performance.now()
    run()
    runs.push(performance.now() - started)
  }
  return runs.sort((a, b) => a - b)[2]
}

// Arranging all ~90 candidates took ~9 s; bounded, ~0.1 s locally.
test('the compact layout of an 80-activity flow takes well under a second', () => {
  const ms = median(() => autoLayout(large(80), { mode: 'compact' }))
  assert.ok(ms < 1000, `median ${ms.toFixed(0)} ms`)
})

// The bound layout.js prunes candidates with: routing only ever moves
// elements forward along the flow, so the arranged document never fits the
// page larger than the placed one.
test('arranging never fits the page larger than placing alone', () => {
  let seed = 3
  const random = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff }
  for (const [name, make] of Object.entries(FIXTURES)) {
    const doc = normalize(make())
    for (let k = 0; k < 4; k++) {
      const moved = { ...doc, nodes: doc.nodes.map((n) => (random() < 0.3 ? { ...n, x: Math.round(n.x + (random() - 0.5) * 300), y: Math.round(n.y + (random() - 0.6) * 120) } : n)) }
      const arranged = pageFit(arrange(moved)).scale
      const placed = pageFit(place(moved)).scale
      assert.ok(arranged <= placed, `${name} #${k}: ${arranged} > ${placed}`)
    }
  }
})

test('the document arrange settles on is not routed again to be drawn', () => {
  const doc = normalize(FIXTURES.rework())
  const settled = arrange({ ...doc, nodes: doc.nodes.map((n, i) => (i === 1 ? { ...n, x: n.x + 37 } : n)) })
  assert.equal(routeAll(settled), routeAll(settled))
  assert.deepEqual(routeAll(settled), routeAfresh(settled))
})

// Every name typed into every element of every fixture, letter by letter:
// whenever the routes are reused, routing afresh gives the same ones.
test('a rename reuses the routes only when routing it afresh gives the same ones', () => {
  let reused = 0
  let rerouted = 0
  for (const make of Object.values(FIXTURES)) {
    const doc = normalize(make())
    const before = routeAfresh(doc)
    for (const node of doc.nodes) {
      for (const name of ['', 'A', 'Approve', `${node.name || ''}x`, 'Approve the purchase order and notify the requester']) {
        const renamed = updateNode(doc, node.id, { name }).doc
        if (sameRouting(doc, renamed)) {
          reused++
          assert.deepEqual(routeAfresh(renamed), before, `${node.id} → «${name}»`)
        } else {
          rerouted++
        }
      }
    }
  }
  assert.ok(reused > 0 && rerouted > 0, `${reused} reused, ${rerouted} rerouted`)
})

test('typing a task name or a connection label does not route again; an event name that wraps does', () => {
  const doc = normalize(FIXTURES.invoice())
  const task = doc.nodes.find((n) => n.type === 'task')
  const event = doc.nodes.find((n) => n.type === 'start_event')
  const edge = doc.edges[0]
  const routes = routeAll(doc)
  const typed = updateNode(doc, task.id, { name: `${task.name} and more` }).doc
  assert.equal(routeAll(typed), routes)
  const labelled = updateEdge(typed, edge.id, { label: 'Approved' }).doc
  assert.equal(routeAll(labelled), routes)
  const wrapped = updateNode(labelled, event.id, { name: 'A much longer name for this event, on three lines' }).doc
  assert.equal(sameRouting(labelled, wrapped), false)
  assert.deepEqual(routeAll(wrapped), routeAfresh(wrapped))
})

test('a move is never taken for a rename', () => {
  const doc = normalize(FIXTURES.parallel())
  const node = doc.nodes[2]
  assert.equal(sameRouting(doc, updateNode(doc, node.id, { x: node.x + 10 }).doc), false)
  assert.ok(doc.lanes.length > 0)
  assert.equal(sameRouting(doc, { ...doc, lanes: doc.lanes.map((l, i) => (i ? l : { ...l, size: l.size + 40 })) }), false)
})
