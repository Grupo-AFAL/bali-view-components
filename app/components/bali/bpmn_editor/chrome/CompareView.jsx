import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { ReactFlow, ReactFlowProvider, Background, ConnectionMode } from '@xyflow/react'
import { layoutLanes, poolOrigin } from '../model/geometry.js'
import { routeAll, findJumps } from '../model/routing.js'
import { placeEdgeLabels } from '../model/edgeLabels.js'
import { buildRfNodes, buildRfEdges, laneNodeId, isLaneNodeId, laneIdOf } from '../model/flow.js'
import { changesOf, detailOf } from '../model/compareChanges.js'
import { overlayView, summaryText } from '../model/diff.js'
import { DIFF_MARKS, diffMark } from '../canvas/diffMarks.js'
import useRefitOnResize from '../hooks/useRefitOnResize.js'
import { CanvasContext } from '../canvas/CanvasContext.js'
import FlowNode from '../canvas/FlowNode.jsx'
import LaneNode from '../canvas/LaneNode.jsx'
import RoutedEdge, { EdgeMarkers } from '../canvas/RoutedEdge.jsx'
import ZoomBar from './ZoomBar.jsx'
import Icon from './icons.jsx'
import BadgeSwitch from './BadgeSwitch.jsx'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const noop = () => {}
const FIT = { padding: 0.12 }
const sameViewport = (a, b) => a && b && Math.abs(a.x - b.x) < 0.5 && Math.abs(a.y - b.y) < 0.5 && Math.abs(a.zoom - b.zoom) < 0.001

// One version drawn read-only.
//   focus ({ id, at }): the element to bring to the middle and highlight — a
//     React Flow node id (a node's, or `lane:<id>`);
//   peerId: the element the other pane points at (its counterpart), highlighted;
//   onPoint (id | null): the person points at an element (hover, click);
//   onInstance / onViewport: for keeping two panes' views together.
function Diagram ({ doc, diff, t, caption, focus, peerId, onPoint = noop, onInstance = noop, onViewport = noop, side, badgesVisible = true, wheelZoom = true }) {
  const layout = useMemo(() => layoutLanes(doc), [doc])
  const routes = useMemo(() => routeAll(doc), [doc])
  const nodes = useMemo(() => buildRfNodes(doc, { layout, diff }), [doc, layout, diff])
  const edges = useMemo(() => buildRfEdges(doc, routes, { diff }), [doc, routes, diff])
  const [focusId, setFocusId] = useState(null)
  const highlightId = focusId || peerId || null
  const canvas = useMemo(() => ({
    t, routes, origin: poolOrigin(doc), orientation: layout.orientation, editable: false, connectable: false,
    renamingId: null, highlightId, startRename: noop, renderRename: noop, renderEdgeRename: noop,
    onLaneResize: noop, onLaneResizing: noop, quickMenuId: null, renderQuickMenu: noop,
    edgeLabels: placeEdgeLabels(doc, routes), jumps: findJumps(routes), badgesVisible
  }), [t, routes, doc, layout.orientation, highlightId, badgesVisible])
  // Two panes split the width after they mount (and again whenever the
  // editor resizes): each fits its diagram to the size it really got.
  const pane = useRef(null)
  const instance = useRef(null)
  // A pane fitting itself is not the person moving it: the other pane does
  // not follow its own fit (`fitting` while it lasts).
  const fitting = useRef(true)
  const fit = useCallback(() => {
    const flow = instance.current
    if (!flow) return
    fitting.current = true
    flow.fitView(FIT)
    setTimeout(() => { fitting.current = false }, 120)
  }, [])
  useRefitOnResize(pane, fit)
  useEffect(() => {
    const flow = instance.current
    const node = focus && flow && flow.getNode(focus.id)
    if (!node) return undefined
    const width = node.width || (node.measured && node.measured.width) || 0
    const height = node.height || (node.measured && node.measured.height) || 0
    flow.setCenter(node.position.x + width / 2, node.position.y + height / 2, { zoom: Math.max(flow.getZoom(), 0.9), duration: 300 })
    setFocusId(focus.id)
    const timer = setTimeout(() => setFocusId(null), 2400)
    return () => clearTimeout(timer)
  }, [focus])
  return (
    <CanvasContext.Provider value={canvas}>
      <div ref={pane} className='bpmn-canvas is-readonly relative min-h-0 min-w-0 flex-1' data-testid='bpmn-compare-pane' data-side={side}>
        <EdgeMarkers />
        {caption && <span className='badge badge-ghost absolute left-3 top-3 z-10'>{caption}</span>}
        <ReactFlow
          nodes={nodes} edges={edges} nodeTypes={nodeTypes} edgeTypes={edgeTypes} connectionMode={ConnectionMode.Loose}
          nodesDraggable={false} nodesConnectable={false} elementsSelectable={false} fitView fitViewOptions={FIT}
          onInit={(flow) => { instance.current = flow; onInstance(flow); setTimeout(fit, 60) }}
          onMove={(_event, viewport) => { if (!fitting.current) onViewport(viewport) }}
          onNodeMouseEnter={(_event, node) => onPoint(node.id)}
          onNodeMouseLeave={() => onPoint(null)}
          onNodeClick={(_event, node) => onPoint(node.id, true)}
          minZoom={0.1} maxZoom={2.5}
          // A comparison is a viewer of its own: the wheel zooms (and, synced, both panes), unless `wheel_zoom: false`.
          zoomOnScroll={wheelZoom} zoomOnPinch={wheelZoom}
        >
          <Background gap={20} size={1} />
          <ZoomBar t={t} fit={FIT} />
        </ReactFlow>
      </div>
    </CanvasContext.Provider>
  )
}

