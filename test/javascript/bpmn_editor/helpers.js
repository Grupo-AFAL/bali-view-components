// Small documents for the model tests: lanes stacked in order, nodes placed
// by centre so a test reads like the diagram it draws.
import { NODE_TYPES } from '../../../app/components/bali/bpmn_editor/model/catalog.js'

export function lanes (...names) {
  return names.map((name, i) => ({ id: `l${i + 1}`, name, kind: 'internal', order: i + 1, size: 180 }))
}

export function node (id, type, laneId, cx, cy, extra = {}) {
  const { width, height } = NODE_TYPES[type] || { width: 120, height: 60 }
  return { id, type, lane_id: laneId, name: extra.name ?? id, x: cx - width / 2, y: cy - height / 2, ...extra }
}

export const flow = (id, source, target, extra = {}) => ({ id, source, target, ...extra })

export function doc (overrides = {}) {
  return { version: 1, orientation: 'horizontal', pool: { x: 0, y: 0 }, lanes: [], nodes: [], edges: [], annotations: [], stencil: [], issues: [], ...overrides }
}
