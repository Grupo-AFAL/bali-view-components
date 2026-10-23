import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { diffDocuments } from '../../../app/components/bali/bpmn_editor/model/diff.js'
import { layoutLanes, nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { LETTER } from '../../../app/components/bali/bpmn_editor/model/page.js'

// An app's two versions of one flow without geometry, a lane name repeated in
// each and lane ids shared with another meaning ("lane-4"), compared by name.
const fixture = JSON.parse(readFileSync(new URL('../../fixtures/bpmn_editor/compare_shared_lane_ids.json', import.meta.url)))
const COMPACT = { mode: 'compact', page: LETTER }
const laneAt = (layout, node) => {
  const box = nodeBox(node)
  const middle = box.y + box.h / 2
  const entry = layout.entries.find((e) => middle >= e.offset && middle < e.offset + e.size)
  return entry ? String(entry.id) : null
}

test('each version is laid out in its own four lanes, whatever the other calls its lanes', () => {
  for (const data of [fixture.compare_with, fixture.current]) {
    const doc = normalize(data, COMPACT)
    const layout = layoutLanes(doc)
    assert.deepEqual(layout.entries.map((e) => String(e.id)), data.lanes.map((l) => l.id))
    for (const node of doc.nodes) assert.equal(laneAt(layout, node), node.lane_id || data.lanes[0].id, node.id)
    assert.ok(new Set(doc.nodes.map((n) => n.y)).size > 2, 'not one row')
  }
})

test('a repeated lane name pairs by its order, and the summary counts only the real changes', () => {
  const diff = diffDocuments(normalize(fixture.compare_with, COMPACT), normalize(fixture.current, COMPACT), { match: 'name' })
  assert.deepEqual([...diff.lanePairs], [['lane-1', 'lane-4'], ['lane-2', 'lane-5'], ['lane-3', 'lane-6'], ['lane-4', 'lane-7']])
  assert.deepEqual(diff.summary, { added: 3, removed: 5, changed: 0, moved: 0 })
})

// The editor lays out a `compare_with:` document with the component's
// `layout:` / `page:` (BpmnEditor.jsx, compareBase), as its own on load:
// with autoLayout's default (straight) this one is 3140 px long, which a pane
// fits at 20 % — one row with 24 px lane bands.
test('laid out with the component layout, the compared version is as long as the editor own', () => {
  const compared = layoutLanes(normalize(fixture.compare_with, COMPACT)).length
  const current = layoutLanes(normalize(fixture.current, COMPACT)).length
  assert.ok(compared / current < 1.2, `${compared} vs ${current}`)
  assert.equal(layoutLanes(normalize(fixture.compare_with)).length, 3140)
})
