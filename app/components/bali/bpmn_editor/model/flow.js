// The document drawn as React Flow nodes and edges. React Flow never owns the
// diagram: these are rebuilt from the document after every change, and a drag
// only becomes real when it is committed back into the document.
//
// Every node carries `measured`: the sizes are the document's, and without
// it React Flow refuses to drag a node it has not measured itself.
//
// Lanes are NOT parents of the nodes inside them (`parentId`): membership is
// decided by geometry when a node is dropped, which is what lets a node move
// to another lane, and a lane is a background node whose body lets pointer
// events through to the pane (flow.css) so dragging inside a lane pans.
import { layoutLanes, laneRect, nodeBox, poolOrigin } from './geometry.js'

export const LANE_PREFIX = 'lane:'
export const laneNodeId = (laneId) => `${LANE_PREFIX}${laneId}`
export const isLaneNodeId = (id) => String(id).startsWith(LANE_PREFIX)
export const laneIdOf = (id) => String(id).slice(LANE_PREFIX.length)

const Z_LANE = -20
const Z_GROUP = -10

export function buildRfNodes (doc, { layout = layoutLanes(doc), editable = false, issues = new Map(), selected = new Set(), diff = null } = {}) {
  const origin = poolOrigin(doc)
  const lanes = layout.entries.map((entry, index) => {
    const rect = laneRect(layout, entry)
    const id = laneNodeId(entry.id)
    return {
      id,
      type: 'lane',
      position: { x: origin.x + rect.x, y: origin.y + rect.y },
      width: rect.w,
      height: rect.h,
      measured: { width: rect.w, height: rect.h },
      zIndex: Z_LANE,
      draggable: editable,
      dragHandle: '.bpmn-lane-header',
      selectable: editable,
      connectable: false,
      selected: selected.has(id),
      data: {
        lane: entry.lane,
        index,
        orientation: layout.orientation,
        header: layout.header,
        issue: issues.get(String(entry.id)) || null,
        diff: diff ? diff.lanes[String(entry.id)] || null : null,
        diffReasons: diff && diff.reasons ? diff.reasons[String(entry.id)] || null : null
      }
    }
  })
  const external = new Set(layout.entries.filter((e) => e.lane.kind === 'external').map((e) => String(e.id)))
  const nodes = (doc.nodes || []).map((node) => {
    const box = nodeBox(node)
    const id = String(node.id)
    return {
      id,
      type: 'bpmn',
      position: { x: origin.x + box.x, y: origin.y + box.y },
      width: box.w,
      height: box.h,
      measured: { width: box.w, height: box.h },
      zIndex: node.type === 'group' ? Z_GROUP : 0,
      draggable: editable,
      selectable: true,
      connectable: editable,
      selected: selected.has(id),
      data: {
        node,
        external: node.lane_id != null && external.has(String(node.lane_id)),
        issue: issues.get(id) || null,
        diff: diff ? diff.nodes[id] || null : null,
        diffReasons: diff && diff.reasons ? diff.reasons[id] || null : null
      }
    }
  })
  return [...lanes, ...nodes]
}

export function buildRfEdges (doc, routes, { editable = false, selected = new Set(), issues = new Map(), diff = null } = {}) {
  const edges = []
  for (const edge of doc.edges || []) {
    const id = String(edge.id)
    const route = routes.get(id)
    if (!route) continue
    edges.push({
      id,
      type: 'routed',
      source: String(edge.source),
      target: String(edge.target),
      sourceHandle: route.sourceSide === 'auto' ? null : route.sourceSide,
      targetHandle: route.targetSide === 'auto' ? null : route.targetSide,
      selectable: true,
      reconnectable: editable,
      deletable: editable,
      selected: selected.has(id),
      zIndex: 1,
      data: { edge, issue: issues.get(id) || null, diff: diff ? diff.edges[id] || null : null, diffReasons: diff && diff.reasons ? diff.reasons[id] || null : null }
    })
  }
  return edges
}
