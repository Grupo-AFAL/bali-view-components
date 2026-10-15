import { memo } from 'react'
import { Handle, NodeToolbar, Position, useStore } from '@xyflow/react'
import { NodeShape, IssueMarker } from '../shapes.jsx'
import { categoryOf, nodeSize, CATEGORY } from '../model/catalog.js'
import { useCanvas } from './CanvasContext.js'

const SIDES = [['top', Position.Top], ['right', Position.Right], ['bottom', Position.Bottom], ['left', Position.Left]]

// Where the name goes: inside activities and annotations, under the shape for
// events and data, above and to the right of a gateway — where the lines
// leaving it do not run — and on top of a group.
function labelClass (category, type, orientation) {
  if (category === CATEGORY.activity) return 'bpmn-label bpmn-label-inside'
  if (type === 'text_annotation') return 'bpmn-label bpmn-label-annotation'
  if (type === 'group') return 'bpmn-label bpmn-label-group'
  if (category === CATEGORY.gateway) return 'bpmn-label bpmn-label-gateway'
  // In vertical lanes the flow leaves an event downwards, through the label.
  return orientation === 'vertical' ? 'bpmn-label bpmn-label-side' : 'bpmn-label bpmn-label-below'
}

// Width the quick menu needs, and the properties panel that covers the right
// edge of the canvas while it is open (w-72 + its gap).
const MENU_WIDTH = 250
const PANEL_WIDTH = 300

// The quick menu goes to the right of the node, or to its left when there is
// no room before the canvas edge (or the properties panel). Only the selected
// node mounts this, so only it follows the viewport.
function QuickMenuToolbar ({ x, width, children, panelOpen }) {
  const right = useStore((s) => (x + width) * s.transform[2] + s.transform[0])
  const paneWidth = useStore((s) => s.width)
  const room = paneWidth - (panelOpen ? PANEL_WIDTH : 0) - right
  return (
    <NodeToolbar isVisible position={room < MENU_WIDTH ? Position.Left : Position.Right} align='start' offset={14}>
      {children}
    </NodeToolbar>
  )
}

function FlowNode ({ id, data, selected, positionAbsoluteX }) {
  const canvas = useCanvas()
  const { node, external, issue, diff } = data
  const note = canvas.notesByElement && canvas.notesByElement.get(id)
  const size = nodeSize(node)
  const box = { w: size.width, h: size.height }
  const category = categoryOf(node)
  const renaming = canvas.renamingId === id
  const name = node.name || ''
  const linked = node.type === 'sub_process' && node.reference && node.reference.url
  return (
    <div
      className={`bpmn-node bpmn-node-${category}${selected ? ' is-selected' : ''}${canvas.highlightId === id ? ' is-highlighted' : ''}${diff ? ` bpmn-diff-${diff}` : ''}`}
      data-node-type={node.type}
      data-testid='bpmn-node'
      title={name || undefined}
    >
      <svg className='bpmn-node-shape' width={box.w} height={box.h} aria-hidden='true'>
        <NodeShape node={node} width={box.w} height={box.h} external={external} />
        {issue && <IssueMarker x={box.w - 2} y={2} />}
      </svg>
      {renaming
        ? canvas.renderRename(node)
        : name && <div className={labelClass(category, node.type, canvas.orientation)}>{name}</div>}
      {note && <span className='bpmn-note-number' style={{ '--bpmn-note-color': note.color }} title={note.text}>{note.number}</span>}
      {linked && !canvas.editable && <span className='bpmn-node-link' aria-hidden='true'>↗</span>}
      {canvas.quickMenuId === id && (
        <QuickMenuToolbar x={positionAbsoluteX} width={box.w} panelOpen={canvas.panelOpen}>
          {canvas.renderQuickMenu(node)}
        </QuickMenuToolbar>
      )}
      {SIDES.map(([side, position]) => (
        <Handle
          key={side}
          id={side}
          type='source'
          position={position}
          isConnectable={canvas.editable && canvas.connectable}
          className='bpmn-handle'
        />
      ))}
    </div>
  )
}

export default memo(FlowNode)
