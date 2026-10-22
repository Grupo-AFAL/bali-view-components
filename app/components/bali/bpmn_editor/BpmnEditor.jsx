// Root of the BPMN editor island (#1489). The DOCUMENT is the state: every
// edit is a pure function document → document (model/operations.js), React
// Flow only draws what the document says and reports gestures back, and
// undo/redo are stacks of documents (model/history.js). The whole document is
// saved to the host (hooks/useSaver.js). Contracts: docs/api/bpmn-editor.md.
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { flushSync } from 'react-dom'
import { ReactFlow, ReactFlowProvider, Background, MiniMap, ConnectionMode, EdgeLabelRenderer, useReactFlow, useKeyPress, getViewportForBounds } from '@xyflow/react'
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
import { fitOptions, fitDiagram, anchorStart, MIN_FIT_ZOOM } from './canvas/fit.js'
import { hasBadges } from './model/appearance.js'
import useRefitOnResize from './hooks/useRefitOnResize.js'
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
import { HintLayer } from './chrome/Hint.jsx'
import Stencil, { STENCIL_MIME } from './chrome/Stencil.jsx'
import { openDrawerUrl } from '../../../frontend/bali/utils/drawer.js'
import { withParams, safeUrl } from './model/urls.js'
import CompareView from './chrome/CompareView.jsx'
import { diffDocuments } from './model/diff.js'
import { DEFAULT_COMPARE_MODE, openMode, requestedComparison, shownMode } from './model/compare.js'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const EMPTY_SELECTION = { nodes: [], edges: [], lanes: [] }
const NOTICE_MS = 4800
const MAX_ZOOM = 2.5
export const NARROW_WIDTH = 768
// Mirrors Bali::BpmnEditor::Component::CHROMES (contract_test.rb).
export const CHROMES = ['full', 'minimal']
// What the wheel does. Mirror Bali::BpmnEditor::Component::WHEEL_ZOOMS (contract_test.rb).
export const WHEEL_ZOOMS = ['auto', 'true', 'false']
const IS_MAC = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent || '')

export default function BpmnEditor (props) {
  return (
    <ReactFlowProvider>
      <Editor {...props} />
    </ReactFlowProvider>
  )
}