// The counterpart of a React Flow node id of one side, in the other: the
// element it paired with (model/diff.js identity / lanePairs), or null.
function counterpartOf (id, side, diff) {
  if (!id) return null
  const lane = isLaneNodeId(id)
  const raw = lane ? laneIdOf(id) : String(id)
  const pairs = lane ? diff.lanePairs : diff.identity // base id → current id
  let other = null
  if (side === 'base') other = pairs.get(raw) || null
  else for (const [baseId, currentId] of pairs) if (currentId === raw) { other = baseId; break }
  return other == null ? null : lane ? laneNodeId(other) : other
}

// Comparing the document with another document (`compare_with:`, one or a
// list to pick from): what was added, removed and changed — by colour AND by
// a mark (+, −, ✎, ⇄ for a step moved to another lane), never by colour
// alone. Side by side by default, the two panes' zoom and panning kept
// together («Sync»); over one canvas only for versions of one process
// (diff.sameProcess), where one drawing reads true. Pointing at an element
// highlights its counterpart in the other pane; «Only changes» fades what did
// not change. The summary lists every change with its detail; picking one
// brings it to the middle and highlights it. Read-only while it is on.
export default function CompareView ({ t, base, current, diff, label, mode: view, onMode, onExit, options = [], picked = 0, onPick = noop, badges = null, badgesVisible = true, wheelZoom = true }) {
  const overlay = useMemo(() => overlayView(base, current, diff), [base, current, diff])
  const entries = useMemo(() => changesOf(base, current, diff, overlay), [base, current, diff, overlay])
  const [focus, setFocus] = useState(null)
  const [sync, setSync] = useState(true)
  const [onlyChanges, setOnlyChanges] = useState(false)
  const [pointed, setPointed] = useState(null) // { side, id }
  const pick = (entry) => setFocus({ side: view === 'side_by_side' ? entry.side : 'overlay', id: view === 'side_by_side' ? entry.id : entry.overlayId, at: Date.now() })
  const focusFor = (side) => (focus && focus.side === side ? focus : null)
  const markOf = (entry) => DIFF_MARKS[diffMark(entry.state, entry.reasons)]
  const nameOf = (element) => element.name || t('compare_unnamed')

  // The two panes' views, kept together while «Sync» is on: a move of one is
  // the other's, unless the other already shows it (which ends the echo).
  const flows = useRef({})
  const syncRef = useRef(sync)
  syncRef.current = sync
  const onInstance = useCallback((side) => (flow) => { flows.current[side] = flow }, [])
  const instanceOf = useMemo(() => ({ base: onInstance('base'), current: onInstance('current') }), [onInstance])
  const follow = useCallback((side) => (viewport) => {
    if (!syncRef.current) return
    const other = flows.current[side === 'base' ? 'current' : 'base']
    if (other && !sameViewport(other.getViewport(), viewport)) other.setViewport(viewport)
  }, [])
  const followOf = useMemo(() => ({ base: follow('base'), current: follow('current') }), [follow])
  const pointOf = useMemo(() => ({ base: (id) => setPointed(id ? { side: 'base', id } : null), current: (id) => setPointed(id ? { side: 'current', id } : null) }), [])
  const peerFor = (side) => (pointed && pointed.side !== side ? counterpartOf(pointed.id, pointed.side, diff) : null)
  useEffect(() => { setPointed(null) }, [base, current])

  return (
    <div className={`bpmn-compare flex h-full flex-col${onlyChanges ? ' is-only-changes' : ''}`} data-testid='bpmn-compare'>
      <div className='bpmn-chrome flex flex-wrap items-center gap-3 border-b border-base-300 px-3 py-2 text-sm'>
        {options.length > 1
          ? (
            <label className='flex items-center gap-2'>
              <span className='font-semibold'>{t('compare_against')}</span>
              <select className='select select-sm w-auto' value={picked} onChange={(e) => onPick(Number(e.target.value))} data-testid='bpmn-compare-pick'>
                {options.map((option, i) => <option key={i} value={i}>{option}</option>)}
              </select>
            </label>
            )
          : <span className='font-semibold'>{t('compare_with', { label })}</span>}
        <details className='bpmn-compare-changes relative' data-testid='bpmn-compare-summary'>
          <summary className='cursor-pointer text-base-content/70'>{summaryText(t, diff.summary)}</summary>
          <ul className='absolute left-0 top-full z-20 mt-1 max-h-80 w-80 overflow-y-auto rounded-lg border border-base-300 bg-base-100 p-1 shadow-lg' data-testid='bpmn-compare-changes'>
            {entries.length === 0 && <li className='px-2 py-1 text-xs text-base-content/60'>{t('compare_none')}</li>}
            {entries.map((entry) => {
              const mark = markOf(entry)
              const details = detailOf(entry, t)
              return (
                <li key={entry.key}>
                  <button type='button' className='flex w-full items-start gap-2 rounded px-2 py-1 text-left text-xs hover:bg-base-200' data-change={entry.key} onClick={() => pick(entry)}>
                    <span className={`bpmn-diff-chip is-${mark.tone}`} aria-hidden='true'>{mark.symbol}</span>
                    <span className='flex min-w-0 grow flex-col'>
                      <span className='truncate'>{entry.kind === 'lane' ? `${t('compare_lane')}: ${nameOf(entry.element)}` : nameOf(entry.element)}</span>
                      {details.map((d) => <span key={d} className='text-base-content/60' data-testid='bpmn-compare-detail'>{d}</span>)}
                    </span>
                    <span className='shrink-0 text-base-content/60'>{t(mark.label)}</span>
                  </button>
                </li>
              )
            })}
          </ul>
        </details>
        {diff.match !== 'id' && !diff.sameProcess && <span className='text-xs text-base-content/60' data-testid='bpmn-compare-by-name'>{t('compare_by_name')}</span>}
        <span className='flex flex-wrap items-center gap-2 text-xs' data-testid='bpmn-compare-legend'>
          {['added', 'removed', 'changed', 'moved'].map((key) => (
            <span key={key} className='flex items-center gap-1'>
              <span className={`bpmn-diff-chip is-${DIFF_MARKS[key].tone}`} aria-hidden='true'>{DIFF_MARKS[key].symbol}</span>{t(DIFF_MARKS[key].label)}
            </span>
          ))}
        </span>
        <span className='grow' />
        {badges && <BadgeSwitch t={t} label={badges.label} visible={badges.visible} onToggle={badges.onToggle} />}
        <label className='flex cursor-pointer items-center gap-1 text-xs'>
          <input type='checkbox' className='toggle toggle-xs' checked={onlyChanges} onChange={(e) => setOnlyChanges(e.target.checked)} data-testid='bpmn-compare-only-changes' />
          {t('compare_only_changes')}
        </label>
        {view === 'side_by_side' && (
          <label className='flex cursor-pointer items-center gap-1 text-xs'>
            <input type='checkbox' className='toggle toggle-xs' checked={sync} onChange={(e) => setSync(e.target.checked)} data-testid='bpmn-compare-sync' />
            {t('compare_sync')}
          </label>
        )}
        {diff.sameProcess && (
          <div className='join' data-testid='bpmn-compare-modes'>
            {['side_by_side', 'overlay'].map((m) => (
              <button key={m} type='button' className={`btn btn-xs join-item ${view === m ? 'btn-primary' : 'btn-outline'}`} onClick={() => onMode(m)}>{t(`compare_${m}`)}</button>
            ))}
          </div>
        )}
        <button type='button' className='btn btn-ghost btn-xs gap-1' onClick={onExit} data-testid='bpmn-compare-exit'><Icon name='x' size={12} />{t('compare_exit')}</button>
      </div>
      {/* Side by side on a phone: one above the other, each still fitting its pane. */}
      <div className={`flex min-h-0 flex-1 ${view === 'side_by_side' ? 'flex-col sm:flex-row' : ''}`}>
        {view === 'side_by_side'
          ? (
            <>
              <ReactFlowProvider key={`base-${picked}`}>
                <Diagram badgesVisible={badgesVisible} wheelZoom={wheelZoom}
                  doc={base} diff={diff.base} t={t} side='base' caption={`${t('compare_base')} · ${label}`} focus={focusFor('base')}
                  peerId={peerFor('base')} onPoint={pointOf.base} onInstance={instanceOf.base} onViewport={followOf.base}
                />
              </ReactFlowProvider>
              <span className='h-px bg-base-300 sm:h-auto sm:w-px' />
              <ReactFlowProvider key='current'>
                <Diagram badgesVisible={badgesVisible} wheelZoom={wheelZoom}
                  doc={current} diff={diff.current} t={t} side='current' caption={t('compare_current')} focus={focusFor('current')}
                  peerId={peerFor('current')} onPoint={pointOf.current} onInstance={instanceOf.current} onViewport={followOf.current}
                />
              </ReactFlowProvider>
            </>
            )
          : <ReactFlowProvider><Diagram badgesVisible={badgesVisible} wheelZoom={wheelZoom} doc={overlay.doc} diff={overlay.diff} t={t} side='overlay' focus={focusFor('overlay')} /></ReactFlowProvider>}
      </div>
    </div>
  )
}
