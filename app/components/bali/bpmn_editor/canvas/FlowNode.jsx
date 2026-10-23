import { memo, useLayoutEffect, useRef, useState } from 'react'
import { Handle, NodeToolbar, Position, useStore } from '@xyflow/react'
import { NodeShape, IssueMarker, AppearanceMark } from '../shapes.jsx'
import { appearanceOf } from '../model/appearance.js'
import { DIFF_MARKS, diffMark } from './diffMarks.js'
import { categoryOf, nodeSize, CATEGORY } from '../model/catalog.js'
import { nodeBox } from '../model/geometry.js'
import { nodeLabelBox, badgeBox, insideLabelBox, badgeTabBox } from '../model/labels.js'
import { textOn } from '../model/contrast.js'
import { safeUrl } from '../model/urls.js'
import { useCanvas } from './CanvasContext.js'

const SIDES = [['top', Position.Top], ['right', Position.Right], ['bottom', Position.Bottom], ['left', Position.Left]]

// Names drawn inside the shape. A name outside it (events, gateways, data)
// is placed at model/labels.js's box — the same box the router steers
// around and the quality metric checks.
function insideClass (type) {
  if (type === 'text_annotation') return 'bpmn-label bpmn-label-annotation'
  if (type === 'group') return 'bpmn-label bpmn-label-group'
  return null
}

