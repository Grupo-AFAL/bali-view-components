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
