// "Center the flow" and the first view: the whole diagram, clear of the
// toolbars over the canvas (top), the zoom bar (bottom) and, while either is
// open, the legend or the properties panel (right) — and never below 40 %, where names stop being legible;
// a larger diagram is scrolled instead of shrunk. `minZoom` (Component
// `min_zoom:`) moves that floor: a small embedded diagram may rather be whole.
// `minimal` (Component `chrome: :minimal`): no toolbar over the canvas, so
// only the zoom bar's room is kept.
export const MIN_FIT_ZOOM = 0.4
// The properties panel over the canvas' right side, as PropertiesPanel.jsx
// sizes it (`w-96 max-w-[max(18rem,36%)]` at `right-3`): 384 px, on a narrow
// canvas 36 % of it and never under 288 px, plus the 12 px to the edge.
export const panelWidth = (canvasWidth) => Math.min(384, Math.max(288, canvasWidth * 0.36)) + 12
// Its room with a gap, at its widest: the fit has no canvas to measure.
export const PANEL_GAP = 20
export const PANEL_RESERVE = panelWidth(Infinity) + PANEL_GAP

export function fitOptions ({ legendOpen = false, panelOpen = false, duration, minZoom = MIN_FIT_ZOOM, minimal = false } = {}) {
  return {
    padding: {
      top: minimal ? '16px' : '76px',
      right: panelOpen ? `${PANEL_RESERVE}px` : legendOpen ? '290px' : minimal ? '16px' : '40px',
      bottom: minimal ? '52px' : '64px',
      left: minimal ? '16px' : '40px'
    },
    minZoom,
    ...(duration ? { duration } : {})
  }
}

// React Flow centres a diagram it clamped to minZoom, which opens a long flow
// in its middle. Shown at the floor, the flow starts at its beginning instead:
// its first lane and first element sit at the padding, the rest scrolls.
export function anchorStart (flow, { padding, minZoom = MIN_FIT_ZOOM } = fitOptions(), duration) {
  const viewport = flow.getViewport()
  if (viewport.zoom > minZoom + 0.001) return
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
