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
import { normalize } from './model/document.js'
import { layoutLanes, nodeBox, poolOrigin } from './model/geometry.js'
import { routeAll, boxesById } from './model/routing.js'
import { buildRfNodes, buildRfEdges, isLaneNodeId, laneIdOf, laneNodeId } from './model/flow.js'
import { PALETTE_ITEMS } from './model/catalog.js'
import * as ops from './model/operations.js'
import * as history from './model/history.js'
import { autoLayout } from './model/layout.js'
import { blockPolicy } from './model/rules.js'
import useSaver from './hooks/useSaver.js'
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
import Notices, { HelpBar } from './chrome/Notices.jsx'
import Legend from './chrome/Legend.jsx'
import { openDrawerUrl } from './drawer.js'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const EMPTY_SELECTION = { nodes: [], edges: [], lanes: [] }
const NOTICE_MS = 4800
// The editor the user touched last. Keyboard shortcuts go to it while the
// focus is inside it or nowhere (on <body>, where it lands when the focused
// node is deleted) — with several editors on a page, only that one answers.
let activeEditor = null

export default function BpmnEditor (props) {
  return (
    <ReactFlowProvider>
      <Editor {...props} />
    </ReactFlowProvider>
  )
}

function Editor ({
  data, editable: editableProp, readOnlyNotice, autosave, palette, legend, rules, nodeFields, laneFields, urls, i18n, hostElement
}) {
  const t = useMemo(() => translator(i18n), [i18n])
  const editable = Boolean(editableProp)
  const policy = useMemo(() => blockPolicy(rules), [rules])
  const names = useMemo(() => ({
    task: t('new_task'), sub_process: t('new_sub_process'), gateway: t('new_gateway'), start: t('new_start'),
    end: t('new_end'), event: t('new_event'), annotation: t('new_annotation'), data: t('new_data')
  }), [t])
  const labels = useMemo(() => ({ yes: t('label_yes'), no: t('label_no') }), [t])
  const flow = useReactFlow()
  const wrapperRef = useRef(null)

  // ── document & history ─────────────────────────────────────────────────
  const [state, setState] = useState(() => history.initialHistory(normalize(data)))
  const doc = state.present
  const docRef = useRef(doc)
  docRef.current = doc

  const [notices, setNotices] = useState([])
  const notify = useCallback((text, tone = 'info') => {
    const id = Math.random().toString(36).slice(2)
    setNotices((list) => [...list.slice(-2), { id, text, tone }])
    setTimeout(() => setNotices((list) => list.filter((n) => n.id !== id)), NOTICE_MS)
  }, [])
  const block = useCallback((result) => notify(t(result.error, result.vars), 'block'), [notify, t])

  const commit = useCallback((next, options) => setState((s) => history.commit(s, next, options)), [])
  // Runs an operation against the CURRENT document; commits or shows the block.
  const apply = useCallback((operation, options) => {
    const result = operation(docRef.current)
    if (result.error) { block(result); return null }
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
  const [panel, setPanel] = useState(null) // null | 'participants'
  const [paletteCollapsed, setPaletteCollapsed] = useState(false)
  const [renamingId, setRenamingId] = useState(null)
  const [highlightId, setHighlightId] = useState(null)
  const [fullscreen, setFullscreen] = useState(false)
  const [dragPositions, setDragPositions] = useState(null) // id → absolute position while dragging
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

  const issues = useMemo(() => new Map(), [])
  const baseNodes = useMemo(() => buildRfNodes(doc, { layout, editable: interactive, issues, selected: selectedSet }), [doc, layout, interactive, issues, selectedSet])
  const nodes = useMemo(() => {
    if (!dragPositions) return baseNodes
    return baseNodes.map((n) => (dragPositions.has(n.id) ? { ...n, position: dragPositions.get(n.id) } : n))
  }, [baseNodes, dragPositions])
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
      const route = routeAll(d).get(String(id))
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
    const result = apply((d) => ops.createNode(d, item.node, point, { policy, names }))
    if (result) {
      select({ nodes: [String(result.id)] })
      setTool(null)
    }
  }, [apply, policy, names, select])

  const connectNodes = useCallback((source, target, type = 'sequence_flow') => {
    const result = apply((d) => ops.connect(d, source, target, { type, policy, labels }))
    if (result) select({ edges: [String(result.id)] })
    return result
  }, [apply, policy, labels, select])

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
    updateNode: (id, patch, coalesce) => apply((d) => ops.updateNode(d, id, patch), { coalesce }),
    updateEdge: (id, patch, coalesce) => apply((d) => ops.updateEdge(d, id, patch), { coalesce }),
    updateLane: (id, patch, coalesce) => apply((d) => ops.updateLane(d, id, patch), { coalesce }),
    moveLane: (id, step) => apply((d) => ops.moveLane(d, id, step)),
    align: () => {},
    deleteSelection,
    openReference: (node) => openReference(node, hostElement),
    newReference: (nodeId) => urls.new_reference && openDrawerUrl(withParam(urls.new_reference, 'client_node_id', nodeId)),
    newLaneAssignee: (laneId) => urls.new_lane_assignee && openDrawerUrl(withParam(urls.new_lane_assignee, 'client_lane_id', laneId))
  }), [apply, deleteSelection, hostElement, urls])

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
        if (Math.abs(dx) > 1 || Math.abs(dy) > 1) apply((doc0) => ops.movePool(doc0, dx, dy))
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
    if (error) block({ error })
  }, [connectorType, policy, block])

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
    if (interactive) setRenamingId(rfNode.id)
  }, [interactive, hostElement])

  const onPaneClick = useCallback((event) => {
    setRenamingId(null)
    if (tool && tool.kind === 'place') { createAt(tool.key, toPool(event.clientX, event.clientY)); return }
    if (tool && tool.kind === 'connect') setTool(null)
  }, [tool, createAt, toPool])

  const onDrop = useCallback((event) => {
    const key = event.dataTransfer.getData(PALETTE_MIME)
    if (!key || !interactive) return
    event.preventDefault()
    createAt(key, toPool(event.clientX, event.clientY))
  }, [createAt, toPool, interactive])

  // ── lanes: resize ──────────────────────────────────────────────────────
  const onLaneResize = useCallback((rfId, axisKind, params) => {
    const l = layoutLanes(docRef.current)
    if (axisKind === 'main') {
      apply((doc0) => ops.resizeLane(doc0, laneIdOf(rfId), l.axis.main === 'y' ? params.height : params.width))
    } else {
      apply((doc0) => ops.setPoolLength(doc0, l.axis.cross === 'x' ? params.width : params.height))
    }
  }, [apply])

  // ── keyboard ───────────────────────────────────────────────────────────
  const undo = useCallback(() => setState(history.undo), [])
  const redo = useCallback(() => setState(history.redo), [])
  const selectAll = useCallback(() => select({ nodes: docRef.current.nodes.map((n) => String(n.id)) }), [select])
  const onKeyDown = useCallback((event) => {
    if (event.defaultPrevented || /^(input|textarea|select)$/i.test(event.target.tagName) || event.target.isContentEditable) return
    const mod = event.ctrlKey || event.metaKey
    const key = event.key.toLowerCase()
    if (key === 'escape') { setTool(null); setRenamingId(null); clearSelection(); return }
    if (!editable) return
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
  }, [editable, undo, redo, selectAll, deleteSelection, clearSelection, selection, apply, policy])

  useEffect(() => {
    const onDocumentKey = (event) => {
      const wrapper = wrapperRef.current
      if (!wrapper) return
      const focus = document.activeElement
      const inside = focus && wrapper.contains(focus)
      if (inside || ((!focus || focus === document.body) && activeEditor === wrapper)) onKeyDown(event)
    }
    document.addEventListener('keydown', onDocumentKey)
    return () => document.removeEventListener('keydown', onDocumentKey)
  }, [onKeyDown])

  // ── fullscreen ─────────────────────────────────────────────────────────
  useEffect(() => {
    const onChange = () => setFullscreen(document.fullscreenElement === wrapperRef.current)
    document.addEventListener('fullscreenchange', onChange)
    return () => document.removeEventListener('fullscreenchange', onChange)
  }, [])
  const toggleFullscreen = useCallback(() => {
    const el = wrapperRef.current
    if (!el) return
    const done = () => setTimeout(() => flow.fitView({ padding: 0.12, duration: 200 }), 50)
    if (document.fullscreenElement) document.exitFullscreen().then(done)
    else if (el.requestFullscreen) el.requestFullscreen().then(done)
  }, [flow])

  // ── host events ────────────────────────────────────────────────────────
  const reload = saver.reload
  useEffect(() => {
    // The stream action targets the editor element; an event dispatched on
    // document reaches every editor, so it may name one with `editor_id`.
    const forMe = (event) => !event.detail || !event.detail.editor_id || (hostElement && event.detail.editor_id === hostElement.id)
    const handlers = {
      'bali-bpmn:reload': (event) => { if (forMe(event)) reload() },
      'bali-bpmn:reference-created': (event) => {
        const { client_node_id: nodeId, reference } = event.detail || {}
        if (!nodeId || !reference || !docRef.current.nodes.some((n) => String(n.id) === String(nodeId))) return
        apply((d) => ops.updateNode(d, nodeId, { reference, name: reference.label }))
      },
      'bali-bpmn:lane-assignee-created': (event) => {
        const { client_lane_id: laneId, assignee } = event.detail || {}
        if (!laneId || !assignee || !docRef.current.lanes.some((l) => String(l.id) === String(laneId))) return
        apply((d) => ops.updateLane(d, laneId, { assignee, name: assignee.label }))
      }
    }
    const seen = new WeakSet()
    const listener = (event) => {
      if (seen.has(event)) return
      seen.add(event)
      handlers[event.type](event)
    }
    const targets = hostElement ? [hostElement, document] : [document]
    for (const el of targets) for (const name of Object.keys(handlers)) el.addEventListener(name, listener)
    return () => { for (const el of targets) for (const name of Object.keys(handlers)) el.removeEventListener(name, listener) }
  }, [hostElement, reload, apply])

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

  const canvas = useMemo(() => ({
    t,
    routes,
    origin,
    orientation: layout.orientation,
    editable: interactive,
    connectable: interactive,
    renamingId,
    highlightId,
    startRename: (id) => interactive && setRenamingId(id),
    renderRename,
    renderEdgeRename,
    onLaneResize,
    onLaneResizing: () => {}
  }), [t, routes, origin, layout.orientation, interactive, renamingId, highlightId, renderRename, renderEdgeRename, onLaneResize])

  // ── chrome ─────────────────────────────────────────────────────────────
  const selectedCount = selection.nodes.length
  let help = t('help_default')
  if (!editable) help = t('help_read_only')
  else if (mode === 'navigate') help = t('help_navigate')
  else if (tool && tool.kind === 'connect') help = t(tool.source ? 'help_connect_target' : 'help_connect_source')
  else if (tool && tool.kind === 'place') help = t('help_place')
  else if (selectedCount === 1) help = t('help_selected')
  const hasSelection = selection.nodes.length || selection.edges.length || selection.lanes.length
  const showPanel = panel === 'participants' || hasSelection

  return (
    <CanvasContext.Provider value={canvas}>
      <div
        ref={wrapperRef}
        className={`bpmn-editor flex flex-col overflow-hidden rounded-xl border border-base-300 bg-base-100 shadow-sm outline-none ${fullscreen ? 'h-screen' : ''}`}
        onPointerDownCapture={() => { activeEditor = wrapperRef.current }}
        tabIndex={-1}
      >
        {readOnlyNotice && !editable && (
          <div className='bpmn-chrome border-b border-base-300 bg-base-200 px-4 py-2 text-sm' role='status'>{readOnlyNotice}</div>
        )}
        <TopBar
          t={t}
          editable={editable}
          statusLabel={doc.status_label}
          saveStatus={saver.status}
          autosave={autosave}
          issues={[]}
          history={{ undo, redo, canUndo: state.past.length > 0, canRedo: state.future.length > 0 }}
          onSave={saver.save}
          canFinalize={false}
        />
        <div className={`flex min-h-0 ${fullscreen ? 'flex-1' : 'h-[640px]'}`}>
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
            className={`bpmn-canvas relative h-full min-w-0 flex-1 ${interactive ? 'is-editable' : 'is-readonly'} ${tool && tool.kind === 'place' ? 'is-placing' : ''} ${tool && tool.kind === 'connect' ? 'is-connecting' : ''} ${showPanel ? 'has-panel' : ''}`}
            onDragOver={(e) => { if (interactive && e.dataTransfer.types.includes(PALETTE_MIME)) { e.preventDefault(); e.dataTransfer.dropEffect = 'copy' } }}
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
              onEdgeDoubleClick={interactive ? (_e, edge) => setRenamingId(edge.id) : undefined}
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
              panOnDrag
              fitView
              fitViewOptions={{ padding: 0.12 }}
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
                onToggleOrientation={() => {
                  apply((d) => ops.setOrientation(d, layout.orientation === 'horizontal' ? 'vertical' : 'horizontal'))
                  setTimeout(() => flow.fitView({ padding: 0.12, duration: 250 }), 50)
                }}
                onAutoLayout={() => {
                  apply((d) => ({ doc: autoLayout(d) }))
                  notify(t('toast_layout'), 'success')
                  setTimeout(() => flow.fitView({ padding: 0.12, duration: 250 }), 50)
                }}
                connecting={Boolean(tool && tool.kind === 'connect')}
                onConnect={() => setTool((current) => (current && current.kind === 'connect' ? null : { kind: 'connect', edge: 'sequence_flow', source: null }))}
                onImport={urls.import ? () => openDrawerUrl(urls.import) : null}
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
              <Legend t={t} entries={legend} />
              <ZoomBar t={t} onSelectAll={interactive ? selectAll : null} selectedCount={selectedCount} />
            </ReactFlow>
            <HelpBar text={help} />
            <Notices notices={notices} t={t} onDismiss={(id) => setNotices((list) => list.filter((n) => n.id !== id))} />
            {showPanel
              ? (
                <PropertiesPanel
                  t={t} doc={doc} selection={selection} api={api} editable={interactive}
                  nodeFields={nodeFields || {}} laneFields={laneFields || []} urls={urls || {}}
                  view={panel === 'participants' && !hasSelection ? 'participants' : 'properties'}
                  onClose={() => { setPanel(null); clearSelection() }}
                  onPickLane={(id) => focusElement(id)}
                />
                )
              : null}
          </div>
        </div>
      </div>
    </CanvasContext.Provider>
  )
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

function withParam (url, key, value) {
  const target = new URL(url, window.location.origin)
  target.searchParams.set(key, value)
  return target.pathname + target.search
}

// Read-only: a click on a node with a reference navigates; editing: a
// double-click does. `bali-bpmn:open-reference` is cancelable so the host can
// handle it itself (open a tab, a drawer…).
function openReference (node, hostElement) {
  const reference = node && node.reference
  if (!reference || !reference.url) return
  const event = new CustomEvent('bali-bpmn:open-reference', { bubbles: true, cancelable: true, detail: { node_id: node.id, reference } })
  if (!(hostElement || document).dispatchEvent(event)) return
  if (window.Turbo && typeof window.Turbo.visit === 'function') window.Turbo.visit(reference.url)
  else window.location.assign(reference.url)
}
