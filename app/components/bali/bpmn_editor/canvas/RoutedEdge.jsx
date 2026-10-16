import { memo } from 'react'
import { BaseEdge } from '@xyflow/react'
import { pathWithJumps } from '../model/routing.js'
import { edgeType } from '../model/catalog.js'
import { useCanvas } from './CanvasContext.js'

// A connection drawn along the route the router computed from the document —
// not along React Flow's handle-to-handle path — so it goes around elements
// and its label rides on its longest segment.
const MARKERS = {
  sequence_flow: { end: 'bpmn-arrow', dash: undefined },
  message_flow: { end: 'bpmn-arrow-open', start: 'bpmn-circle-open', dash: '6 4' },
  association: { end: null, dash: '2 3' }
}

function RoutedEdge ({ id, data, selected }) {
  const canvas = useCanvas()
  const route = canvas.routes.get(id)
  if (!route) return null
  const { edge, issue, diff } = data
  const type = edgeType(edge)
  const marker = MARKERS[type]
  const { x: ox, y: oy } = canvas.origin
  const suffix = selected ? '-selected' : ''
  const label = edge.label
  // The label's box comes from model/edgeLabels.js: beside the line, near its source.
  const box = label && canvas.edgeLabels ? canvas.edgeLabels.get(id) : null
  const lx = box ? box.x + ox + box.w / 2 : route.label.x + ox
  const ly = box ? box.y + oy + box.h / 2 : route.label.y + oy
  const renaming = canvas.renamingId === id
  return (
    <>
      <BaseEdge
        id={id}
        path={pathWithJumps(route.points, (canvas.jumps && canvas.jumps.get(id)) || [], ox, oy)}
        className={`bpmn-edge bpmn-edge-${type}${selected ? ' is-selected' : ''}${issue ? ' has-issue' : ''}${diff ? ` bpmn-diff-${diff}` : ''}`}
        markerEnd={marker.end ? `url(#${marker.end}${suffix})` : undefined}
        markerStart={marker.start ? `url(#${marker.start}${suffix})` : undefined}
        style={{ strokeDasharray: marker.dash }}
        interactionWidth={16}
      />
      {renaming && canvas.renderEdgeRename(edge, { x: lx, y: ly })}
      {!renaming && label && (
        <g
          className='bpmn-edge-label'
          transform={`translate(${lx} ${ly})`}
          onDoubleClick={canvas.editable ? (event) => { event.stopPropagation(); canvas.startRename(id) } : undefined}
        >
          <rect x={-(box ? box.w : 30) / 2} y={-9} width={box ? box.w : 30} height={18} rx={4} />
          <text x={0} y={0} textAnchor='middle' dominantBaseline='central'>{label}</text>
        </g>
      )}
    </>
  )
}

export default memo(RoutedEdge)

// Marker definitions the edges point at. Two sets so a selected connection
// can take the selection colour (markers do not inherit the path's stroke).
export function EdgeMarkers () {
  const defs = [['', 'bpmn-marker'], ['-selected', 'bpmn-marker is-selected']]
  return (
    <svg className='bpmn-markers' width='0' height='0' aria-hidden='true'>
      <defs>
        {defs.map(([suffix, className]) => (
          <g key={suffix || 'base'} className={className}>
            <marker id={`bpmn-arrow${suffix}`} viewBox='0 0 10 10' refX='9' refY='5' markerWidth='7' markerHeight='7' orient='auto-start-reverse'>
              <path d='M0,0 L10,5 L0,10 z' className='bpmn-marker-fill' />
            </marker>
            <marker id={`bpmn-arrow-open${suffix}`} viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>
              <path d='M0,0 L10,5 L0,10 z' className='bpmn-marker-open' />
            </marker>
            <marker id={`bpmn-circle-open${suffix}`} viewBox='0 0 10 10' refX='5' refY='5' markerWidth='7' markerHeight='7'>
              <circle cx='5' cy='5' r='3.5' className='bpmn-marker-open' />
            </marker>
          </g>
        ))}
      </defs>
    </svg>
  )
}