function Editor ({
  data, editable: editableProp, autosave, lockOrientation, externalLanes = true, openIssues = false, layout: layoutMode, page, palette, legend, rules, fields, urls, i18n, hostElement,
  name, watermark, review, selectedId = '', chrome = 'full', minZoom = MIN_FIT_ZOOM, annotatable = false,
  badges = true, badgeToggle = true, badgeToggleLabel = '', wheelZoom = 'auto', compareOpen = '', compareIndex = 0, takeHostEvents
}) {
  const t = useMemo(() => translator(i18n), [i18n])
  const editable = Boolean(editableProp)
  // `chrome: :minimal` — a diagram embedded in the app's own page: the canvas
  // and its zoom bar, at the height of its container.
  const minimal = chrome === 'minimal'
  // `rules: false` — nothing is checked, nothing blocks (model/rules/engine.js).
  const validating = rules !== false
  // Notes on a read-only diagram, saved on their own (Component `annotatable:`).
  const notesOnly = !editable && Boolean(annotatable) && Boolean(urls && urls.annotations)
  // The compact layout and the print/export sheet (Component `layout:`, `page:`).
  const layoutOptions = useMemo(() => ({ mode: layoutMode === 'straight' ? 'straight' : 'compact', page: { ...LETTER, ...(page || {}) } }), [layoutMode, page])
  const policy = useMemo(() => blockPolicy(rules), [rules])
  const [arranging, setArranging] = useState(false)
  const [legendOpen, setLegendOpen] = useState(!minimal)
  const names = useMemo(() => ({
    task: t('new_task'), sub_process: t('new_sub_process'), gateway: t('new_gateway'), start: t('new_start'),
    end: t('new_end'), event: t('new_event'), annotation: t('new_annotation'), data: t('new_data')
  }), [t])
  const labels = useMemo(() => ({ yes: t('label_yes'), no: t('label_no') }), [t])
  const flow = useReactFlow()
  const wrapperRef = useRef(null)
  // React Flow mounts in an animation frame, committed at once (flushSync, so
  // its effects run there too). Its ResizeObservers are then created before
  // the frame's observers deliver. Mounted in an ordinary commit, their
  // creation (in React Flow's effects) waited for whatever flushed them next —
  // with two editors on a page, the other editor's update in the microtask
  // between two observer callbacks — and the observers born mid-delivery were
  // left undelivered: Chrome's «ResizeObserver loop completed with undelivered
  // notifications» (the pair and split view previews).
  const [canvasReady, setCanvasReady] = useState(false)
  const [pointer, setPointer] = useState(null) // over the canvas, while a connection looks for its target
  // A container with no size yet (a collapsed pane about to slide open, a
  // hidden tab) waits until it has one: React Flow warns on a 0-wide parent
  // (error 004) and its first fit would be to nothing.
  useEffect(() => {
    let observer = null
    let frame = window.requestAnimationFrame(() => {
      const element = wrapperRef.current
      const sized = () => element.clientWidth > 0 && element.clientHeight > 0
      if (!element || sized() || !window.ResizeObserver) { flushSync(() => setCanvasReady(true)); return }
      observer = new window.ResizeObserver(() => {
        if (!sized()) return
        observer.disconnect()
        frame = window.requestAnimationFrame(() => flushSync(() => setCanvasReady(true)))
      })
      observer.observe(element)
    })
    return () => { window.cancelAnimationFrame(frame); if (observer) observer.disconnect() }
  }, [])

  // ── document & history ─────────────────────────────────────────────────
  const [state, setRendered] = useState(() => history.initialHistory(normalize(data, layoutOptions)))
  const doc = state.present
  const docRef = useRef(doc)
  docRef.current = doc
  // Every change to the history goes through here, so stateRef (and docRef)
  // hold the latest committed state before React renders it: an edit made
  // while a save answers, or a 409's reset, is what the saver decides on.
  const stateRef = useRef(state)
  const setState = useCallback((update) => {
    const next = typeof update === 'function' ? update(stateRef.current) : update
    if (next === stateRef.current) return
    stateRef.current = next
    docRef.current = next.present
    setRendered(next)
  }, [])

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

  // The nodes' `appearance.badge`: shown or not (Component `badges:`), by the
  // person with the switch — which says so, `bali-bpmn:badges-change` — or by
  // the app, `bali-bpmn:badges` { visible }. Only the badge: the colour and
  // the fading stay. The canvas, the exports and the nodes' names follow it.
  const [badgesVisible, setBadgesVisible] = useState(badges !== false)
  const toggleBadges = useCallback(() => {
    setBadgesVisible(!badgesVisible)
    emit('badges-change', { visible: !badgesVisible })
  }, [badgesVisible, emit])
  // Offered only when there is something to show — re-read with each document
  // (a split view swaps the one on the right) — and unless the app fixed it.
  const docHasBadges = useMemo(() => hasBadges(doc), [doc])
  const badgeSwitch = badgeToggle !== false && docHasBadges ? { visible: badgesVisible, onToggle: toggleBadges, label: badgeToggleLabel } : null

  const saver = useSaver({
    doc,
    revision: state.revision,
    current: useCallback(() => ({ doc: stateRef.current.present, revision: stateRef.current.revision }), []),
    layoutOptions,
    urls,
    editable,
    notesOnly,
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
  const [selection, setSelection] = useState(() => (
    selectedId && state.present.nodes.some((n) => String(n.id) === String(selectedId)) ? { ...EMPTY_SELECTION, nodes: [String(selectedId)] } : EMPTY_SELECTION
  ))
  const [tool, setTool] = useState(null) // { kind: 'place', key } | { kind: 'connect', edge, source }
  const [mode, setMode] = useState('edit') // 'edit' | 'navigate'
  const [boxSelect, setBoxSelect] = useState(false)
  const [panel, setPanel] = useState(null) // null | 'participants' | 'properties' (narrow editors)
  const [paletteCollapsed, setPaletteCollapsed] = useState(false)
  // An editor narrower than NARROW_WIDTH opens with the palette, the stencil
  // and the legend folded: open, their ~250 px each covered most of a phone's
  // canvas, and «Connect» and the quick menu went under them. Opened there,
  // the palette is a layer over the canvas instead of a column beside it. Measured once, before
  // the first paint; the person opens either from then on. The canvas's own
  // chrome narrows by a container query (flow.css).
  const [narrow, setNarrow] = useState(false)
  useLayoutEffect(() => {
    const element = wrapperRef.current
    // Not the minimal chrome: it has no palette, and no toolbar to open the
    // panel from.
    if (minimal || !element || !element.clientWidth || element.clientWidth >= NARROW_WIDTH) return
    setNarrow(true)
    setPaletteCollapsed(true)
    setLegendOpen(false)
  }, [])
  const [renamingId, setRenamingId] = useState(null)
  const [highlightId, setHighlightId] = useState(null)
  const [fullscreen, setFullscreen] = useState(false)
  const [dragPositions, setDragPositions] = useState(null) // id → absolute position while dragging
  const [liveLength, setLiveLength] = useState(null) // shared lane length while one lane's end is dragged
  const [dialog, setDialog] = useState(() => (openIssues && editable ? 'pending' : null)) // null | 'pending' | 'rules'
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
  // A selection opens the properties panel while editing, or to write notes;
  // a reader's selection (a click, `selected_id:`, `bali-bpmn:select`) only marks the node.
  // Narrow, a selection does not open the properties panel by itself: it
  // would cover the whole canvas and the quick menu beside the element. The
  // view toolbar's «Properties» opens it.
  const selectionPanel = (editable || notesOnly) && (!narrow || panel === 'properties')
  const panelOpen = panel === 'participants' || (selectionPanel && (selection.nodes.length > 0 || selection.edges.length > 0 || selection.lanes.length > 0))
  const fit = useMemo(() => fitOptions({ legendOpen: legendOpen && legend && legend.length > 0, panelOpen, minZoom, minimal }), [legendOpen, legend, panelOpen, minZoom, minimal])

  // The palette the host allows, for VIS-10 (an imported element it does not offer).
  const allowed = useMemo(() => (palette && palette.items && palette.items.length ? new Set(palette.items.filter((i) => i.state === 'enabled').map((i) => i.key)) : null), [palette])
  const issueList = useMemo(() => (editable && validating ? mergeIssues(evaluate(doc, rules || {}, t, { allowed, page: layoutOptions.page }), doc.issues, doc, rules || {}) : []), [editable, validating, doc, rules, t, allowed, layoutOptions])
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

  // `bali-bpmn:selection-change` { node_id, reference, type, lane_id, lane_name }: what the PERSON picked
  // — a click, Enter or Space on a node; a click on the empty canvas or Escape
  // clears it (node_id null). What the app sets (`selected_id:`,
  // `bali-bpmn:select`) is not echoed back.
  const announceSelection = useCallback((nodeId) => {
    const node = nodeId == null ? null : docRef.current.nodes.find((n) => String(n.id) === String(nodeId))
    if (!node) { emit('selection-change', { node_id: null, reference: null }); return }
    const lane = node.lane_id == null ? null : docRef.current.lanes.find((l) => String(l.id) === String(node.lane_id))
    emit('selection-change', {
      node_id: String(node.id),
      reference: node.reference || null,
      type: node.type,
      lane_id: lane ? String(lane.id) : null,
      lane_name: lane ? lane.name || null : null
    })
  }, [emit])
  const hadNodeSelected = useRef(false)
  hadNodeSelected.current = selection.nodes.length > 0
  const clearByPerson = useCallback(() => {
    const announce = hadNodeSelected.current
    clearSelection()
    if (announce) announceSelection(null)
  }, [clearSelection, announceSelection])

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
    // Notes move nothing: no arrangement, so a reader's note never shifts the diagram.
    addNote: (targetId) => apply((d) => ops.addAnnotation(d, targetId), { arrange: false }),
    updateNote: (id, patch, coalesce) => apply((d) => ops.updateAnnotation(d, id, patch), { coalesce, arrange: false }),
    deleteNote: (id) => apply((d) => ops.deleteAnnotation(d, id), { arrange: false }),
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

  // A node picked by the person, by click or by keyboard. Reading: it is
  // selected, announced, and a linked sub-process opens unless the app took
  // `bali-bpmn:open-reference` over (preventDefault) — then the click only
  // selects. Editing: React Flow selects on a click; Enter or Space do it here.
  const activateNode = useCallback((id, { byKeyboard = false } = {}) => {
    const node = docRef.current.nodes.find((n) => String(n.id) === String(id))
    if (!node) return
    if (!editable || byKeyboard) select({ nodes: [String(node.id)] })
    announceSelection(node.id)
    if (!editable) openReference(node, hostElement)
  }, [editable, select, announceSelection, hostElement])

  const onNodeClick = useCallback((event, rfNode) => {
    if (rfNode.type !== 'bpmn') return
    if (interactive && tool && tool.kind === 'connect') {
      if (!tool.source) setTool({ ...tool, source: rfNode.id })
      else if (connectNodes(tool.source, rfNode.id, tool.edge)) setTool(null)
      event.stopPropagation()
      return
    }
    activateNode(rfNode.id)
  }, [interactive, tool, connectNodes, activateNode])

  const onNodeDoubleClick = useCallback((_event, rfNode) => {
    if (rfNode.type !== 'bpmn') return
    const node = rfNode.data.node
    if (node.type === 'sub_process' && node.reference && safeUrl(node.reference.url)) { openReference(node, hostElement); return }
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
    if (tool && tool.kind === 'connect') { setTool(null); return }
    clearByPerson()
  }, [tool, createAt, toPool, clearByPerson])

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
  const arrowRun = useRef(null) // the run of arrow presses not yet settled
  const onKeyDown = useCallback((event) => {
    if (event.defaultPrevented || /^(input|textarea|select)$/i.test(event.target.tagName) || event.target.isContentEditable) return
    const mod = event.ctrlKey || event.metaKey
    const key = event.key.toLowerCase()
    if (key === 'escape') {
      // Taken only when there was something to let go of: the page's own Esc
      // (a SplitView closing its detail) skips a prevented one, and answers the next.
      if (tool || renamingId != null || selection.nodes.length || selection.edges.length || selection.lanes.length) event.preventDefault()
      setTool(null); setRenamingId(null); clearByPerson(); return
    }
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
      // 10 px a press, 1 px with Shift. The whole run of presses is one undo
      // step (coalesce); the local arrangement waits for the key to go up.
      event.preventDefault()
      const step = event.shiftKey ? 1 : 10
      const delta = { x: key === 'arrowleft' ? -step : key === 'arrowright' ? step : 0, y: key === 'arrowup' ? -step : key === 'arrowdown' ? step : 0 }
      const coalesce = `arrows:${selection.nodes.join(',')}`
      arrowRun.current = { coalesce, ids: selection.nodes, fine: event.shiftKey || Boolean(arrowRun.current && arrowRun.current.fine) }
      apply((d) => ops.moveNodes(d, selection.nodes, delta, { policy }), { coalesce, arrange: false })
    }
  }, [interactive, undo, redo, selectAll, deleteSelection, clearByPerson, selection, apply, policy, tool, renamingId])

  // An arrow released: the run of moves settles (collisions, lanes, routes)
  // into the same undo step. Moves made with Shift keep their pixel.
  const onKeyUp = useCallback((event) => {
    if (!event.key.toLowerCase().startsWith('arrow') || !arrowRun.current) return
    const { coalesce, ids, fine } = arrowRun.current
    arrowRun.current = null
    apply((d) => ({ doc: arrange(d, { keep: fine ? new Set(ids.map(String)) : null }) }), { coalesce, arrange: false })
  }, [apply])

  useKeyboard(wrapperRef, onKeyDown, onKeyUp)

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
  // `bali-bpmn:select` { node_id }: the app moves the selection (null clears it)
  // and the node is brought into view if it is not.
  const selectFromHost = useCallback((nodeId) => {
    if (nodeId == null) { clearSelection(); return }
    const node = docRef.current.nodes.find((n) => String(n.id) === String(nodeId))
    if (!node) return
    select({ nodes: [String(node.id)] })
    revealNode(flow, wrapperRef.current, node, poolOrigin(docRef.current))
  }, [clearSelection, select, flow])

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
  // `compare_with:` — one comparison or a list the person picks from.
  const comparisons = useMemo(() => {
    const raw = review && review.compare_with
    return (Array.isArray(raw) ? raw : raw ? [raw] : []).filter((c) => c && c.document)
      .map((c) => ({ ...c, match: c.match || 'auto' }))
  }, [review])
  // Open on load with `compare_open:` / `compare_index:`; the TopBar's
  // «Compare», the comparison bar and `bali-bpmn:compare` change it, and
  // `bali-bpmn:compare-change` says what is shown.
  const [comparison, setComparison] = useState(() => ({ index: compareIndex, mode: comparisons.length ? openMode(compareOpen) : null }))
  const compare = comparisons[comparison.index] || comparisons[0] || null
  // Normalized when the comparison opens, not on load: normalize lays out a
  // document without coordinates, for a view most readers never open.
  const comparing = Boolean(comparison.mode)
  const compareBase = useMemo(() => (compare && comparing ? normalize(compare.document, layoutOptions) : null), [compare, comparing, layoutOptions])
  const compareDiff = useMemo(() => (compareBase ? diffDocuments(compareBase, doc, { match: compare.match }) : null), [compareBase, doc, compare])
  const compareShown = compareDiff ? shownMode(comparison.mode, compareDiff.sameProcess) : null
  // Opened comparing, the canvas mounted hidden, at no size, and its first fit
  // was to nothing: it fits the first time it is shown.
  const canvasFitted = useRef(!comparing)
  useEffect(() => {
    if (comparing || canvasFitted.current) return
    canvasFitted.current = true
    setTimeout(() => fitDiagram(flow, fit), 50)
  }, [comparing, flow, fit])
  // Committed at once, as a click's update is: the panes' React Flow creates
  // its ResizeObservers in that commit's effects, and an ordinary update from
  // outside React ran them inside another observer's delivery — Chrome's
  // «ResizeObserver loop», 2 runs in 8 switching to the overlay.
  const compareFromHost = useCallback((detail) => {
    flushSync(() => setComparison((current) => requestedComparison(current, detail, comparisons.length) || current))
  }, [comparisons.length])
  const reportedComparison = useRef(null)
  useEffect(() => {
    const key = compareShown ? `${comparison.index}:${compareShown}` : null
    if (key === reportedComparison.current) return
    reportedComparison.current = key
    emit('compare-change', { open: Boolean(compareShown), index: comparison.index, mode: compareShown })
  }, [compareShown, comparison.index, emit])
  // `ready` once its listeners are attached and what the app sent before is applied.
  const announceReady = useCallback(() => emit('ready', {}), [emit])
  useHostEvents(hostElement, { reload, apply, docRef, onSelect: selectFromHost, onBadges: setBadgesVisible, onCompare: compareFromHost, takeQueued: takeHostEvents, onReady: announceReady })

  // ── the wheel (Component `wheel_zoom:`) ────────────────────────────────
  // 'zoom': it zooms. 'modifier': it scrolls the page, and Ctrl + wheel (a
  // trackpad pinch arrives as that too) or ⌘ + wheel zooms. 'off': it never
  // does, the pinch included. `auto` decides by what the editor knows of its
  // own box, not by measuring the page: editable, `chrome: :minimal` (the
  // host sized the container for it) and full screen zoom; a read-only
  // diagram among the page's content scrolls the page. A page that gives a
  // read-only full-chrome editor a box of its own says so with `true`.
  const wheelMode = wheelZoom === 'true' ? 'zoom' : wheelZoom === 'false' ? 'off' : (editable || minimal || fullscreen) ? 'zoom' : 'modifier'
  // ⌘ is not a pinch for React Flow, which only zooms a modified wheel with
  // Ctrl: held, it turns the wheel's zoom on for as long as it is.
  const metaHeld = useKeyPress('Meta')
  const wheelZooms = wheelMode === 'zoom' || (wheelMode === 'modifier' && metaHeld)
  const [wheelHint, setWheelHint] = useState(false)
  const wheelHintTimer = useRef(null)
  const onCanvasWheel = useCallback((event) => {
    if (wheelMode !== 'modifier' || event.ctrlKey || event.metaKey) return
    setWheelHint(true)
    clearTimeout(wheelHintTimer.current)
    wheelHintTimer.current = setTimeout(() => setWheelHint(false), 1500)
  }, [wheelMode])
  useEffect(() => () => clearTimeout(wheelHintTimer.current), [])

  // Minimal chrome: the editor fills its container and fits again when that
  // container changes size (a split pane dragged, a drawer opened) — on every
  // frame of it, with no animation of its own: a fit that waited for the size
  // to settle, or eased towards it, left the diagram cut off at the moving
  // edge for the whole of a 300 ms slide and then jumped. Measured off the
  // canvas itself, not `fitView`: React Flow learns the new size from its own
  // ResizeObserver, which may report after this one.
  const refitLive = useCallback(() => {
    const canvasEl = wrapperRef.current && wrapperRef.current.querySelector('.react-flow')
    const nodes = flow.getNodes()
    if (!canvasEl || !canvasEl.clientWidth || !canvasEl.clientHeight || !nodes.length) return
    flow.setViewport(getViewportForBounds(flow.getNodesBounds(nodes), canvasEl.clientWidth, canvasEl.clientHeight, fit.minZoom, MAX_ZOOM, fit.padding))
    anchorStart(flow, fit)
  }, [flow, fit])
  useRefitOnResize(wrapperRef, refitLive, minimal, 0)
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
  const exports = useExports({ doc, name, watermark, tags, page: layoutOptions.page, wrapperRef, badges: badgesVisible, onError: () => notify(t('export_failed'), 'error') })

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

  // Connecting (the toolbar's «Connect», the quick menu's arrow, a connector
  // of the palette): the source stands out, a dashed line follows the pointer
  // from it, and the elements the connection may not reach are faded — not
  // the ones a gateway would make valid, which the notice then offers.
  const connecting = Boolean(tool && tool.kind === 'connect')
  const connectSource = connecting && tool.source ? String(tool.source) : null
  const connectInvalid = useMemo(() => {
    if (!connectSource) return null
    const type = (tool && tool.edge) || 'sequence_flow'
    const invalid = new Set()
    for (const n of doc.nodes) {
      const id = String(n.id)
      if (id === connectSource) continue
      const error = ops.connectionError(doc, connectSource, id, { type, policy })
      if (!error) continue
      const through = type === 'sequence_flow' && error === 'block_connection' && ops.gatewaysNeeded(doc, connectSource, id, { policy }) &&
        !ops.connectThroughGateway(doc, connectSource, id, { policy, names, labels }).error
      if (!through) invalid.add(id)
    }
    return invalid
  }, [connectSource, tool, doc, policy, names, labels])

  useEffect(() => { if (!connectSource) setPointer(null) }, [connectSource])

  const hasSelection = selection.nodes.length || selection.edges.length || selection.lanes.length
  useEffect(() => { if (!hasSelection && panel === 'properties') setPanel(null) }, [hasSelection, panel])
  const showPanel = !connecting && (panel === 'participants' || (selectionPanel && hasSelection))

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
    panelOpen: Boolean(showPanel),
    onNodeActivate: (id) => activateNode(id, { byKeyboard: true }),
    connectSource,
    connectInvalid,
    badgesVisible
  }), [edgeLabels, jumps, t, routes, origin, layout.orientation, interactive, renamingId, highlightId, renderRename, renderEdgeRename, onLaneResize, onLaneResizing, quickMenuId, renderQuickMenu, notesByElement, showPanel, activateNode, connectSource, connectInvalid, badgesVisible])

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
      <HintLayer rootRef={wrapperRef}>
      <div
        ref={wrapperRef}
        className={`bpmn-editor relative flex flex-col overflow-hidden rounded-xl border border-base-300 bg-base-100 shadow-sm outline-none ${fullscreen ? 'h-screen' : minimal ? 'is-minimal h-full min-h-60' : ''}`}
        onPointerDownCapture={() => claimKeyboard(wrapperRef.current)}
        tabIndex={-1}
      >
        {!minimal && (
          <TopBar
            t={t}
            editable={editable}
            notesOnly={notesOnly}
            statusLabel={doc.status_label}
            saveStatus={saver.status}
            autosave={autosave}
            issues={issueList}
            onIssues={() => setDialog('pending')}
            onRules={validating ? () => setDialog('rules') : null}
            history={{ undo, redo, canUndo: state.past.length > 0, canRedo: state.future.length > 0 }}
            onSave={saver.save}
            canFinalize={Boolean(urls.finalize)}
            onFinalize={finalize}
            finalizing={saver.finalizing}
            exports={exports}
            onCompare={compare ? () => setComparison((c) => ({ ...c, mode: c.mode ? null : DEFAULT_COMPARE_MODE })) : null}
            comparing={comparing}
          />
        )}
        {compareShown && (
          <div className={fullscreen || minimal ? 'min-h-0 flex-1' : 'h-[640px]'}>
            <CompareView
              t={t} base={compareBase} current={doc} diff={compareDiff} label={compare.label} mode={compareShown}
              onMode={(mode) => setComparison((c) => ({ ...c, mode }))} onExit={() => setComparison((c) => ({ ...c, mode: null }))}
              options={comparisons.map((c) => c.label)} picked={comparison.index} onPick={(index) => setComparison((c) => ({ ...c, index }))}
              badgesVisible={badgesVisible}
              wheelZoom={wheelZoom !== 'false'}
              badges={badgeToggle !== false && (docHasBadges || hasBadges(compareBase)) ? { visible: badgesVisible, onToggle: toggleBadges, label: badgeToggleLabel } : null}
            />
          </div>
        )}
        <div className={`relative flex min-h-0 ${comparing ? 'hidden' : ''} ${fullscreen || minimal ? 'flex-1' : 'h-[640px]'}`}>
          {editable && !minimal && (
            <Palette
              t={t} palette={palette} tool={tool && tool.kind === 'place' ? tool : null}
              disabled={mode !== 'edit'}
              onPick={(key) => {
                if (!key) { setTool(null); return }
                const item = PALETTE_ITEMS[key]
                setTool(item.tool === 'connect' ? { kind: 'connect', key, edge: item.edge, source: null } : { kind: 'place', key })
                // Over the canvas, the palette steps aside for the click that places it.
                if (narrow) setPaletteCollapsed(true)
              }}
              overlay={narrow}
              onAddLane={addLane}
              collapsed={paletteCollapsed}
              onToggle={() => setPaletteCollapsed((c) => !c)}
            />
          )}
          <div
            className={`bpmn-canvas relative h-full min-w-0 flex-1 ${interactive ? 'is-editable' : 'is-readonly'}${connectSource ? ' has-connect-source' : ''} ${tool && tool.kind === 'place' ? 'is-placing' : ''} ${tool && tool.kind === 'connect' ? 'is-connecting' : ''} ${showPanel ? 'has-panel' : ''} ${quickMenuId ? 'has-quick-menu' : ''} ${arranging ? 'is-arranging' : ''}`}
            onDragOver={(e) => { if (interactive && (e.dataTransfer.types.includes(PALETTE_MIME) || e.dataTransfer.types.includes(STENCIL_MIME))) { e.preventDefault(); e.dataTransfer.dropEffect = 'copy' } }}
            onDrop={onDrop}
            onPointerDown={(e) => { if (!/^(input|textarea|select|button)$/i.test(e.target.tagName)) wrapperRef.current?.focus({ preventScroll: true }) }}
            onPointerMove={connectSource ? (e) => { const r = e.currentTarget.getBoundingClientRect(); setPointer({ x: e.clientX - r.left, y: e.clientY - r.top }) } : undefined}
            onWheel={onCanvasWheel}
          >
            <EdgeMarkers />
            {wheelHint && (
              <div className='bpmn-chrome bpmn-wheel-hint' role='status' data-testid='bpmn-wheel-hint'>
                {t(IS_MAC ? 'wheel_hint_meta' : 'wheel_hint_ctrl')}
              </div>
            )}
            {connecting && (
              <div className='bpmn-chrome bpmn-connect-banner' role='status' data-testid='bpmn-connect-banner'>
                <Icon name='arrowRight' size={13} />
                <span>{t(connectSource ? 'connect_banner_target' : 'connect_banner_source')}</span>
                <button type='button' className='btn btn-ghost btn-xs' onClick={() => setTool(null)}>{t('connect_cancel')}</button>
              </div>
            )}
            {connectSource && pointer && <ConnectGuide flow={flow} doc={doc} sourceId={connectSource} pointer={pointer} />}
            {canvasReady && (
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
              // The editor's own keyboard (useKeyboard) moves the selection with the
              // arrows; React Flow's would move a focused node behind its back.
              disableKeyboardA11y
              selectionKeyCode='Shift'
              multiSelectionKeyCode={['Shift', 'Meta', 'Control']}
              panOnDrag={!(interactive && boxSelect)}
              selectionOnDrag={interactive && boxSelect}
              fitView
              fitViewOptions={fit}
              onInit={(instance) => setTimeout(() => anchorStart(instance, fit), 60)}
              minZoom={Math.min(0.1, minZoom)}
              maxZoom={MAX_ZOOM}
              zoomOnDoubleClick={false}
              zoomOnScroll={wheelZooms}
              preventScrolling={wheelZooms}
              zoomOnPinch={wheelMode !== 'off'}
            >
              <Background gap={20} size={1} />
              {!minimal && <MiniMap className='bpmn-chrome' nodeColor={minimapColor} pannable zoomable ariaLabel={t('minimap')} />}
              {!minimal && (
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
              )}
              {!minimal && (
                <ViewToolbar
                  t={t}
                  editable={editable}
                  onParticipants={doc.lanes.length ? () => setPanel((p) => (p === 'participants' ? null : 'participants')) : null}
                  participantsOpen={panel === 'participants'}
                  onProperties={narrow && (editable || notesOnly) && hasSelection ? () => setPanel((p) => (p === 'properties' ? null : 'properties')) : null}
                  propertiesOpen={panel === 'properties'}
                  navigating={mode === 'navigate'}
                  onNavigate={() => { setMode((m) => (m === 'navigate' ? 'edit' : 'navigate')); setTool(null) }}
                  fullscreen={fullscreen}
                  onFullscreen={toggleFullscreen}
                  badges={badgeSwitch}
                />
              )}
              <Legend t={t} entries={legendEntries} open={legendOpen} onToggle={setLegendOpen} />
              {interactive && !showPanel && !minimal && <Stencil t={t} items={doc.stencil} startOpen={!narrow} />}
              <ZoomBar t={t} fit={fit} onSelectAll={interactive && !minimal ? selectAll : null} selectedCount={interactive ? selectedCount : 0} boxSelect={boxSelect} onBoxSelect={interactive ? () => setBoxSelect((b) => !b) : null} badges={minimal ? badgeSwitch : null} />
            </ReactFlow>
            )}
            <Notices notices={notices} t={t} onDismiss={(id) => setNotices((list) => list.filter((n) => n.id !== id))} />
            {showPanel
              ? (
                <PropertiesPanel
                  t={t} doc={doc} selection={selection} api={api} editable={interactive} notesEditable={notesOnly}
                  nodeFields={(fields && fields.nodes) || {}} laneFields={(fields && fields.lanes) || []} urls={urls || {}}
                  externalLanes={externalLanes}
                  view={panel === 'participants' && !hasSelection ? 'participants' : 'properties'}
                  onClose={() => { setPanel(null); clearByPerson() }}
                  onPickLane={(id) => focusElement(id)}
                  annotationTags={tags}
                />
                )
              : null}
          </div>
        </div>
        {!comparing && !minimal && (
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
      </HintLayer>
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
  if (!reference || !safeUrl(reference.url)) return false
  const event = new CustomEvent('bali-bpmn:open-reference', { bubbles: true, cancelable: true, detail: { node_id: node.id, reference } })
  return (hostElement || document).dispatchEvent(event)
}

function openReference (node, hostElement) {
  if (!announceOpenReference(node, hostElement)) return
  const url = safeUrl(node.reference.url)
  if (window.Turbo && typeof window.Turbo.visit === 'function') window.Turbo.visit(url)
  else window.location.assign(url)
}

// Brings a node into view when it is not, at the zoom the reader chose.
function revealNode (flow, wrapper, node, origin) {
  const pane = wrapper && wrapper.querySelector('.react-flow')
  if (!pane) return
  const { x, y, zoom } = flow.getViewport()
  const box = nodeBox(node)
  const left = (origin.x + box.x) * zoom + x
  const top = (origin.y + box.y) * zoom + y
  const { width, height } = pane.getBoundingClientRect()
  if (left >= 0 && top >= 0 && left + box.w * zoom <= width && top + box.h * zoom <= height) return
  flow.setCenter(origin.x + box.cx, origin.y + box.cy, { zoom, duration: 300 })
}

// The dashed line from the connection's source to the pointer, in the
// canvas' own pixels (the source's centre is projected through the viewport).
function ConnectGuide ({ flow, doc, sourceId, pointer }) {
  const node = doc.nodes.find((n) => String(n.id) === sourceId)
  if (!node) return null
  const o = poolOrigin(doc)
  const box = nodeBox(node)
  const { x, y, zoom } = flow.getViewport()
  const from = { x: (o.x + box.cx) * zoom + x, y: (o.y + box.cy) * zoom + y }
  return (
    <svg className='bpmn-connect-guide' data-testid='bpmn-connect-guide' aria-hidden='true'>
      <line x1={from.x} y1={from.y} x2={pointer.x} y2={pointer.y} />
    </svg>
  )
}
