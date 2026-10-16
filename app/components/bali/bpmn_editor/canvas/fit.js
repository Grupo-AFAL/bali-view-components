// "Center the flow" and the first view: the whole diagram, clear of the
// toolbars over the canvas (top), the zoom bar (bottom) and, while either is
// open, the legend or the properties panel (right) — and never below 40 %, where names stop being legible;
// a larger diagram is scrolled instead of shrunk.
export const MIN_FIT_ZOOM = 0.4

export function fitOptions ({ legendOpen = false, panelOpen = false, duration } = {}) {
  return {
    padding: { top: '76px', right: panelOpen ? '320px' : legendOpen ? '290px' : '40px', bottom: '64px', left: '40px' },
    minZoom: MIN_FIT_ZOOM,
    ...(duration ? { duration } : {})
  }
}

// React Flow centres a diagram it clamped to minZoom, which opens a long flow
// in its middle. Shown at the floor, the flow starts at its beginning instead:
// its first lane and first element sit at the padding, the rest scrolls.
export function anchorStart (flow, { padding } = fitOptions(), duration) {
  const viewport = flow.getViewport()
  if (viewport.zoom > MIN_FIT_ZOOM + 0.001) return
  const nodes = flow.getNodes()
  if (!nodes.length) return
  const bounds = flow.getNodesBounds(nodes)
  const sides = typeof padding === 'object' ? padding : {}
  const left = parseFloat(sides.left) || 40
  const top = parseFloat(sides.top) || 40
  const x = Math.max(viewport.x, left - bounds.x * viewport.zoom)
  const y = Math.max(viewport.y, top - bounds.y * viewport.zoom)
  if (x === viewport.x && y === viewport.y) return
  flow.setViewport({ x, y, zoom: viewport.zoom }, duration ? { duration } : undefined)
}

export function fitDiagram (flow, options, duration) {
  return Promise.resolve(flow.fitView({ ...options, ...(duration ? { duration } : {}) }))
    .then(() => anchorStart(flow, options, duration))
}
