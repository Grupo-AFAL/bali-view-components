// Root of the BPMN editor island (#1489). The DOCUMENT is the state: every
// edit is a pure function document → document (model/operations.js), React
// Flow only draws what the document says and reports gestures back, and
// undo/redo are stacks of documents (model/history.js). The whole document is
// saved to the host (hooks/useSaver.js). Contracts: docs/api/bpmn-editor.md.
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { ReactFlow, ReactFlowProvider, Background, MiniMap, ConnectionMode, EdgeLabelRenderer, useReactFlow } from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import './flow.css'
import { translator } from './i18n.js'
import { normalize, namedByReference } from './model/document.js'
import { layoutLanes, nodeBox, poolOrigin } from './model/geometry.js'
import { routeAll, boxesById, distanceToRoute, findJumps } from './model/routing.js'
import { buildRfNodes, buildRfEdges, isLaneNodeId, laneIdOf, laneNodeId } from './model/flow.js'
import { PALETTE_ITEMS, isFlowNode, isArtifactLike, edgeType } from './model/catalog.js'
import * as ops from './model/operations.js'
import * as history from './model/history.js'
import { autoLayout } from './model/layout.js'
import { LETTER } from './model/page.js'
import { arrange } from './model/arrange.js'
import { placeEdgeLabels } from './model/edgeLabels.js'
import { fitOptions, fitDiagram, anchorStart } from './canvas/fit.js'
import { blockPolicy, evaluate, mergeIssues, issuesByElement, hasErrors, ruleList } from './model/rules/engine.js'
import useSaver from './hooks/useSaver.js'
import useHostEvents from './hooks/useHostEvents.js'
import useKeyboard, { claimKeyboard } from './hooks/useKeyboard.js'
import useExports from './hooks/useExports.js'
import { CanvasContext } from './canvas/CanvasContext.js'
import FlowNode from './canvas/FlowNode.jsx'
import LaneNode from './canvas/LaneNode.jsx'
import RoutedEdge, { EdgeMarkers } from './canvas/RoutedEdge.jsx'
import { minimapColor } from './canvas/minimap.js'
import ZoomBar from './chrome/ZoomBar.jsx'
import TopBar from './chrome/TopBar.jsx'
import Palette, { PALETTE_MIME } from './chrome/Palette.jsx'
import PropertiesPanel from './chrome/PropertiesPanel.jsx'
import { CanvasToolbar, ViewToolbar } from './chrome/CanvasToolbar.jsx'
import Notices from './chrome/Notices.jsx'
import Icon from './chrome/icons.jsx'
import Legend from './chrome/Legend.jsx'
import PendingPanel from './chrome/PendingPanel.jsx'
import RulesDialog from './chrome/RulesDialog.jsx'
import QuickMenu from './chrome/QuickMenu.jsx'
import Stencil, { STENCIL_MIME } from './chrome/Stencil.jsx'
import { openDrawerUrl } from '../../../frontend/bali/utils/drawer.js'
import { withParams } from './model/urls.js'
import CompareView from './chrome/CompareView.jsx'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const EMPTY_SELECTION = { nodes: [], edges: [], lanes: [] }
const NOTICE_MS = 4800

export default function BpmnEditor (props) {
  return (
    <ReactFlowProvider>
      <Editor {...props} />
    </ReactFlowProvider>
  )
}

