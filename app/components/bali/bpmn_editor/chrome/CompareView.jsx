import { useMemo } from 'react'
import { ReactFlow, ReactFlowProvider, Background, ConnectionMode } from '@xyflow/react'
import { layoutLanes, poolOrigin } from '../model/geometry.js'
import { routeAll } from '../model/routing.js'
import { buildRfNodes, buildRfEdges } from '../model/flow.js'
import { diffDocuments, overlayDocument } from '../model/diff.js'
import { CanvasContext } from '../canvas/CanvasContext.js'
import FlowNode from '../canvas/FlowNode.jsx'
import LaneNode from '../canvas/LaneNode.jsx'
import RoutedEdge, { EdgeMarkers } from '../canvas/RoutedEdge.jsx'
import ZoomBar from './ZoomBar.jsx'
import Icon from './icons.jsx'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const noop = () => {}

function Diagram ({ doc, diff, t, caption }) {
  const layout = useMemo(() => layoutLanes(doc), [doc])
  const routes = useMemo(() => routeAll(doc), [doc])
  const nodes = useMemo(() => buildRfNodes(doc, { layout, diff }), [doc, layout, diff])
  const edges = useMemo(() => buildRfEdges(doc, routes, { diff }), [doc, routes, diff])
  const canvas = useMemo(() => ({
    t, routes, origin: poolOrigin(doc), orientation: layout.orientation, editable: false, connectable: false,
    renamingId: null, highlightId: null, startRename: noop, renderRename: noop, renderEdgeRename: noop,
    onLaneResize: noop, onLaneResizing: noop, quickMenuId: null, renderQuickMenu: noop
  }), [t, routes, doc, layout.orientation])
  return (
    <CanvasContext.Provider value={canvas}>
      <div className='bpmn-canvas is-readonly relative h-full min-w-0 flex-1'>
        <EdgeMarkers />
        {caption && <span className='badge badge-ghost absolute left-3 top-3 z-10'>{caption}</span>}
        <ReactFlow
          nodes={nodes} edges={edges} nodeTypes={nodeTypes} edgeTypes={edgeTypes} connectionMode={ConnectionMode.Loose}
          nodesDraggable={false} nodesConnectable={false} elementsSelectable={false} fitView fitViewOptions={{ padding: 0.12 }}
          // Two canvases mount in the same frame and the first measures its
          // pane before the flex layout splits the width: fit again once laid out.
          onInit={(instance) => setTimeout(() => instance.fitView({ padding: 0.12 }), 60)}
          minZoom={0.1} maxZoom={2.5}
        >
          <Background gap={20} size={1} />
          <ZoomBar t={t} />
        </ReactFlow>
      </div>
    </CanvasContext.Provider>
  )
}

// Comparing the document with another version (`compare_with:`): what was
// added in green, removed in red, changed in amber — over one canvas or with
// the two versions side by side. Read-only while it is on.
export default function CompareView ({ t, base, current, label, mode, onMode, onExit }) {
  const diff = useMemo(() => diffDocuments(base, current), [base, current])
  const overlay = useMemo(() => overlayDocument(base, current), [base, current])
  const baseDiff = useMemo(() => ({ nodes: Object.fromEntries(Object.entries(diff.nodes).filter(([, s]) => s !== 'added')), edges: Object.fromEntries(Object.entries(diff.edges).filter(([, s]) => s !== 'added')), lanes: {} }), [diff])
  return (
    <div className='flex h-full flex-col' data-testid='bpmn-compare'>
      <div className='bpmn-chrome flex flex-wrap items-center gap-3 border-b border-base-300 px-3 py-2 text-sm'>
        <span className='font-semibold'>{t('compare_with', { label })}</span>
        <span className='text-base-content/70'>{t('compare_summary', diff.summary)}</span>
        <span className='flex items-center gap-2 text-xs'>
          <span className='badge badge-success badge-xs' />{t('compare_added')}
          <span className='badge badge-error badge-xs' />{t('compare_removed')}
          <span className='badge badge-warning badge-xs' />{t('compare_changed')}
        </span>
        <span className='grow' />
        <div className='join'>
          {['overlay', 'side_by_side'].map((m) => (
            <button key={m} type='button' className={`btn btn-xs join-item ${mode === m ? 'btn-primary' : 'btn-outline'}`} onClick={() => onMode(m)}>{t(`compare_${m}`)}</button>
          ))}
        </div>
        <button type='button' className='btn btn-ghost btn-xs gap-1' onClick={onExit}><Icon name='x' size={12} />{t('compare_exit')}</button>
      </div>
      <div className='flex min-h-0 flex-1'>
        {mode === 'side_by_side'
          ? (
            <>
              <ReactFlowProvider><Diagram doc={base} diff={baseDiff} t={t} caption={`${t('compare_base')} · ${label}`} /></ReactFlowProvider>
              <span className='w-px bg-base-300' />
              <ReactFlowProvider><Diagram doc={current} diff={diff} t={t} caption={t('compare_current')} /></ReactFlowProvider>
            </>
            )
          : <ReactFlowProvider><Diagram doc={overlay} diff={diff} t={t} /></ReactFlowProvider>}
      </div>
    </div>
  )
}
