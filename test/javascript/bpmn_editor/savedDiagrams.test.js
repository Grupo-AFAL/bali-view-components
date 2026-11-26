// A diagram saved before a release is not moved by the first edit after it.
// The fixture holds documents as v3.29.1 left them — Tidy up of every sample,
// straight and compact, in both orientations, and the end of random editing
// sessions — settled under that version's arrangement. Whatever this one
// changes about where a name is drawn or how close two elements may stand,
// arranging them again must change nothing.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'

const SAVED = JSON.parse(readFileSync(new URL('../../fixtures/bpmn_editor/arranged_v3_29_1.json', import.meta.url), 'utf8'))
const moved = (before, after) => [
  ...after.nodes.filter((n, i) => n.x !== before.nodes[i].x || n.y !== before.nodes[i].y).map((n, i) => `${n.id} by ${n.x - before.nodes.find((m) => m.id === n.id).x},${n.y - before.nodes.find((m) => m.id === n.id).y}`),
  ...after.lanes.filter((l, i) => l.size !== before.lanes[i].size).map((l) => `lane ${l.id} to ${l.size}`)
]

for (const [name, saved] of Object.entries(SAVED)) {
  test(`a diagram saved by v3.29.1 stays as it is when arranged: ${name}`, () => {
    const doc = normalize(saved)
    const arranged = arrange(doc)
    assert.deepEqual(moved(doc, arranged), [])
    assert.equal(arranged, doc)
  })
}