// An activity's name keeps clear of what it draws in its corners, and ends
// in an ellipsis past the lines that fit; the whole name is the node's title.
function Label ({ node, name, orientation, category, badge, link }) {
  if (category === CATEGORY.activity) {
    const area = insideLabelBox({ ...node, x: 0, y: 0 }, { badge, link })
    return (
      <div className='bpmn-label bpmn-label-inside' data-testid='bpmn-node-label' style={{ left: area.x, top: area.y, width: area.w, height: area.h }}>
        <span style={{ WebkitLineClamp: area.lines, '--bpmn-label-corner': `${area.corner}px` }}>
          {area.corner > 0 && <><i className='bpmn-label-corner is-left' /><i className='bpmn-label-corner is-right' /></>}
          {name}
        </span>
      </div>
    )
  }
  const inside = insideClass(node.type)
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
const EDGE_GAP = 8

// The quick menu goes to the right of the node, or to its left when there is
// no room before the canvas edge (or the properties panel). With room on
// neither side (a phone's canvas) it goes below the node, slid sideways to
// stay inside the canvas. Only the selected node mounts this, so only it
// follows the viewport.
function QuickMenuToolbar ({ x, width, children, panelOpen }) {
  const left = useStore((s) => x * s.transform[2] + s.transform[0])
  const right = useStore((s) => (x + width) * s.transform[2] + s.transform[0])
  const paneWidth = useStore((s) => s.width)
  const room = paneWidth - (panelOpen ? PANEL_WIDTH : 0) - right
  // Its drawn width, which grows with «Split with» and «More».
  const menu = useRef(null)
  const [span, setSpan] = useState(MENU_WIDTH)
  useLayoutEffect(() => {
    const drawn = menu.current && menu.current.offsetWidth
    if (drawn && drawn !== span) setSpan(drawn)
  })
  if (room < MENU_WIDTH && left < MENU_WIDTH) {
    const shift = Math.max(EDGE_GAP, Math.min(left, paneWidth - span - EDGE_GAP)) - left
    return (
      <NodeToolbar isVisible position={Position.Bottom} align='start' offset={14}>
        <div ref={menu} className='w-max' style={{ transform: `translateX(${Math.round(shift)}px)` }}>{children}</div>
      </NodeToolbar>
    )
  }
  return (
    <NodeToolbar isVisible position={room < MENU_WIDTH ? Position.Left : Position.Right} align='start' offset={14}>
      {children}
    </NodeToolbar>
  )
}

function FlowNode ({ id, data, selected, positionAbsoluteX }) {
  const canvas = useCanvas()
  const { node, external, issue, diff, diffReasons } = data
  const note = canvas.notesByElement && canvas.notesByElement.get(id)
  const size = nodeSize(node)
  const box = { w: size.width, h: size.height }
  const category = categoryOf(node)
  const renaming = canvas.renamingId === id
  const name = node.name || ''
  const linked = node.type === 'sub_process' && node.reference && safeUrl(node.reference.url)
  const look = appearanceOf(node)
  // Hidden with «Show badges» off (BpmnEditor `badgesVisible`): in the name too.
  const badge = look && canvas.badgesVisible !== false ? look.badge : null
  // Focusable, and Enter or Space act as a click (BpmnEditor's onNodeActivate).
  const activate = canvas.onNodeActivate
  const mark = diff ? DIFF_MARKS[diffMark(diff, diffReasons)] : null
  // What the eye gets from colour, fading, badge and mark, in words: the
  // name, the app's badge, «faded» (`appearance_dimmed`, which the app may
  // reword — the meaning is the app's), and what a comparison found.
  const showLink = Boolean(linked && !canvas.editable)
  const tab = badge ? badgeTabBox({ ...node, x: 0, y: 0 }, badge) : null
  const noteNumber = note && <span className='bpmn-note-number' style={{ '--bpmn-note-color': note.color, '--bpmn-note-text': textOn(note.color) || undefined }} title={note.text}>{note.number}</span>
  const spoken = [name || node.type, badge, look && look.dimmed && canvas.t('appearance_dimmed'), mark && canvas.t(mark.label)].filter(Boolean).join(', ')
  return (
    <div
      className={`bpmn-node bpmn-node-${category}${selected ? ' is-selected' : ''}${canvas.highlightId === id ? ' is-highlighted' : ''}${diff ? ` bpmn-diff-${diff}` : ''}${look && look.dimmed ? ' is-dimmed' : ''}${badge ? ' has-badge' : ''}${canvas.connectSource === id ? ' is-connect-source' : ''}${canvas.connectInvalid && canvas.connectInvalid.has(id) ? ' is-connect-invalid' : ''}`}
      data-node-type={node.type}
      data-testid='bpmn-node'
      data-node-id={id}
      title={name || undefined}
      tabIndex={activate ? 0 : undefined}
      role={activate ? 'button' : 'group'}
      aria-label={spoken}
      aria-pressed={activate ? Boolean(selected) : undefined}
      onKeyDown={activate
        ? (event) => {
            if (event.target !== event.currentTarget || (event.key !== 'Enter' && event.key !== ' ')) return
            event.preventDefault()
            activate(id)
          }
        : undefined}
    >
      <svg className='bpmn-node-shape' width={box.w} height={box.h} aria-hidden='true'>
        <NodeShape node={node} width={box.w} height={box.h} external={external} badge={Boolean(badge)} />
        {look && <AppearanceMark node={node} width={box.w} height={box.h} color={look.color} />}
        {issue && (() => { const b = badgeBox({ ...node, x: 0, y: 0 }); return <IssueMarker x={b.x + b.w / 2} y={b.y + 8} /> })()}
      </svg>
      {renaming
        ? canvas.renderRename(node)
        : name && <Label node={node} name={name} orientation={canvas.orientation} category={category} badge={Boolean(badge)} link={showLink} />}
      {mark && <span className={`bpmn-diff-mark bpmn-diff-chip is-${mark.tone}`} data-testid='bpmn-diff-mark' data-mark={diffMark(diff, diffReasons)} aria-hidden='true'>{mark.symbol}</span>}
      {badge
        ? (
          <div className='bpmn-node-tabs' style={{ '--bpmn-tab-radius': `${tab.radius}px`, '--bpmn-tab-reserve': issue || showLink ? '20px' : '0px' }}>
            <span className='bpmn-node-badge' data-testid='bpmn-node-badge' style={look.color ? { '--bpmn-badge': look.color, '--bpmn-badge-text': textOn(look.color) } : undefined}>{badge}</span>
            {noteNumber}
          </div>
          )
        : noteNumber}
      {showLink && <span className='bpmn-node-link' data-testid='bpmn-node-link' aria-hidden='true'>↗</span>}
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
