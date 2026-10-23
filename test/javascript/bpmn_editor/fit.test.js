import { test } from 'node:test'
import assert from 'node:assert/strict'
import { anchorStart, fitOptions, MIN_FIT_ZOOM } from '../../../app/components/bali/bpmn_editor/canvas/fit.js'

// A stand-in for React Flow's instance: a viewport and the bounds of its nodes.
function flowAt (viewport, bounds) {
  const calls = []
  return {
    calls,
    getViewport: () => viewport,
    getNodes: () => [{ id: 'n' }],
    getNodesBounds: () => bounds,
    setViewport: (v) => calls.push(v)
  }
}

test('a diagram clamped to the minimum zoom opens at its start, not its middle', () => {
  // 4000 px wide at 40 %: React Flow centred it, so its start is off-screen.
  const flow = flowAt({ x: -300, y: 120, zoom: MIN_FIT_ZOOM }, { x: 0, y: 0, width: 4000, height: 600 })
  anchorStart(flow, fitOptions())
  assert.deepEqual(flow.calls, [{ x: 40, y: 120, zoom: MIN_FIT_ZOOM }])
})

test('a diagram that fits keeps the centred view', () => {
  const flow = flowAt({ x: 200, y: 120, zoom: 0.8 }, { x: 0, y: 0, width: 800, height: 400 })
  anchorStart(flow, fitOptions())
  assert.deepEqual(flow.calls, [])
})

test('at the floor, an axis whose start is already in view is left alone', () => {
  const flow = flowAt({ x: 300, y: 120, zoom: MIN_FIT_ZOOM }, { x: 0, y: 0, width: 400, height: 300 })
  anchorStart(flow, fitOptions())
  assert.deepEqual(flow.calls, [])
})

test('the fit keeps the diagram clear of the properties panel and of the open legend', () => {
  assert.equal(fitOptions().padding.right, '40px')
  assert.equal(fitOptions({ legendOpen: true }).padding.right, '290px')
  assert.equal(fitOptions({ panelOpen: true }).padding.right, '320px')
  assert.equal(fitOptions({ legendOpen: true, panelOpen: true }).padding.right, '320px')
})

// Component `min_zoom:`: an embedded diagram may go below 40 % to be seen whole.
test('min_zoom moves the floor of the fit and of the anchoring', () => {
  assert.equal(fitOptions().minZoom, MIN_FIT_ZOOM)
  assert.equal(fitOptions({ minZoom: 0.15 }).minZoom, 0.15)
  // At 25 % with a 15 % floor the diagram fitted: it stays centred.
  const fitted = flowAt({ x: -300, y: 120, zoom: 0.25 }, { x: 0, y: 0, width: 4000, height: 600 })
  anchorStart(fitted, fitOptions({ minZoom: 0.15 }))
  assert.deepEqual(fitted.calls, [])
  // Clamped at that floor, it opens at its start.
  const clamped = flowAt({ x: -300, y: 120, zoom: 0.15 }, { x: 0, y: 0, width: 9000, height: 600 })
  anchorStart(clamped, fitOptions({ minZoom: 0.15 }))
  assert.deepEqual(clamped.calls, [{ x: 40, y: 120, zoom: 0.15 }])
})

test('the minimal chrome keeps only the zoom bar clear', () => {
  assert.deepEqual(fitOptions({ minimal: true }).padding, { top: '16px', right: '16px', bottom: '52px', left: '16px' })
  assert.equal(fitOptions({ minimal: true, legendOpen: true }).padding.right, '290px')
})
