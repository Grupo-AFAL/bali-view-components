import { memo } from 'react'
import { Handle, NodeToolbar, Position, useStore } from '@xyflow/react'
import { NodeShape, IssueMarker } from '../shapes.jsx'
import { categoryOf, nodeSize, CATEGORY } from '../model/catalog.js'
import { nodeBox } from '../model/geometry.js'
import { nodeLabelBox, badgeBox } from '../model/labels.js'
import { textOn } from '../model/contrast.js'
import { useCanvas } from './CanvasContext.js'

const SIDES = [['top', Position.Top], ['right', Position.Right], ['bottom', Position.Bottom], ['left', Position.Left]]

// Names drawn inside the shape. A name outside it (events, gateways, data)
// is placed at model/labels.js's box — the same box the router steers
// around and the quality metric checks.
function insideClass (category, type) {
  if (category === CATEGORY.activity) return 'bpmn-label bpmn-label-inside'
  if (type === 'text_annotation') return 'bpmn-label bpmn-label-annotation'
  if (type === 'group') return 'bpmn-label bpmn-label-group'
  return null
}

function Label ({ node, name, orientation, category }) {
  const inside = insideClass(category, node.type)
  if (inside) return <div className={inside}>{name}</div>
  const label = nodeLabelBox(node, orientation)
  if (!label) return null
  const box = nodeBox(node)
  return (
    <div
      className={`bpmn-label bpmn-label-outside${category === CATEGORY.gateway ? ' text-right' : orientation === 'vertical' && category === CATEGORY.event ? ' text-left' : ' text-center'}`}
      style={{ left: label.x - box.x, top: label.y - box.y, width: label.w, WebkitLineClamp: label.lines }}
    >
      {name}
    </div>
  )
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
        {issue && (() => { const b = badgeBox({ ...node, x: 0, y: 0 }); return <IssueMarker x={b.x + b.w / 2} y={b.y + 8} /> })()}
      </svg>
      {renaming
        ? canvas.renderRename(node)
        : name && <Label node={node} name={name} orientation={canvas.orientation} category={category} />}
      {note && <span className='bpmn-note-number' style={{ '--bpmn-note-color': note.color, '--bpmn-note-text': textOn(note.color) || undefined }} title={note.text}>{note.number}</span>}
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
