// The compact layout (AFAL VIS-01/02/03): horizontal lanes, a flow that
// serpentines into bands until it fits a letter page legibly, with the same
// hard constraints as the straight one.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { FIXTURES } from './fixtures.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { measure } from '../../../app/components/bali/bpmn_editor/model/layoutQuality.js'
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

test('the invoice does not fit a letter page straight; compact folds it until it does', () => {
  const straight = autoLayout(normalize(FIXTURES.invoice()))
  const folded = compact(normalize(FIXTURES.invoice()))
  assert.equal(pageFit(straight).fits, false)
  assert.equal(pageFit(folded).fits, true)
  assert.ok(pageFit(folded).width < pageFit(straight).width)
})

test('a returning band reads right to left: its steps are straight lines out of the left side', () => {
  const doc = compact(normalize(FIXTURES.invoice()))
  const back = [...routeAll(doc).values()].filter((r) => r.sourceSide === 'left' && r.targetSide === 'right')
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
