import { test } from 'node:test'
import assert from 'node:assert/strict'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { evaluate } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import * as ops from '../../../app/components/bali/bpmn_editor/model/operations.js'

// The shape of the dummy's BpmnSampleFlows.large: a chain of 60 activities
// over four lanes with a decision every six steps, no coordinates.
function large () {
  const lanes = ['Requester', 'Purchasing', 'Warehouse', 'Finance'].map((name, i) => ({ id: `l${i + 1}`, name, order: i + 1 }))
  const nodes = [{ id: 'start', type: 'start_event', lane_id: 'l1', name: 'Need detected', documentation: 'Any area.' }]
  const edges = []
  let previous = 'start'
  for (let step = 1; step <= 60; step++) {
    const lane = `l${((step - 1) % 4) + 1}`
    nodes.push({ id: `t${step}`, type: 'task', lane_id: lane, name: `Purchase step ${step}` })
    edges.push({ id: `f${step}`, source: previous, target: `t${step}`, label: previous.startsWith('g') ? 'Yes' : undefined })
    previous = `t${step}`
    if (step % 6 === 0 && step < 60) {
      nodes.push({ id: `g${step}`, type: 'exclusive_gateway', lane_id: lane, name: `Step ${step} approved?`, documentation: '…' })
      nodes.push({ id: `x${step}`, type: 'end_event', lane_id: lane, name: `Cancelled at ${step}`, documentation: '…' })
      edges.push({ id: `f${step}-g`, source: `t${step}`, target: `g${step}` }, { id: `f${step}-no`, source: `g${step}`, target: `x${step}`, label: 'No' })
      previous = `g${step}`
    }
  }
  nodes.push({ id: 'end', type: 'end_event', lane_id: 'l4', name: 'Purchase closed', documentation: '…' })
  edges.push({ id: 'f-end', source: previous, target: 'end' })
  return { version: 1, lanes, nodes, edges }
}

test('a 60-activity flow lays out inside its lanes without overlaps and passes the rules', () => {
  const started = performance.now()
  const doc = normalize(large())
  const layout = layoutLanes(doc)
  for (const n of doc.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
  for (let i = 0; i < doc.nodes.length; i++) {
    for (let j = i + 1; j < doc.nodes.length; j++) assert.equal(boxesOverlap(nodeBox(doc.nodes[i]), nodeBox(doc.nodes[j])), false)
  }
  assert.equal(routeAll(doc).size, doc.edges.length)
  assert.deepEqual(evaluate(doc, {}, translator({})), [])
  assert.ok(performance.now() - started < 1500)
})

test('R19 flags it once the host sets a size threshold', () => {
  const issues = evaluate(normalize(large()), { enabled: ['R19'], options: { max_activities: 40 } }, translator({}))
  assert.deepEqual(issues.map((i) => i.rule), ['R19'])
})

test('review notes are numbered after the highest and leave with their element', () => {
  let doc = normalize(large())
  doc = ops.addAnnotation(doc, 't1').doc
  doc = ops.addAnnotation(doc, 't2').doc
  doc = ops.addAnnotation(doc, 't3', { text: 'Check', tag: 'keep' }).doc
  doc = ops.deleteAnnotation(doc, doc.annotations[1].id).doc
  doc = ops.addAnnotation(doc, 't4').doc
  assert.deepEqual(doc.annotations.map((a) => [a.target_id, a.number]), [['t1', 1], ['t3', 3], ['t4', 4]])
  assert.equal(ops.deleteElements(doc, { nodeIds: ['t3'] }).doc.annotations.length, 2, 'notes leave with their element')
})