function Editor ({
  data, editable: editableProp, autosave, lockOrientation, externalLanes = true, openIssues = false, layout: layoutMode, page, palette, legend, rules, fields, urls, i18n, hostElement,
  name, watermark, review
}) {
  const t = useMemo(() => translator(i18n), [i18n])
  const editable = Boolean(editableProp)
  // The compact layout and the print/export sheet (Component `layout:`, `page:`).
  const layoutOptions = useMemo(() => ({ mode: layoutMode === 'straight' ? 'straight' : 'compact', page: { ...LETTER, ...(page || {}) } }), [layoutMode, page])
  const policy = useMemo(() => blockPolicy(rules), [rules])
  const [arranging, setArranging] = useState(false)
  const [legendOpen, setLegendOpen] = useState(true)
  const names = useMemo(() => ({
    task: t('new_task'), sub_process: t('new_sub_process'), gateway: t('new_gateway'), start: t('new_start'),
    end: t('new_end'), event: t('new_event'), annotation: t('new_annotation'), data: t('new_data')
  }), [t])
  const labels = useMemo(() => ({ yes: t('label_yes'), no: t('label_no') }), [t])
  const flow = useReactFlow()
  const wrapperRef = useRef(null)

  // ── document & history ─────────────────────────────────────────────────
  const [state, setState] = useState(() => history.initialHistory(normalize(data, layoutOptions)))
  const doc = state.present
  const docRef = useRef(doc)
  docRef.current = doc

  const [notices, setNotices] = useState([])
  const notify = useCallback((text, tone = 'info', action = null) => {
    const id = Math.random().toString(36).slice(2)
    setNotices((list) => [...list.slice(-2), { id, text, tone, action }])
    setTimeout(() => setNotices((list) => list.filter((n) => n.id !== id)), action ? NOTICE_MS * 2 : NOTICE_MS)
  }, [])
  const block = useCallback((result) => notify(t(result.error, result.vars), 'block'), [notify, t])

  const commit = useCallback((next, options) => setState((s) => history.commit(s, next, options)), [])
  // Runs an operation against the CURRENT document; commits or shows the block.
  // Every edit is settled by the local arrangement (model/arrange.js) into ONE
  // document, so one undo step reverts both. `arrange: false` for edits that
  // set geometry on purpose (a lane's size, the shared length) or run per
  // keystroke.
  const apply = useCallback((operation, options = {}) => {
    let result = operation(docRef.current)
    if (result.error) { block(result); return null }
    if (options.arrange !== false && result.doc !== docRef.current) {
      const settled = arrange(result.doc, { before: docRef.current })
      if (settled !== result.doc) {
        result = { ...result, doc: settled }
        setArranging(true)
        setTimeout(() => setArranging(false), 260)
      }
    }
    if (result.doc !== docRef.current) commit(result.doc, options)
    docRef.current = result.doc
    return result
  }, [block, commit])

  const emit = useCallback((name, detail) => {
    const target = hostElement || document
    target.dispatchEvent(new CustomEvent(`bali-bpmn:${name}`, { bubbles: true, detail }))
  }, [hostElement])

  const saver = useSaver({
    doc,
    revision: state.revision,
    urls,
    editable,
    autosave,
    onAdopt: useCallback((serverDoc, { replace }) => {
      setState((s) => (replace ? history.adopt(s, serverDoc) : history.adopt(s, { ...s.present, issues: serverDoc.issues, version: serverDoc.version })))
    }, []),
    onReset: useCallback((serverDoc) => setState((s) => history.reset(s, serverDoc)), []),
    onEvent: emit,
    notify,
    t
  })

  // ── selection & view state ─────────────────────────────────────────────
  const [selection, setSelection] = useState(EMPTY_SELECTION)
  const [tool, setTool] = useState(null) // { kind: 'place', key } | { kind: 'connect', edge, source }
  const [mode, setMode] = useState('edit') // 'edit' | 'navigate'
  const [boxSelect, setBoxSelect] = useState(false)
  const [panel, setPanel] = useState(null) // null | 'participants'
  const [paletteCollapsed, setPaletteCollapsed] = useState(false)
  const [renamingId, setRenamingId] = useState(null)
  const [highlightId, setHighlightId] = useState(null)
  const [fullscreen, setFullscreen] = useState(false)
  const [dragPositions, setDragPositions] = useState(null) // id → absolute position while dragging
  const [liveLength, setLiveLength] = useState(null) // shared lane length while one lane's end is dragged
  const [dialog, setDialog] = useState(() => (openIssues && editable ? 'pending' : null)) // null | 'pending' | 'rules'
  const [compareMode, setCompareMode] = useState(null) // null | 'overlay' | 'side_by_side'
  // The quick menu's default direction follows the reading direction.
  const [direction, setDirection] = useState(() => (state.present.orientation === 'vertical' ? 'down' : 'right'))
  const interactive = editable && mode === 'edit'

  const selectedSet = useMemo(() => new Set([...selection.nodes, ...selection.edges, ...selection.lanes.map(laneNodeId)]), [selection])

  // ── derived drawing ────────────────────────────────────────────────────
  const layout = useMemo(() => layoutLanes(doc), [doc])
  const origin = useMemo(() => poolOrigin(doc), [doc])
  // While dragging, nodes are drawn where the pointer has them and the
  // connections that touch them are re-routed live; the document itself only
  // changes on drop.
  const liveDoc = useMemo(() => {
    if (!dragPositions) return doc
    return {
      ...doc,
      nodes: doc.nodes.map((n) => {
        const p = dragPositions.get(String(n.id))
        return p ? { ...n, x: p.x - origin.x, y: p.y - origin.y } : n
      })
    }
  }, [doc, dragPositions, origin])
  const baseRoutes = useMemo(() => routeAll(doc), [doc])
  const routes = useMemo(() => {
    if (!dragPositions) return baseRoutes
    const moving = new Set(dragPositions.keys())
    const touched = new Set(liveDoc.edges.filter((e) => moving.has(String(e.source)) || moving.has(String(e.target))).map((e) => String(e.id)))
    return routeAll(liveDoc, { previous: baseRoutes, onlyIds: touched, boxes: boxesById(liveDoc) })
  }, [liveDoc, baseRoutes, dragPositions])
  const routesRef = useRef(routes)
  routesRef.current = routes

  // The rules run on every change while editing; a viewer sees no pending
  // markers. Server issues (the document's `issues`) join them.
  const edgeLabels = useMemo(() => placeEdgeLabels(liveDoc, routes), [liveDoc, routes])
  const jumps = useMemo(() => findJumps(routes), [routes])
  const panelOpen = panel === 'participants' || selection.nodes.length > 0 || selection.edges.length > 0 || selection.lanes.length > 0
  const fit = useMemo(() => fitOptions({ legendOpen: legendOpen && legend && legend.length > 0, panelOpen }), [legendOpen, legend, panelOpen])

  // The palette the host allows, for VIS-10 (an imported element it does not offer).
  const allowed = useMemo(() => (palette && palette.items && palette.items.length ? new Set(palette.items.filter((i) => i.state === 'enabled').map((i) => i.key)) : null), [palette])
  const issueList = useMemo(() => (editable ? mergeIssues(evaluate(doc, rules || {}, t, { allowed, page: layoutOptions.page }), doc.issues, doc) : []), [editable, doc, rules, t, allowed, layoutOptions])
  const issues = useMemo(() => issuesByElement(issueList), [issueList])
  const baseNodes = useMemo(() => buildRfNodes(doc, { layout, editable: interactive, issues, selected: selectedSet }), [doc, layout, interactive, issues, selectedSet])
  // Lanes share one length: while the end of one is dragged every lane
  // follows it (gobierno-corporativo's onLaneResizing), not only on release.
  const nodes = useMemo(() => {
    if (!dragPositions && liveLength == null) return baseNodes
    const key = layout.axis.crossSize
    return baseNodes.map((n) => {
      if (n.type === 'lane' && liveLength != null) return { ...n, [key]: liveLength, measured: { ...n.measured, [key]: liveLength } }
      return dragPositions && dragPositions.has(n.id) ? { ...n, position: dragPositions.get(n.id) } : n
    })
  }, [baseNodes, dragPositions, liveLength, layout.axis.crossSize])
  const edges = useMemo(() => buildRfEdges(doc, routes, { editable: interactive, selected: selectedSet, issues }), [doc, routes, interactive, selectedSet, issues])

  // Selection that points at deleted elements is dropped.
  useEffect(() => {
    setSelection((sel) => {
      const ids = (list, all) => list.filter((id) => all.some((e) => String(e.id) === id))
      const next = { nodes: ids(sel.nodes, doc.nodes), edges: ids(sel.edges, doc.edges), lanes: ids(sel.lanes, doc.lanes) }
      return next.nodes.length === sel.nodes.length && next.edges.length === sel.edges.length && next.lanes.length === sel.lanes.length ? sel : next
    })
  }, [doc])

  // ── helpers ────────────────────────────────────────────────────────────
  const toPool = useCallback((clientX, clientY) => {
    const p = flow.screenToFlowPosition({ x: clientX, y: clientY })
    const o = poolOrigin(docRef.current)
    return { x: p.x - o.x, y: p.y - o.y }
  }, [flow])

  const select = useCallback((next) => setSelection({ ...EMPTY_SELECTION, ...next }), [])
  const clearSelection = useCallback(() => setSelection(EMPTY_SELECTION), [])

  const focusElement = useCallback((id) => {
    const d = docRef.current
    const o = poolOrigin(d)
    const node = d.nodes.find((n) => String(n.id) === String(id))
    let center = null
    if (node) {
      const box = nodeBox(node)
      center = { x: o.x + box.cx, y: o.y + box.cy }
      select({ nodes: [String(node.id)] })
    } else if (d.lanes.some((l) => String(l.id) === String(id))) {
      const l = layoutLanes(d)
      const entry = l.byId.get(String(id))
      center = l.axis.main === 'y' ? { x: o.x + 300, y: o.y + entry.offset + entry.size / 2 } : { x: o.x + entry.offset + entry.size / 2, y: o.y + 200 }
      select({ lanes: [String(id)] })
    } else if (d.edges.some((e) => String(e.id) === String(id))) {
      const route = routesRef.current.get(String(id))
      if (route) center = { x: o.x + route.label.x, y: o.y + route.label.y }
      select({ edges: [String(id)] })
    }
    if (center) flow.setCenter(center.x, center.y, { zoom: Math.max(flow.getZoom(), 0.9), duration: 300 })
    const highlight = node ? String(id) : laneNodeId(id)
    setHighlightId(highlight)
    setTimeout(() => setHighlightId((h) => (h === highlight ? null : h)), 2400)
  }, [flow, select])

  // ── element operations ─────────────────────────────────────────────────
  const createAt = useCallback((key, point) => {
    const item = PALETTE_ITEMS[key]
    if (!item || !item.node) return
    // Dropped on a sequence flow: inserted in it, nothing disconnected.
    const onEdge = isFlowNode(item.node) && docRef.current.edges.find((e) => {
      const route = baseRoutes.get(String(e.id))
      return edgeType(e) === 'sequence_flow' && route && distanceToRoute(point, route) < 10
    })
    const result = onEdge
      ? apply((d) => ops.insertOnEdge(d, onEdge.id, item.node, point, { policy, names }))
      : apply((d) => ops.createNode(d, item.node, point, { policy, names }))
    if (result) {
      select({ nodes: [String(result.id)] })
      setTool(null)
      if (onEdge) notify(t('toast_inserted'), 'success')
      // With nothing to search, the only way to link a new sub-process is to
      // create its entity: the host's drawer opens right away.
      if (item.node.type === 'sub_process' && urls.new_reference && !urls.references) {
        openDrawerUrl(withParams(urls.new_reference, { client_node_id: result.id, editor_id: hostElement && hostElement.id }))
      }
    }
  }, [apply, policy, names, select, baseRoutes, notify, t, urls, hostElement])

  // A stencil item becomes a linked sub-process and leaves the list.
  const placeStencil = useCallback((index, point) => {
    const item = (docRef.current.stencil || [])[index]
    if (!item || !item.reference) return
    const result = apply((d) => {
      const created = ops.createNode(d, { type: 'sub_process', reference: item.reference, name: item.reference.label }, point, { policy, names })
      if (created.error) return created
      return { ...created, doc: { ...created.doc, stencil: (created.doc.stencil || []).filter((_, i) => i !== index) } }
    })
    if (result) select({ nodes: [String(result.id)] })
  }, [apply, policy, names, select])

  // The quick menu's add: from an activity that already has its way out, a
  // branch through `gateway` (or the splitting gateway that way leads to).
  const quickAdd = useCallback((d, sourceId, attrs, dir, gateway) => {
    const appended = ops.appendNode(d, sourceId, attrs, dir, { policy, names, labels })
    if (appended.error !== 'block_connection' || !ops.branchPoint(d, sourceId)) return appended
    return ops.branchNode(d, sourceId, attrs, dir, { gateway, policy, names, labels })
  }, [policy, names, labels])

  const appendFrom = useCallback((sourceId, key, gateway) => {
    const item = PALETTE_ITEMS[key]
    if (!item || !item.node) return
    const result = apply((d) => quickAdd(d, sourceId, item.node, direction, gateway && PALETTE_ITEMS[gateway].node))
    if (result) select({ nodes: [String(result.id)] })
  }, [apply, quickAdd, direction, select])

  // A sequence flow refused because the activity already has its way out:
  // the block stays, and the notice offers the split that makes it valid.
  const blockConnection = useCallback((source, target, type, error) => {
    const through = (d) => ops.connectThroughGateway(d, source, target, { policy, names, labels })
    const needed = ops.gatewaysNeeded(docRef.current, source, target, { policy })
    const offer = type === 'sequence_flow' && error === 'block_connection' && needed && !through(docRef.current).error
    if (!offer) { block({ error }); return }
    notify(t(error), 'block', {
      // A way back into an activity that already has its way in: the merging XOR (AFAL COM-22).
      label: t(needed.merge && !needed.split ? 'add_merge' : 'add_gateway'),
      run: () => {
        const result = apply(through)
        if (result) select({ edges: [String(result.id)] })
      }
    })
  }, [policy, names, labels, block, notify, t, apply, select])

  const connectNodes = useCallback((source, target, type = 'sequence_flow') => {
    const error = ops.connectionError(docRef.current, source, target, { type, policy })
    if (error) { blockConnection(source, target, type, error); return null }
    const result = apply((d) => ops.connect(d, source, target, { type, policy, labels }))
    if (result) select({ edges: [String(result.id)] })
    return result
  }, [apply, policy, labels, select, blockConnection])

  const deleteSelection = useCallback(() => {
    const sel = selection
    if (!sel.nodes.length && !sel.edges.length && !sel.lanes.length) return
    const result = apply((d) => ops.deleteElements(d, { nodeIds: sel.nodes, edgeIds: sel.edges, laneIds: sel.lanes }, { policy }))
    if (result) clearSelection()
  }, [apply, selection, policy, clearSelection])

  const addLane = useCallback(() => {
    const number = docRef.current.lanes.length + 1
    const result = apply((d) => ops.addLane(d, { name: t('new_lane', { number }) }))
    if (result) {
      select({ lanes: [String(result.id)] })
      setRenamingId(laneNodeId(result.id))
    }
  }, [apply, t, select])

  const api = useMemo(() => ({
    updateNode: (id, patch, coalesce) => apply((d) => ops.updateNode(d, id, patch), { coalesce, arrange: !coalesce }),
    updateEdge: (id, patch, coalesce) => apply((d) => ops.updateEdge(d, id, patch), { coalesce, arrange: !coalesce }),
    updateLane: (id, patch, coalesce) => apply((d) => ops.updateLane(d, id, patch), { coalesce, arrange: !coalesce }),
    moveLane: (id, step) => apply((d) => ops.moveLane(d, id, step)),
    align: (dir) => apply((d) => ops.alignNodes(d, selection.nodes, dir, { policy })),
    addNote: (targetId) => apply((d) => ops.addAnnotation(d, targetId)),
    updateNote: (id, patch, coalesce) => apply((d) => ops.updateAnnotation(d, id, patch), { coalesce }),
    deleteNote: (id) => apply((d) => ops.deleteAnnotation(d, id)),
    deleteSelection,
    // The panel's link is a real <a href> (open in a new tab works); its click
    // only asks the host first.
    announceOpenReference: (node) => announceOpenReference(node, hostElement),
    newReference: (nodeId) => urls.new_reference && openDrawerUrl(withParams(urls.new_reference, { client_node_id: nodeId, editor_id: hostElement && hostElement.id })),
    newLaneAssignee: (laneId) => urls.new_lane_assignee && openDrawerUrl(withParams(urls.new_lane_assignee, { client_lane_id: laneId, editor_id: hostElement && hostElement.id }))
  }), [apply, deleteSelection, hostElement, urls, selection, policy])

  // ── React Flow callbacks ───────────────────────────────────────────────
  const onNodesChange = useCallback((changes) => {
    let selectionChanged = false
    const add = { nodes: new Set(selection.nodes), lanes: new Set(selection.lanes) }
    for (const change of changes) {
      if (change.type === 'position' && change.dragging && change.position) {
        setDragPositions((map) => new Map(map || []).set(change.id, change.position))
      } else if (change.type === 'select') {
        selectionChanged = true
        const isLane = isLaneNodeId(change.id)
        const set = isLane ? add.lanes : add.nodes
        const id = isLane ? laneIdOf(change.id) : change.id
        change.selected ? set.add(id) : set.delete(id)
      }
    }
    if (selectionChanged) {
      // A lane is selected on its own: lanes and nodes do not mix.
      const lanes = [...add.lanes]
      setSelection((sel) => (lanes.some((id) => !sel.lanes.includes(id))
        ? { ...EMPTY_SELECTION, lanes: lanes.filter((id) => !sel.lanes.includes(id)) }
        : { ...sel, nodes: [...add.nodes], lanes: add.nodes.size ? [] : lanes }))
    }
  }, [selection])

  const onEdgesChange = useCallback((changes) => {
    const edgesSel = new Set(selection.edges)
    let changed = false
    for (const change of changes) {
      if (change.type !== 'select') continue
      changed = true
      change.selected ? edgesSel.add(change.id) : edgesSel.delete(change.id)
    }
    if (changed) setSelection((sel) => ({ ...sel, edges: [...edgesSel] }))
  }, [selection])

  // Lane header drag: dropped over another lane → reorder; otherwise the
  // whole set of lanes moves (the pool offset).
  const onNodeDrag = useCallback((_event, rfNode) => {
    if (!isLaneNodeId(rfNode.id)) return
    const d = docRef.current
    const o = poolOrigin(d)
    const l = layoutLanes(d)
    const entry = l.byId.get(laneIdOf(rfNode.id))
    const start = l.axis.main === 'y' ? { x: o.x, y: o.y + entry.offset } : { x: o.x + entry.offset, y: o.y }
    const delta = { x: rfNode.position.x - start.x, y: rfNode.position.y - start.y }
    const map = new Map([[rfNode.id, rfNode.position]])
    for (const n of d.nodes) {
      if (String(n.lane_id) !== String(entry.id)) continue
      map.set(String(n.id), { x: o.x + Number(n.x) + delta.x, y: o.y + Number(n.y) + delta.y })
    }
    setDragPositions(map)
  }, [])

  const onNodeDragStop = useCallback((_event, rfNode, dragged) => {
    setDragPositions(null)
    const d = docRef.current
    const o = poolOrigin(d)
    if (isLaneNodeId(rfNode.id)) {
      const l = layoutLanes(d)
      const laneId = laneIdOf(rfNode.id)
      const entry = l.byId.get(laneId)
      const mainNow = rfNode.position[l.axis.main] - o[l.axis.main]
      const center = mainNow + entry.size / 2
      const over = l.entries.find((e) => e.id !== entry.id && center >= e.offset && center < e.offset + e.size)
      if (over) {
        const ids = l.entries.map((e) => String(e.id)).filter((id) => id !== String(laneId))
        const at = ids.indexOf(String(over.id)) + (over.offset > entry.offset ? 1 : 0)
        ids.splice(at, 0, String(laneId))
        apply((doc0) => ops.reorderLanes(doc0, ids))
      } else {
        const start = l.axis.main === 'y' ? { x: o.x, y: o.y + entry.offset } : { x: o.x + entry.offset, y: o.y }
        const dx = rfNode.position.x - start.x
        const dy = rfNode.position.y - start.y
        if (Math.abs(dx) > 1 || Math.abs(dy) > 1) apply((doc0) => ops.movePool(doc0, dx, dy), { arrange: false })
      }
      return
    }
    const movedIds = (dragged || [rfNode]).filter((n) => !isLaneNodeId(n.id)).map((n) => n.id)
    const original = d.nodes.find((n) => String(n.id) === rfNode.id)
    if (!original) return
    const delta = { x: rfNode.position.x - (o.x + Number(original.x)), y: rfNode.position.y - (o.y + Number(original.y)) }
    if (Math.abs(delta.x) < 1 && Math.abs(delta.y) < 1) return
    apply((doc0) => ops.moveNodes(doc0, movedIds, delta, { policy }))
  }, [apply, policy])

  const connectorType = (tool && tool.kind === 'connect' && tool.edge) || 'sequence_flow'
  const isValidConnection = useCallback((connection) => !ops.connectionError(docRef.current, connection.source, connection.target, {
    type: connectorType, policy
  }), [connectorType, policy])

  const onConnect = useCallback((connection) => {
    connectNodes(connection.source, connection.target, connectorType)
  }, [connectNodes, connectorType])

  // A drop on a node the connection may not reach says why, instead of
  // silently snapping back.
  const onConnectEnd = useCallback((event, connectionState) => {
    if (!connectionState || connectionState.isValid || !connectionState.fromNode) return
    const point = event.changedTouches ? event.changedTouches[0] : event
    const element = document.elementFromPoint(point.clientX, point.clientY)
    const target = element && element.closest('.react-flow__node-bpmn')
    const targetId = (connectionState.toNode && connectionState.toNode.id) || (target && target.dataset.id)
    if (!targetId || targetId === connectionState.fromNode.id) return
    const error = ops.connectionError(docRef.current, connectionState.fromNode.id, targetId, { type: connectorType, policy })
    if (error) blockConnection(connectionState.fromNode.id, targetId, connectorType, error)
  }, [connectorType, policy, blockConnection])

  const onReconnect = useCallback((oldEdge, connection) => {
    const source = connection.source !== oldEdge.source ? connection.source : undefined
    const target = connection.target !== oldEdge.target ? connection.target : undefined
    apply((d) => ops.reconnect(d, oldEdge.id, { source, target }, { policy }))
  }, [apply, policy])

  const onNodeClick = useCallback((event, rfNode) => {
    if (!editable) {
      if (rfNode.type === 'bpmn') openReference(rfNode.data.node, hostElement)
      return
    }
    if (tool && tool.kind === 'connect' && rfNode.type === 'bpmn') {
      if (!tool.source) setTool({ ...tool, source: rfNode.id })
      else if (connectNodes(tool.source, rfNode.id, tool.edge)) setTool(null)
      event.stopPropagation()
    }
  }, [editable, tool, connectNodes, hostElement])

  const onNodeDoubleClick = useCallback((_event, rfNode) => {
    if (rfNode.type !== 'bpmn') return
    const node = rfNode.data.node
    if (node.type === 'sub_process' && node.reference && node.reference.url) { openReference(node, hostElement); return }
    if (interactive && !namedByReference(node)) setRenamingId(rfNode.id)
  }, [interactive, hostElement])

  const onEdgeClick = useCallback((event, rfEdge) => {
    if (!tool || tool.kind !== 'place') return
    const item = PALETTE_ITEMS[tool.key]
    const edge = docRef.current.edges.find((e) => String(e.id) === rfEdge.id)
    if (!item || !item.node || !isFlowNode(item.node) || !edge || edgeType(edge) !== 'sequence_flow') return
    const result = apply((d) => ops.insertOnEdge(d, edge.id, item.node, toPool(event.clientX, event.clientY), { policy, names }))
    if (result) {
      select({ nodes: [String(result.id)] })
      setTool(null)
      notify(t('toast_inserted'), 'success')
    }
  }, [tool, apply, toPool, policy, names, select, notify, t])

  const onPaneClick = useCallback((event) => {
    setRenamingId(null)
    if (tool && tool.kind === 'place') { createAt(tool.key, toPool(event.clientX, event.clientY)); return }
    if (tool && tool.kind === 'connect') setTool(null)
  }, [tool, createAt, toPool])

  const onDrop = useCallback((event) => {
    if (!interactive) return
    const stencilIndex = event.dataTransfer.getData(STENCIL_MIME)
    if (stencilIndex !== '') {
      event.preventDefault()
      placeStencil(Number(stencilIndex), toPool(event.clientX, event.clientY))
      return
    }
    const key = event.dataTransfer.getData(PALETTE_MIME)
    if (!key) return
    event.preventDefault()
    createAt(key, toPool(event.clientX, event.clientY))
  }, [createAt, toPool, interactive, placeStencil])

  // ── lanes: resize ──────────────────────────────────────────────────────
  const onLaneResize = useCallback((rfId, axisKind, params) => {
    const l = layoutLanes(docRef.current)
    if (axisKind === 'main') {
      apply((doc0) => ops.resizeLane(doc0, laneIdOf(rfId), l.axis.main === 'y' ? params.height : params.width), { arrange: false })
    } else {
      setLiveLength(null)
      apply((doc0) => ops.setPoolLength(doc0, l.axis.cross === 'x' ? params.width : params.height), { arrange: false })
    }
  }, [apply])
  const onLaneResizing = useCallback((_rfId, params) => {
    const l = layoutLanes(docRef.current)
    setLiveLength(l.axis.cross === 'x' ? params.width : params.height)
  }, [])

  // ── keyboard ───────────────────────────────────────────────────────────
  const undo = useCallback(() => setState(history.undo), [])
  const redo = useCallback(() => setState(history.redo), [])
  const selectAll = useCallback(() => select({ nodes: docRef.current.nodes.map((n) => String(n.id)) }), [select])
  const onKeyDown = useCallback((event) => {
    if (event.defaultPrevented || /^(input|textarea|select)$/i.test(event.target.tagName) || event.target.isContentEditable) return
    const mod = event.ctrlKey || event.metaKey
    const key = event.key.toLowerCase()
    if (key === 'escape') { setTool(null); setRenamingId(null); clearSelection(); return }
    if (!interactive) return
    if (mod && key === 'z' && !event.shiftKey) {
      event.preventDefault(); undo()
    } else if (mod && (key === 'y' || (key === 'z' && event.shiftKey))) {
      event.preventDefault(); redo()
    } else if (mod && key === 'a') {
      event.preventDefault(); selectAll()
    } else if (key === 'delete' || key === 'backspace') {
      event.preventDefault(); deleteSelection()
    } else if (key.startsWith('arrow') && selection.nodes.length) {
      event.preventDefault()
      const step = event.shiftKey ? 1 : 10
      const delta = { x: key === 'arrowleft' ? -step : key === 'arrowright' ? step : 0, y: key === 'arrowup' ? -step : key === 'arrowdown' ? step : 0 }
      apply((d) => ops.moveNodes(d, selection.nodes, delta, { policy }), { coalesce: `arrows:${selection.nodes.join(',')}` })
    }
  }, [interactive, undo, redo, selectAll, deleteSelection, clearSelection, selection, apply, policy])

  useKeyboard(wrapperRef, onKeyDown)

  // ── fullscreen ─────────────────────────────────────────────────────────
  useEffect(() => {
    const onChange = () => setFullscreen(document.fullscreenElement === wrapperRef.current)
    document.addEventListener('fullscreenchange', onChange)
    return () => document.removeEventListener('fullscreenchange', onChange)
  }, [])
  const toggleFullscreen = useCallback(() => {
    const el = wrapperRef.current
    if (!el) return
    const done = () => setTimeout(() => fitDiagram(flow, fit, 200), 50)
    if (document.fullscreenElement) document.exitFullscreen().then(done)
    else if (el.requestFullscreen) el.requestFullscreen().then(done)
  }, [flow, fit])

  // ── host events ────────────────────────────────────────────────────────
  const reload = saver.reload
  useHostEvents(hostElement, { reload, apply, docRef })

  // ── in-place rename ────────────────────────────────────────────────────
  const renderRename = useCallback((element, isLane) => (
    <RenameInput
      value={element.name || ''}
      className={isLane ? 'bpmn-rename' : 'bpmn-rename left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2'}
      onDone={(value) => {
        setRenamingId(null)
        if (value == null || value === (element.name || '')) return
        if (isLane) apply((d) => ops.updateLane(d, element.id, { name: value }))
        else apply((d) => ops.updateNode(d, element.id, { name: value }))
      }}
    />
  ), [apply])
  const renderEdgeRename = useCallback((edge, point) => (
    <EdgeLabelRenderer>
      <div className='nodrag nopan absolute' style={{ transform: `translate(-50%, -50%) translate(${point.x}px, ${point.y}px)`, pointerEvents: 'all' }}>
        <RenameInput
          value={edge.label || ''} className='bpmn-rename static' onDone={(value) => {
            setRenamingId(null)
            if (value != null && value !== (edge.label || '')) apply((d) => ops.updateEdge(d, edge.id, { label: value }))
          }}
        />
      </div>
    </EdgeLabelRenderer>
  ), [apply])

  const tags = useMemo(() => (review && review.tags) || [], [review])
  const compare = (review && review.compare_with) || null
  const compareBase = useMemo(() => (compare && compare.document ? normalize(compare.document) : null), [compare])
  const notesByElement = useMemo(() => {
    const map = new Map()
    for (const note of doc.annotations || []) {
      if (map.has(String(note.target_id))) continue
      map.set(String(note.target_id), { number: note.number, text: note.text, color: (tags.find((tag) => tag.key === note.tag) || {}).color })
    }
    return map
  }, [doc.annotations, tags])
  const legendEntries = useMemo(() => {
    const used = new Set((doc.annotations || []).map((a) => a.tag).filter(Boolean))
    return [...(legend || []), ...tags.filter((tag) => used.has(tag.key)).map((tag) => ({ key: `note_${tag.key}`, label: tag.label, swatch: 'color', color: tag.color }))]
  }, [legend, tags, doc.annotations])

  // ── outputs ────────────────────────────────────────────────────────────
  const exports = useExports({ doc, name, watermark, tags, page: layoutOptions.page, wrapperRef })

  // The quick menu shows next to the one selected flow node that can be
  // followed (not an end event, not an artifact) while nothing else is going on.
  const enabledKeys = useMemo(() => new Set(((palette && palette.items) || []).filter((i) => i.state === 'enabled').map((i) => i.key)), [palette])
  const single = selection.nodes.length === 1 && !selection.edges.length ? doc.nodes.find((n) => String(n.id) === selection.nodes[0]) : null
  const quickMenuId = interactive && !tool && !dragPositions && !renamingId && single && single.type !== 'end_event' && !isArtifactLike(single) ? String(single.id) : null
  const renderQuickMenu = useCallback((node) => {
    const d = doc
    const point = policy.oneInOneOut ? ops.branchPoint(d, node.id) : null
    const splits = ['binary_decision', 'exclusive_gateway', 'parallel_gateway', 'inclusive_gateway'].filter((k) => enabledKeys.has(k))
    const needsGateway = Boolean(point && !point.split)
    // Each direction tried on the side, so one that cannot work is disabled
    // and says why instead of failing after the click.
    const blocked = {}
    for (const dir of ['up', 'down', 'left', 'right']) {
      const tried = needsGateway && !splits.length
        ? { error: 'block_connection' }
        : quickAdd(d, node.id, { type: 'task' }, dir, splits[0] && PALETTE_ITEMS[splits[0]].node)
      if (tried.error) blocked[dir] = t(tried.error, tried.vars)
    }
    return (
      <QuickMenu
        t={t} enabled={enabledKeys} direction={direction} onDirection={setDirection} blocked={blocked} needsGateway={needsGateway}
        onAdd={(key, gateway) => appendFrom(node.id, key, gateway)}
        onConnect={() => setTool({ kind: 'connect', edge: 'sequence_flow', source: String(node.id) })}
      />
    )
  }, [t, enabledKeys, direction, appendFrom, policy, quickAdd, doc])

  const hasSelection = selection.nodes.length || selection.edges.length || selection.lanes.length
  const showPanel = panel === 'participants' || hasSelection

  const canvas = useMemo(() => ({
    t,
    routes,
    origin,
    orientation: layout.orientation,
    editable: interactive,
    connectable: interactive,
    renamingId,
    highlightId,
    startRename: (id) => interactive && !labelLocked(docRef.current, id) && setRenamingId(id),
    renderRename,
    renderEdgeRename,
    onLaneResize,
    onLaneResizing,
    quickMenuId,
    renderQuickMenu,
    notesByElement,
    edgeLabels,
    jumps,
    panelOpen: Boolean(showPanel)
  }), [edgeLabels, jumps, t, routes, origin, layout.orientation, interactive, renamingId, highlightId, renderRename, renderEdgeRename, onLaneResize, onLaneResizing, quickMenuId, renderQuickMenu, notesByElement, showPanel])

  // ── finalize ───────────────────────────────────────────────────────────
  // The draft always saves; finalizing needs a flow without errors, checked
  // here first and then by the server, whose 422 `issues` open the panel.
  const finalize = useCallback(async () => {
    if (hasErrors(issueList)) {
      setDialog('pending')
      notify(t('toast_finalize_blocked'), 'block')
      return
    }
    const result = await saver.finalize()
    if (result.ok) notify(t('toast_finalized'), 'success')
    else if (result.issues) {
      setState((s) => history.adopt(s, { ...s.present, issues: result.issues }))
      setDialog('pending')
      notify(t('toast_finalize_blocked'), 'block')
    }
  }, [issueList, saver, notify, t])

  // ── chrome ─────────────────────────────────────────────────────────────
  const selectedCount = selection.nodes.length
  let help = t('help_default')
  if (!editable) help = t('help_read_only')
  else if (mode === 'navigate') help = t('help_navigate')
  else if (tool && tool.kind === 'connect') help = t(tool.source ? 'help_connect_target' : 'help_connect_source')
  else if (tool && tool.kind === 'place') help = t('help_place')
  else if (selectedCount === 1) help = t('help_selected')

  return (
    <CanvasContext.Provider value={canvas}>
      <div
        ref={wrapperRef}
        className={`bpmn-editor relative flex flex-col overflow-hidden rounded-xl border border-base-300 bg-base-100 shadow-sm outline-none ${fullscreen ? 'h-screen' : ''}`}
        onPointerDownCapture={() => claimKeyboard(wrapperRef.current)}
        tabIndex={-1}
      >
        <TopBar
          t={t}
          editable={editable}
          statusLabel={doc.status_label}
          saveStatus={saver.status}
          autosave={autosave}
          issues={issueList}
          onIssues={() => setDialog('pending')}
          onRules={() => setDialog('rules')}
          history={{ undo, redo, canUndo: state.past.length > 0, canRedo: state.future.length > 0 }}
          onSave={saver.save}
          canFinalize={Boolean(urls.finalize)}
          onFinalize={finalize}
          finalizing={saver.finalizing}
          exports={exports}
          onCompare={compareBase ? () => setCompareMode((m) => (m ? null : 'overlay')) : null}
          comparing={Boolean(compareMode)}
        />
        {compareMode && (
          <div className={fullscreen ? 'min-h-0 flex-1' : 'h-[640px]'}>
            <CompareView t={t} base={compareBase} current={doc} label={compare.label} mode={compareMode} onMode={setCompareMode} onExit={() => setCompareMode(null)} />
          </div>
        )}
        <div className={`flex min-h-0 ${compareMode ? 'hidden' : ''} ${fullscreen ? 'flex-1' : 'h-[640px]'}`}>
          {editable && (
            <Palette
              t={t} palette={palette} tool={tool && tool.kind === 'place' ? tool : null}
              disabled={mode !== 'edit'}
              onPick={(key) => {
                if (!key) { setTool(null); return }
                const item = PALETTE_ITEMS[key]
                setTool(item.tool === 'connect' ? { kind: 'connect', key, edge: item.edge, source: null } : { kind: 'place', key })
              }}
              onAddLane={addLane}
              collapsed={paletteCollapsed}
              onToggle={() => setPaletteCollapsed((c) => !c)}
            />
          )}
          <div
            className={`bpmn-canvas relative h-full min-w-0 flex-1 ${interactive ? 'is-editable' : 'is-readonly'} ${tool && tool.kind === 'place' ? 'is-placing' : ''} ${tool && tool.kind === 'connect' ? 'is-connecting' : ''} ${showPanel ? 'has-panel' : ''} ${arranging ? 'is-arranging' : ''}`}
            onDragOver={(e) => { if (interactive && (e.dataTransfer.types.includes(PALETTE_MIME) || e.dataTransfer.types.includes(STENCIL_MIME))) { e.preventDefault(); e.dataTransfer.dropEffect = 'copy' } }}
            onDrop={onDrop}
            onPointerDown={(e) => { if (!/^(input|textarea|select|button)$/i.test(e.target.tagName)) wrapperRef.current?.focus({ preventScroll: true }) }}
          >
            <EdgeMarkers />
            <ReactFlow
              nodes={nodes}
              edges={edges}
              nodeTypes={nodeTypes}
              edgeTypes={edgeTypes}
              onNodesChange={onNodesChange}
              onEdgesChange={onEdgesChange}
              onNodeDrag={interactive ? onNodeDrag : undefined}
              onNodeDragStop={interactive ? onNodeDragStop : undefined}
              onConnect={interactive ? onConnect : undefined}
              onReconnect={interactive ? onReconnect : undefined}
              isValidConnection={isValidConnection}
              onNodeClick={onNodeClick}
              onNodeDoubleClick={onNodeDoubleClick}
              onEdgeClick={interactive ? onEdgeClick : undefined}
              onEdgeDoubleClick={interactive ? (_e, edge) => { if (!labelLocked(docRef.current, edge.id)) setRenamingId(edge.id) } : undefined}
              onPaneClick={onPaneClick}
              onConnectEnd={interactive ? onConnectEnd : undefined}
              connectionMode={ConnectionMode.Loose}
              // A selected lane would rise above the nodes it holds (React Flow
              // lifts a selected node by 1000) and its body would cover them.
              elevateNodesOnSelect={false}
              nodesDraggable={interactive}
              nodesConnectable={interactive}
              edgesReconnectable={interactive}
              elementsSelectable={interactive}
              deleteKeyCode={null}
              selectionKeyCode='Shift'
              multiSelectionKeyCode={['Shift', 'Meta', 'Control']}
              panOnDrag={!(interactive && boxSelect)}
              selectionOnDrag={interactive && boxSelect}
              fitView
              fitViewOptions={fit}
              onInit={(instance) => setTimeout(() => anchorStart(instance, fit), 60)}
              minZoom={0.1}
              maxZoom={2.5}
              zoomOnDoubleClick={false}
            >
              <Background gap={20} size={1} />
              <MiniMap className='bpmn-chrome' nodeColor={minimapColor} pannable zoomable ariaLabel={t('minimap')} />
              <CanvasToolbar
                t={t}
                editable={interactive}
                orientation={layout.orientation}
                onAddLane={addLane}
                onToggleOrientation={lockOrientation ? null : () => {
                  apply((d) => ops.setOrientation(d, layout.orientation === 'horizontal' ? 'vertical' : 'horizontal'))
                  setTimeout(() => fitDiagram(flow, fit, 250), 50)
                }}
                onAutoLayout={() => {
                  apply((d) => ({ doc: autoLayout(d, layoutOptions) }), { arrange: false })
                  notify(t('toast_layout'), 'success')
                  setTimeout(() => fitDiagram(flow, fit, 250), 50)
                }}
                connecting={Boolean(tool && tool.kind === 'connect')}
                onConnect={() => setTool((current) => (current && current.kind === 'connect' ? null : { kind: 'connect', edge: 'sequence_flow', source: null }))}
                onImport={urls.import ? () => openDrawerUrl(withParams(urls.import, { editor_id: hostElement && hostElement.id })) : null}
              />
              <ViewToolbar
                t={t}
                editable={editable}
                onParticipants={doc.lanes.length ? () => setPanel((p) => (p === 'participants' ? null : 'participants')) : null}
                participantsOpen={panel === 'participants'}
                navigating={mode === 'navigate'}
                onNavigate={() => { setMode((m) => (m === 'navigate' ? 'edit' : 'navigate')); setTool(null) }}
                fullscreen={fullscreen}
                onFullscreen={toggleFullscreen}
              />
              <Legend t={t} entries={legendEntries} open={legendOpen} onToggle={setLegendOpen} />
              {interactive && !showPanel && <Stencil t={t} items={doc.stencil} />}
              <ZoomBar t={t} fit={fit} onSelectAll={interactive ? selectAll : null} selectedCount={selectedCount} boxSelect={boxSelect} onBoxSelect={interactive ? () => setBoxSelect((b) => !b) : null} />
            </ReactFlow>
            <Notices notices={notices} t={t} onDismiss={(id) => setNotices((list) => list.filter((n) => n.id !== id))} />
            {showPanel
              ? (
                <PropertiesPanel
                  t={t} doc={doc} selection={selection} api={api} editable={interactive}
                  nodeFields={(fields && fields.nodes) || {}} laneFields={(fields && fields.lanes) || []} urls={urls || {}}
                  externalLanes={externalLanes}
                  view={panel === 'participants' && !hasSelection ? 'participants' : 'properties'}
                  onClose={() => { setPanel(null); clearSelection() }}
                  onPickLane={(id) => focusElement(id)}
                  annotationTags={tags}
                />
                )
              : null}
          </div>
        </div>
        {!compareMode && (
          // The context help lives under the canvas, where it covers nothing.
          <p className='bpmn-chrome flex items-center gap-2 border-t border-base-300 px-3 py-1.5 text-xs text-base-content/70' data-testid='bpmn-help'>
            <Icon name='info' size={13} />{help}
          </p>
        )}
        {dialog === 'pending' && (
          <PendingPanel t={t} issues={issueList} onClose={() => setDialog(null)} onPick={(issue) => { setDialog(null); focusElement(issue.element_id) }} />
        )}
        {dialog === 'rules' && <RulesDialog t={t} rules={ruleList(rules || {})} onClose={() => setDialog(null)} />}
      </div>
    </CanvasContext.Provider>
  )
}

