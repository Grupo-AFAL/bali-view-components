import { test } from 'node:test'
import assert from 'node:assert/strict'
import { FIXTURES } from './fixtures.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { measure, sharedLength, segmentsCross } from '../../../app/components/bali/bpmn_editor/model/layoutQuality.js'
import { setOrientation } from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'

// Ceilings for the soft measures after Auto-arrange, per fixture: what the
// layout reaches today, so a regression shows. Crossings stay at most one
// (the rework loop has one); bends average at most one per connection.
const CEILING = {
  invoice: { crossings: 0, avgBends: 1, maxBends: 2 },
  rework: { crossings: 1, avgBends: 1.5, maxBends: 4 },
  parallel: { crossings: 0, avgBends: 1, maxBends: 2 },
  large: { crossings: 0, avgBends: 1, maxBends: 2 },
  partners: { crossings: 0, avgBends: 1, maxBends: 2 }
}

for (const [name, make] of Object.entries(FIXTURES)) {
  for (const orientation of ['horizontal', 'vertical']) {
    test(`${name} (${orientation}) after Auto-arrange: no hard violation, a straight happy path, soft measures under their ceiling`, () => {
      const base = normalize(make())
      const doc = autoLayout(orientation === 'vertical' ? setOrientation(base, 'vertical').doc : base)
      const m = measure(doc)
      assert.equal(m.hard, 0, JSON.stringify(m.details))
      assert.equal(m.happyPathDeviation, 0, 'the happy path reads in a straight line')
      if (orientation === 'horizontal') {
        const ceiling = CEILING[name]
        assert.ok(m.crossings <= ceiling.crossings, `crossings ${m.crossings}`)
        assert.ok(m.avgBends <= ceiling.avgBends, `average bends ${m.avgBends}`)
        assert.ok(m.maxBends <= ceiling.maxBends, `max bends ${m.maxBends}`)
      }
    })
  }
}

test('arranging an arranged document changes nothing (same object)', () => {
  const doc = autoLayout(normalize(FIXTURES.invoice()))
  assert.equal(arrange(doc), doc)
})

test('the metric sees what it measures', () => {
  const h = (x1, x2, y) => [{ x: x1, y }, { x: x2, y }]
  const v = (x, y1, y2) => [{ x, y: y1 }, { x, y: y2 }]
  assert.equal(sharedLength(h(0, 100, 10), h(50, 150, 10)), 50)
  assert.equal(sharedLength(h(0, 100, 10), h(100, 150, 10)), 0, 'touching is not sharing')
  assert.equal(sharedLength(h(0, 100, 10), h(0, 100, 22)), 0, 'a parallel channel is not sharing')
  assert.equal(segmentsCross(h(0, 100, 10), v(50, 0, 20)), true)
  assert.equal(segmentsCross(h(0, 100, 10), v(100, 0, 20)), false, 'meeting at an end is not crossing')
  const crowded = normalize(FIXTURES.invoice())
  crowded.nodes[2] = { ...crowded.nodes[2], x: crowded.nodes[1].x }
  assert.ok(measure(crowded).overlaps > 0)
})

test('the hand-placed invoice flow has violations Auto-arrange removes', () => {
  const loaded = normalize(FIXTURES.invoice())
  assert.ok(measure(loaded).hard > 0)
  assert.equal(measure(autoLayout(loaded)).hard, 0)
})

test('the metric counts two branches of a gateway leaving by the same side', () => {
  const doc = normalize(FIXTURES.invoice())
  const route = (points) => ({ points })
  const routes = new Map(doc.edges.map((e) => [String(e.id), route([{ x: 0, y: 0 }, { x: 0, y: 1 }])]))
  // Both out of g1 downwards, 12 px apart: no shared stretch, still one side.
  routes.set('f3', route([{ x: 450, y: 275 }, { x: 450, y: 400 }]))
  routes.set('f4', route([{ x: 462, y: 271 }, { x: 462, y: 300 }, { x: 600, y: 300 }]))
  const m = measure(doc, { routes, edgeLabels: new Map() })
  assert.equal(m.gatewaySharedSide, 1)
  assert.deepEqual(m.details.find((d) => d[0] === 'gatewaySharedSide'), ['gatewaySharedSide', 'g1', 'f3', 'f4', 'bottom'])
})

// "No" goes on in the gateway's lane, "Yes" to the next lane: "No" leaves
// straight out the reading side on the gateway's row, "Yes" by the side
// towards its lane.
for (const [orientation, straight, towardsNextLane] of [['horizontal', 'right', 'bottom'], ['vertical', 'bottom', 'right']]) {
  test(`the invoice's gateway after Tidy up (${orientation}): its branches leave by distinct sides, the one in its lane straight`, () => {
    const doc = autoLayout(normalize({ ...FIXTURES.invoice(), orientation }))
    const routes = routeAll(doc)
    assert.equal(routes.get('f4').sourceSide, straight)
    assert.equal(routes.get('f3').sourceSide, towardsNextLane)
    assert.equal(routes.get('f4').points.length, 2, 'No → Invoice rejected is one straight line')
    assert.equal(measure(doc, { routes }).gatewaySharedSide, 0)
  })
}

test('a gateway whose branches both lie below it still sends them out by distinct sides: the one in its lane by the reading side', () => {
  const laid = autoLayout(normalize(FIXTURES.invoice()))
  // "Invoice rejected" a row lower, still in the gateway's lane: both targets are below.
  const doc = { ...laid, nodes: laid.nodes.map((n) => (n.id === 'e2' ? { ...n, y: n.y + 60 } : n)) }
  const routes = routeAll(doc)
  assert.equal(routes.get('f4').sourceSide, 'right')
  assert.equal(routes.get('f3').sourceSide, 'bottom')
})
