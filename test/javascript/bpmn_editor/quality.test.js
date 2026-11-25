import { test } from 'node:test'
import assert from 'node:assert/strict'
import { FIXTURES } from './fixtures.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { arrange, emptyStretches, STEP } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { measure, sharedLength, segmentsCross } from './support/layoutQuality.js'
import { setOrientation, deleteElements } from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { routeDiagram } from '../../../app/components/bali/bpmn_editor/model/router.js'
import { doc as docOf, lanes as lanesOf, node as nodeOf, flow as flowOf } from './helpers.js'
import { hasExternalLabel } from '../../../app/components/bali/bpmn_editor/model/labels.js'

// Ceilings for the soft measures after Tidy up, per fixture: what the
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
    test(`${name} (${orientation}) after Tidy up: no hard violation, a straight happy path, soft measures under their ceiling`, () => {
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

// The sample's decision stands 130 px after «Validate invoice»: its name, 4 px
// over the diamond, reached 3 px into the activity's height and lay on its
// pending badge. A name above keeps over the row and its badges (labels.js).
test('the hand-placed invoice flow has no violation as it comes; one made by hand, Tidy up removes', () => {
  const loaded = normalize(FIXTURES.invoice())
  assert.equal(measure(loaded).hard, 0, JSON.stringify(measure(loaded).details))
  const crowded = { ...loaded, nodes: loaded.nodes.map((n, i) => (i === 2 ? { ...n, x: loaded.nodes[1].x } : n)) }
  assert.ok(measure(crowded).hard > 0)
  assert.equal(measure(autoLayout(crowded)).hard, 0)
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

test('deleting an element closes the gap it leaves; what lies before it stays put', () => {
  const laid = autoLayout(normalize(FIXTURES.large(12)))
  const { doc: cut } = deleteElements(laid, { nodeIds: ['t3'] })
  assert.ok(emptyStretches(cut).length > 0, 'without the arrangement a column stands empty')
  const settled = arrange(cut, { before: laid })
  assert.deepEqual(emptyStretches(settled), [])
  const x = (d, id) => d.nodes.find((n) => n.id === id).x
  assert.equal(x(settled, 't2'), x(laid, 't2'), 'before the gap: untouched')
  assert.ok(x(laid, 't4') - x(settled, 't4') >= STEP.horizontal - 10, 'after it: one column back')
  assert.equal(measure(settled).hard, 0)
})

test('an element nudged by the pixel keeps its pixel; the arrangement only moves it out of a collision', () => {
  const laid = autoLayout(normalize(FIXTURES.invoice()))
  const nudged = { ...laid, nodes: laid.nodes.map((n) => (n.id === 't3' ? { ...n, x: n.x + 1 } : n)) }
  const x = (d) => d.nodes.find((n) => n.id === 't3').x
  assert.equal(x(arrange(nudged)), x(laid), 'snapped back to the grid by default')
  assert.equal(x(arrange(nudged, { keep: new Set(['t3']) })), x(laid) + 1)
})

// #1694: elements may be left close together. The least is measured between
// shapes; a name counts where it is drawn, not as part of one box around the
// element, and a shape left a little over another's edge goes to that least.
const after = (type, gap, extra = {}) => {
  const width = { task: 150, exclusive_gateway: 50, end_event: 36 }[type]
  return docOf({
    lanes: [{ ...lanesOf('A')[0], size: 260 }, { ...lanesOf('A', 'B')[1], size: 200 }],
    nodes: [nodeOf('s', 'start_event', 'l1', 110, 130, { name: 'Go' }), nodeOf('a', 'task', 'l1', 300, 130), nodeOf('b', type, 'l1', 375 + gap + width / 2, 130, extra), nodeOf('c', 'task', 'l2', 800, 330)],
    edges: [flowOf('f0', 's', 'a'), flowOf('f1', 'a', 'b'), flowOf('f2', 'b', 'c')]
  })
}
const settledGap = (d) => {
  const arranged = arrange(d)
  assert.equal(measure(arranged).hard, 0, JSON.stringify(measure(arranged).details))
  assert.equal(arrange(arranged), arranged, 'settled')
  const [a, b] = ['a', 'b'].map((id) => nodeBox(arranged.nodes.find((n) => n.id === id)))
  return b.x - (a.x + a.w)
}
const gaps = (type, asked, extra) => asked.map((gap) => settledGap(after(type, gap, extra)))

test('two activities: what a person leaves stays, 20 px is the least, and a little over the edge goes there too', () => {
  assert.deepEqual(gaps('task', [80, 60, 40, 20]), [80, 60, 40, 20])
  assert.deepEqual(gaps('task', [12, 5, 0, -4, -20, -60]), [20, 20, 20, 20, 20, 20])
})

test('an activity dropped on another — over more than half of it — still goes to the next free spot', () => {
  assert.deepEqual(gaps('task', [-100, -140]), [90, 90])
})

test('a gateway comes as close to the activity before it as another activity: its name stands above the row', () => {
  const name = { name: '¿La factura es válida?' }
  assert.deepEqual(gaps('exclusive_gateway', [60, 40, 20, 5, -4], name), [60, 40, 20, 20, 20])
  assert.deepEqual(gaps('exclusive_gateway', [40, 20, 5], { ...name, label_position: 'bottom' }), [40, 20, 20])
  assert.deepEqual(gaps('exclusive_gateway', [40, 20, 5], { ...name, label_orientation: 'vertical' }), [40, 20, 20])
})

// An event's name under it is drawn in the activity's row: it keeps the event its own width away.
test('an event keeps only the room its name takes: 27 px for «Fin», none for a name above', () => {
  assert.deepEqual(gaps('end_event', [57, 37, 20, 0], { name: 'Fin' }), [57, 37, 27, 27])
  assert.deepEqual(gaps('end_event', [57, 37, 20, 0], { name: 'Pago realizado' }), [57, 37, 37, 37])
  assert.deepEqual(gaps('end_event', [37, 20, 0], { name: 'Pago realizado', label_position: 'top' }), [37, 27, 27])
})

// Under 36 px the two port stubs (18 px each) run past each other: the search
// between their ends drew [375,72] → 393 → back to 374 → 395, a loop.
test('the connection between two neighbours closer than their stubs is a straight line, or one step halfway', () => {
  const pointsOf = (d, id) => routeDiagram(d).get(id).points.map((p) => [p.x, p.y])
  for (const [type, extra] of [['task', {}], ['exclusive_gateway', { name: 'Ok?' }], ['end_event', { name: 'Fin', label_position: 'top' }]]) {
    for (const gap of [20, 30]) {
      const route = pointsOf(arrange(after(type, gap, extra)), 'f1')
      assert.equal(route.length, 2, `${type} at ${gap}: ${JSON.stringify(route)}`)
      assert.equal(route[0][1], route[1][1])
    }
  }
  const lower = after('task', 20)
  lower.nodes[2] = { ...lower.nodes[2], y: lower.nodes[2].y + 30 }
  const stepped = pointsOf(arrange(lower), 'f1')
  assert.deepEqual(stepped.map(([x]) => x - stepped[0][0]), [0, 10, 10, 20])
})

test('a name is never left on the stub of a neighbour’s port', () => {
  // A narrow activity: the gateway's name would reach over its top port.
  const narrow = after('exclusive_gateway', 20, { name: '¿La factura es válida?' })
  narrow.nodes[1] = { ...narrow.nodes[1], width: 80, x: 375 - 80 }
  assert.ok(settledGap(narrow) > 20)
})

test('two activities one over the other may stand 16 px apart in a lane', () => {
  const stacked = docOf({ lanes: [{ ...lanesOf('A')[0], size: 400 }], nodes: [nodeOf('t1', 'task', 'l1', 300, 90), nodeOf('t2', 'task', 'l1', 300, 90 + 64 + 16)] })
  const [t1, t2] = arrange(stacked).nodes
  assert.deepEqual([t2.x - t1.x, t2.y - (t1.y + 64)], [0, 16])
})

// #1694: names placed by hand (`label_position`) are part of the footprint
// the layout, the arrangement and the router already work with.
const withLabels = (doc, position, turned = () => false) => ({ ...doc, nodes: doc.nodes.map((n) => (hasExternalLabel(n) ? { ...n, label_position: position(n), ...(turned(n) ? { label_orientation: 'vertical' } : {}) } : n)) })
for (const [name, make] of Object.entries(FIXTURES)) {
  for (const orientation of ['horizontal', 'vertical']) {
    test(`${name} (${orientation}) with every outside name placed above, below or mixed: no hard violation`, () => {
      const base = normalize(make())
      const turned = orientation === 'vertical' ? setOrientation(base, 'vertical').doc : base
      let flip = 0
      for (const position of [() => 'top', () => 'bottom', () => (flip++ % 2 ? 'top' : 'bottom')]) {
        const laid = autoLayout(withLabels(turned, position))
        assert.equal(measure(laid).hard, 0, `Tidy up: ${JSON.stringify(measure(laid).details)}`)
        // Placed on a diagram already laid out, as the properties panel does it.
        const edited = arrange(withLabels(autoLayout(turned), position))
        assert.equal(measure(edited).hard, 0, `edit: ${JSON.stringify(measure(edited).details)}`)
        assert.equal(arrange(edited), edited, 'settled')
      }
    })
  }
}

// …and so are names turned to read upwards (`label_orientation`), whose box is tall.
for (const [name, make] of Object.entries(FIXTURES)) {
  for (const orientation of ['horizontal', 'vertical']) {
    test(`${name} (${orientation}) with outside names turned, where the editor puts them, above and below: no hard violation`, () => {
      const base = normalize(make())
      const turned = orientation === 'vertical' ? setOrientation(base, 'vertical').doc : base
      let flip = 0
      for (const position of [() => null, () => 'top', () => 'bottom']) {
        for (const which of [() => true, () => flip++ % 2 === 0]) {
          const laid = autoLayout(withLabels(turned, position, which))
          assert.equal(measure(laid).hard, 0, `Tidy up: ${JSON.stringify(measure(laid).details)}`)
          const edited = arrange(withLabels(autoLayout(turned), position, which))
          assert.equal(measure(edited).hard, 0, `edit: ${JSON.stringify(measure(edited).details)}`)
          assert.equal(arrange(edited), edited, 'settled')
        }
      }
    })
  }
}