// Flows leaving a parallel gateway carry no condition, hence no label.
function labelLocked (doc, edgeId) {
  const edge = doc.edges.find((e) => String(e.id) === String(edgeId))
  const source = edge && doc.nodes.find((n) => String(n.id) === String(edge.source))
  return Boolean(source && source.type === 'parallel_gateway')
}

function RenameInput ({ value, className, onDone }) {
  const [text, setText] = useState(value)
  const finished = useRef(false)
  const finish = (result) => {
    if (finished.current) return
    finished.current = true
    onDone(result)
  }
  return (
    <input
      autoFocus
      className={`${className} nodrag nopan`}
      value={text}
      onChange={(e) => setText(e.target.value)}
      onFocus={(e) => e.target.select()}
      onBlur={() => finish(text.trim())}
      onKeyDown={(e) => {
        e.stopPropagation()
        if (e.key === 'Enter') finish(text.trim())
        if (e.key === 'Escape') finish(null)
      }}
      onPointerDown={(e) => e.stopPropagation()}
      onDoubleClick={(e) => e.stopPropagation()}
    />
  )
}

// The drawer URL carries the client id of what is being created and the
// editor's DOM id, which the host's stream answer targets.
// Read-only: a click on a node with a reference navigates; editing: a
// double-click does. `bali-bpmn:open-reference` is cancelable so the host can
// handle it itself (open a tab, a drawer…).
// Announces it; false when the host took it over (preventDefault).
function announceOpenReference (node, hostElement) {
  const reference = node && node.reference
  if (!reference || !reference.url) return false
  const event = new CustomEvent('bali-bpmn:open-reference', { bubbles: true, cancelable: true, detail: { node_id: node.id, reference } })
  return (hostElement || document).dispatchEvent(event)
}

function openReference (node, hostElement) {
  if (!announceOpenReference(node, hostElement)) return
  if (window.Turbo && typeof window.Turbo.visit === 'function') window.Turbo.visit(node.reference.url)
  else window.location.assign(node.reference.url)
}
