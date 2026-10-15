// Root of the BPMN editor island (#1489). The DOCUMENT is the state: every
// edit is a pure function document → document (model/operations.js), React
// Flow only draws what the document says, and undo/redo are stacks of
// documents. See docs/api/bpmn-editor.md for the data and save contracts.
import { useCallback, useMemo, useState } from 'react'
import { ReactFlow, ReactFlowProvider, Background, MiniMap, ConnectionMode } from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import './flow.css'
import { translator } from './i18n.js'
import { normalize } from './model/document.js'
import { layoutLanes } from './model/geometry.js'
import { routeAll } from './model/routing.js'
import { buildRfNodes, buildRfEdges } from './model/flow.js'
import { CanvasContext } from './canvas/CanvasContext.js'
import FlowNode from './canvas/FlowNode.jsx'
import LaneNode from './canvas/LaneNode.jsx'
import RoutedEdge, { EdgeMarkers } from './canvas/RoutedEdge.jsx'
import { minimapColor } from './canvas/minimap.js'
import ZoomBar from './chrome/ZoomBar.jsx'

const nodeTypes = { bpmn: FlowNode, lane: LaneNode }
const edgeTypes = { routed: RoutedEdge }
const noop = () => {}

export default function BpmnEditor (props) {
  return (
    <ReactFlowProvider>
      <Editor {...props} />
    </ReactFlowProvider>
  )
}

function Editor ({ data, readOnlyNotice, i18n, hostElement }) {
  const t = useMemo(() => translator(i18n), [i18n])
  const [doc] = useState(() => normalize(data))
  const layout = useMemo(() => layoutLanes(doc), [doc])
  const routes = useMemo(() => routeAll(doc), [doc])
  const nodes = useMemo(() => buildRfNodes(doc, { layout }), [doc, layout])
  const edges = useMemo(() => buildRfEdges(doc, routes), [doc, routes])
  const origin = useMemo(() => ({ x: Number(doc.pool.x) || 0, y: Number(doc.pool.y) || 0 }), [doc])

  const openReference = useCallback((node) => {
    const reference = node.reference
    if (!reference || !reference.url) return
    const event = new CustomEvent('bali-bpmn:open-reference', {
      bubbles: true, cancelable: true, detail: { node_id: node.id, reference }
    })
    if (!(hostElement || document).dispatchEvent(event)) return
    if (window.Turbo && typeof window.Turbo.visit === 'function') window.Turbo.visit(reference.url)
    else window.location.assign(reference.url)
  }, [hostElement])

  const canvas = useMemo(() => ({
    t,
    routes,
    origin,
    orientation: layout.orientation,
    editable: false,
    connectable: false,
    renamingId: null,
    highlightId: null,
    startRename: noop,
    renderRename: noop,
    renderEdgeRename: noop,
    onLaneResize: noop,
    onLaneResizing: noop
  }), [t, routes, origin, layout.orientation])

  const onNodeClick = useCallback((_event, rfNode) => {
    if (rfNode.type === 'bpmn') openReference(rfNode.data.node)
  }, [openReference])

  return (
    <CanvasContext.Provider value={canvas}>
      <div className='bpmn-editor flex flex-col overflow-hidden rounded-xl border border-base-300 bg-base-100 shadow-sm'>
        {readOnlyNotice && (
          <div className='bpmn-chrome border-b border-base-300 bg-base-200 px-4 py-2 text-sm' role='status'>
            {readOnlyNotice}
          </div>
        )}
        <div className='bpmn-canvas is-readonly h-[620px]'>
          <EdgeMarkers />
          <ReactFlow
            nodes={nodes}
            edges={edges}
            nodeTypes={nodeTypes}
            edgeTypes={edgeTypes}
            connectionMode={ConnectionMode.Loose}
            nodesDraggable={false}
            nodesConnectable={false}
            elementsSelectable={false}
            onNodeClick={onNodeClick}
            fitView
            fitViewOptions={{ padding: 0.12 }}
            minZoom={0.1}
            maxZoom={2.5}
          >
            <Background gap={20} size={1} />
            <MiniMap className='bpmn-chrome' nodeColor={minimapColor} pannable zoomable ariaLabel={t('minimap')} />
            <ZoomBar t={t} />
          </ReactFlow>
        </div>
      </div>
    </CanvasContext.Provider>
  )
}
