// The compact layout (AFAL VIS-01/02/03): horizontal lanes, a flow that
// serpentines into bands until it fits a letter page legibly, with the same
// hard constraints as the straight one.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { FIXTURES, supplierOnboarding } from './fixtures.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, node, flow } from './helpers.js'
import { measure } from './support/layoutQuality.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { setOrientation } from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { pageFit, LETTER } from '../../../app/components/bali/bpmn_editor/model/page.js'

const compact = (doc) => autoLayout(doc, { mode: 'compact' })

// Ceilings for the soft measures in compact mode, what it reaches today. The
// 60-activity flow cycles through four lanes every five steps: folded into
// bands its lane changes cross the returning rows (11 crossings).
const CEILING = {
  invoice: { crossings: 0, avgBends: 1, maxBends: 2 },
  rework: { crossings: 1, avgBends: 1.5, maxBends: 4 },
  parallel: { crossings: 1, avgBends: 1, maxBends: 2 },
  large: { crossings: 12, avgBends: 1, maxBends: 4 },
  partners: { crossings: 0, avgBends: 1, maxBends: 2 }
}

for (const [name, make] of Object.entries(FIXTURES)) {
  test(`${name} in compact mode: no hard violation, soft measures under their ceiling`, () => {
    const doc = compact(normalize(make()))
    const m = measure(doc)
    assert.equal(m.hard, 0, JSON.stringify(m.details))
    const ceiling = CEILING[name]
    assert.ok(m.crossings <= ceiling.crossings, `crossings ${m.crossings}`)
    assert.ok(m.avgBends <= ceiling.avgBends, `average bends ${m.avgBends}`)
    assert.ok(m.maxBends <= ceiling.maxBends, `max bends ${m.maxBends}`)
    assert.equal(arrange(doc), doc, 'settled: arranging again changes nothing')
  })
}

// Before folding, compact tightens the flow (layout.js: columns as wide as
// what they hold, tasks of 120 px, names wrapped at 100 px, 40 px between
// neighbours). A flow of a dozen steps then reads straight on the page.
const backwards = (doc) => [...routeAll(doc).values()].filter((r) => r.sourceSide === 'left' && r.targetSide === 'right')

test('the invoice does not fit loose, fits tightened: compact keeps it straight', () => {
  const loose = autoLayout(normalize(FIXTURES.invoice()))
  const tight = compact(normalize(FIXTURES.invoice()))
  assert.equal(pageFit(loose).fits, false)
  assert.equal(pageFit(tight).fits, true)
  assert.equal(backwards(tight).length, 0, 'not folded: nothing reads backwards')
})

// The 10-step flow of the demo video folded into two bands before.
test('«Alta de proveedor» from the demo fits a landscape letter page straight, at 6 pt or more', () => {
  const doc = compact(normalize(supplierOnboarding()))
  const fit = pageFit(doc)
  assert.ok(fit.scale >= 0.727, `scale ${fit.scale.toFixed(3)}`)
  assert.equal(backwards(doc).length, 0, 'not folded')
  const m = measure(doc)
  assert.equal(m.hard, 0, JSON.stringify(m.details))
})

test('a flow too long even tightened folds, and a returning band reads right to left in straight lines', () => {
  const doc = compact(normalize(FIXTURES.large(14)))
  assert.equal(pageFit(doc).fits, true)
  const back = backwards(doc)
  assert.ok(back.length > 0, 'some step of the flow reads backwards')
  assert.ok(back.every((r) => r.points.length === 2), 'and is one straight segment')
})

test('a flow that fits straight stays straight', () => {
  const doc = normalize(FIXTURES.partners())
  assert.deepEqual(compact(doc).nodes, autoLayout(doc).nodes)
})

test('the 60-activity flow does not fit a letter page even folded, and says so', () => {
  const straight = pageFit(autoLayout(normalize(FIXTURES.large())))
  const folded = pageFit(compact(normalize(FIXTURES.large())))
  assert.equal(folded.fits, false)
  assert.ok(folded.scale > straight.scale * 3, `folded shows it larger (${folded.scale.toFixed(2)} vs ${straight.scale.toFixed(2)})`)
})

test('vertical lanes are laid out straight: compact keeps lanes horizontal only', () => {
  const vertical = setOrientation(normalize(FIXTURES.large(14)), 'vertical').doc
  assert.deepEqual(compact(vertical).nodes, autoLayout(vertical).nodes)
})

test('the target page is an option: a portrait page folds more', () => {
  const doc = normalize(FIXTURES.large(14))
  const landscape = compact(doc)
  const portrait = autoLayout(doc, { mode: 'compact', page: { ...LETTER, orientation: 'portrait' } })
  assert.ok(pageFit(portrait, { ...LETTER, orientation: 'portrait' }).width < pageFit(landscape).width)
})

test('a group, and an artifact in no lane, move with the lane they lie over when it shrinks', () => {
  const two = lanes('A', 'B')
  two[0].size = 400
  const d = doc({
    lanes: two,
    nodes: [
      node('a', 'task', 'l1', 200, 100), node('b', 'task', 'l2', 200, 500), node('c', 'task', 'l2', 420, 500),
      { id: 'g', type: 'group', lane_id: 'l2', name: '', x: 110, y: 450, width: 430, height: 110 },
      node('do', 'data_object', null, 700, 480)
    ],
    edges: [flow('e', 'b', 'c')]
  })
  const r = arrange(d)
  const at = (id) => r.nodes.find((n) => n.id === id)
  const frames = (outer, inner) => { const a = nodeBox(outer); const b = nodeBox(inner); return b.x >= a.x && b.y >= a.y && b.x + b.w <= a.x + a.w && b.y + b.h <= a.y + a.h }

  assert.ok(at('b').y < 500, 'the lane shrank and its content moved up')
  assert.ok(frames(at('g'), at('b')) && frames(at('g'), at('c')), 'the group still frames its activities')
  assert.equal(at('do').y - d.nodes.find((n) => n.id === 'do').y, at('b').y - d.nodes.find((n) => n.id === 'b').y, 'the data object moved with the lane')
  assert.equal(arrange(r), r)
})
