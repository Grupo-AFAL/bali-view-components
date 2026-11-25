import { memo, useLayoutEffect, useRef, useState } from 'react'
import { Handle, NodeResizeControl, NodeToolbar, Position, useStore } from '@xyflow/react'
import { NodeShape, IssueMarker, AppearanceMark, chevronAround } from '../shapes.jsx'
import { appearanceOf } from '../model/appearance.js'
import { DIFF_MARKS, diffMark } from './diffMarks.js'
import { categoryOf, nodeSize, isResizable, CATEGORY, MIN_NODE_SIZE, MAX_NODE_SIZE } from '../model/catalog.js'
import { nodeBox } from '../model/geometry.js'
import { nodeLabelBox, badgeBox, insideLabelBox, badgeTabBox, chevronDepth } from '../model/labels.js'
import { textOn } from '../model/contrast.js'
import { safeUrl } from '../model/urls.js'
import { useCanvas } from './CanvasContext.js'

// The card's selection sits 5–6 px out (flow.css `.is-selected::after`), its
// read-only halo 4 px beyond its 2.5 px ring: drawn outside it, not over the shape.
const SELECTION_INSET = 6
const HALO_INSET = SELECTION_INSET + 1.25 + 2
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
function Label ({ node, name, orientation, activityShape, category, badge, link }) {
  if (category === CATEGORY.activity) {
    const area = insideLabelBox({ ...node, x: 0, y: 0 }, { badge, link, activityShape })
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
  if (label.vertical) {
    // The line runs up the box: a span as long as the box is tall, turned a
    // quarter back around the box's bottom-left corner (flow.css).
    return (
      <div className='bpmn-label bpmn-label-outside is-vertical' data-testid='bpmn-node-name' style={{ left: label.x - box.x, top: label.y - box.y, width: label.w, height: label.h }}>
        <span className={LABEL_ALIGN[label.align]} style={{ width: label.h, height: label.w, WebkitLineClamp: label.lines }}>{name}</span>
      </div>
    )
  }
  return (
    <div
      className={`bpmn-label bpmn-label-outside ${LABEL_ALIGN[label.align]}`}
      data-testid='bpmn-node-name'
      style={{ left: label.x - box.x, top: label.y - box.y, width: label.w, WebkitLineClamp: label.lines }}
    >
      {name}
    </div>
  )
}

const LABEL_ALIGN = { end: 'text-right', start: 'text-left', middle: 'text-center' }

// Width the quick menu needs, and the properties panel that covers the right
// edge of the canvas while it is open (w-72 + its gap).
const MENU_WIDTH = 250
const PANEL_WIDTH = 300
const EDGE_GAP = 8

// The menu as it opens with every pick (269 × 58 px measured), before «More».
const MENU_SIZE = { w: 272, h: 60 }
const MENU_OFFSET = 14
// Where the menu may go, in order: [side, align, its top-left corner from the
// node's box `n` in screen px].
const MENU_PLACES = [
  ['right', 'start', (n) => ({ x: n.x + n.w + MENU_OFFSET, y: n.y })],
  ['left', 'start', (n) => ({ x: n.x - MENU_OFFSET - MENU_SIZE.w, y: n.y })],
  ['bottom', 'start', (n) => ({ x: n.x, y: n.y + n.h + MENU_OFFSET })],
  ['bottom', 'end', (n) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y + n.h + MENU_OFFSET })],
  ['top', 'start', (n) => ({ x: n.x, y: n.y - MENU_OFFSET - MENU_SIZE.h })],
  ['top', 'end', (n) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y - MENU_OFFSET - MENU_SIZE.h })]
]

// The first place where the menu covers no other element and stays inside the
// canvas (clear of the properties panel), as an index of MENU_PLACES, or -1.
// Next to a neighbour the menu took the clicks meant for it: with «Validate
// invoice» selected, its icons lay over the gateway 130 px on.
function freePlace (store, id, panelOpen) {
  const [tx, ty, zoom] = store.transform
  const screen = (node) => {
    const at = node.internals.positionAbsolute
    return { x: at.x * zoom + tx, y: at.y * zoom + ty, w: (node.measured.width || 0) * zoom, h: (node.measured.height || 0) * zoom }
  }
  const own = store.nodeLookup.get(id)
  if (!own) return -1
  const me = screen(own)
  const others = [...store.nodeLookup.values()].filter((n) => n.type === 'bpmn' && n.id !== id).map(screen)
  const pane = { w: store.width - (panelOpen ? PANEL_WIDTH : 0), h: store.height }
  return MENU_PLACES.findIndex(([, , corner]) => {
    const { x, y } = corner(me)
    if (x < EDGE_GAP || y < EDGE_GAP || x + MENU_SIZE.w > pane.w - EDGE_GAP || y + MENU_SIZE.h > pane.h - EDGE_GAP) return false
    return !others.some((o) => x < o.x + o.w && o.x < x + MENU_SIZE.w && y < o.y + o.h && o.y < y + MENU_SIZE.h)
  })
}

// The quick menu goes beside the node where it covers no other element:
// right, left, below or above it. When every place is taken or out of the
// canvas: to the right, or to the left when there is no room before the
// canvas edge (or the properties panel); with room on neither side (a phone's
// canvas) below the node, slid sideways to stay inside the canvas. Only the
// selected node mounts this, so only it follows the viewport.
function QuickMenuToolbar ({ id, x, width, children, panelOpen }) {
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
  // By the size it opens at, not the one it grows to: «More» would move the
  // menu from under the pointer that opened it.
  const place = useStore((s) => freePlace(s, id, panelOpen))
  if (place >= 0) {
    const [side, align] = MENU_PLACES[place]
    return (
      <NodeToolbar isVisible position={side} align={align} offset={MENU_OFFSET}>
        <div className='w-max' data-menu-side={side}>{children}</div>
      </NodeToolbar>
    )
  }
  if (room < MENU_WIDTH && left < MENU_WIDTH) {
    const shift = Math.max(EDGE_GAP, Math.min(left, paneWidth - span - EDGE_GAP)) - left
    return (
      <NodeToolbar isVisible position={Position.Bottom} align='start' offset={MENU_OFFSET}>
        <div ref={menu} className='w-max' style={{ transform: `translateX(${Math.round(shift)}px)` }}>{children}</div>
      </NodeToolbar>
    )
  }
  return (
    <NodeToolbar isVisible position={room < MENU_WIDTH ? Position.Left : Position.Right} align='start' offset={MENU_OFFSET}>
      {children}
    </NodeToolbar>
  )
}

function FlowNode ({ id, data, selected, positionAbsoluteX }) {
  const canvas = useCanvas()
  const { external, issue, diff, diffReasons } = data
  // `live`: the size while the corner is dragged (BpmnEditor's liveSize).
  const node = data.live ? { ...data.node, ...data.live } : data.node
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
  const tab = badge ? badgeTabBox({ ...node, x: 0, y: 0 }, badge, { activityShape: canvas.activityShape }) : null
  const noteNumber = note && <span className='bpmn-note-number' style={{ '--bpmn-note-color': note.color, '--bpmn-note-text': textOn(note.color) || undefined }} title={note.text}>{note.number}</span>
  const chevron = category === CATEGORY.activity && canvas.activityShape === 'chevron'
  const spoken = [name || node.type, badge, look && look.dimmed && canvas.t('appearance_dimmed'), mark && canvas.t(mark.label)].filter(Boolean).join(', ')
  return (
    <div
      className={`bpmn-node bpmn-node-${category}${selected ? ' is-selected' : ''}${canvas.highlightId === id ? ' is-highlighted' : ''}${diff ? ` bpmn-diff-${diff}` : ''}${look && look.dimmed ? ' is-dimmed' : ''}${badge ? ' has-badge' : ''}${canvas.connectSource === id ? ' is-connect-source' : ''}${canvas.connectInvalid && canvas.connectInvalid.has(id) ? ' is-connect-invalid' : ''}${chevron ? ' is-chevron' : ''}`}
      style={chevron ? { '--bpmn-chevron-depth': `${chevronDepth(box.h, box.w)}px` } : undefined}
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
        <NodeShape node={node} width={box.w} height={box.h} external={external} badge={Boolean(badge)} activityShape={canvas.activityShape} />
        {look && <AppearanceMark node={node} width={box.w} height={box.h} color={look.color} activityShape={canvas.activityShape} />}
        {issue && (() => { const b = badgeBox({ ...node, x: 0, y: 0 }, canvas.activityShape); return <IssueMarker x={b.x + b.w / 2} y={b.y + 8} /> })()}
      </svg>
      {chevron && (
        <svg className='bpmn-node-selection' width={box.w} height={box.h} aria-hidden='true' data-testid='bpmn-node-selection'>
          <path className='bpmn-node-selection-halo' d={chevronAround(box.w, box.h, HALO_INSET)} />
          <path d={chevronAround(box.w, box.h, SELECTION_INSET)} />
        </svg>
      )}
      {renaming
        ? canvas.renderRename(node)
        : name && <Label node={node} name={name} orientation={canvas.orientation} activityShape={canvas.activityShape} category={category} badge={Boolean(badge)} link={showLink} />}
      {mark && <span className={`bpmn-diff-mark bpmn-diff-chip is-${mark.tone}`} data-testid='bpmn-diff-mark' data-mark={diffMark(diff, diffReasons)} aria-hidden='true'>{mark.symbol}</span>}
      {badge
        ? (
          <div className='bpmn-node-tabs' style={{ '--bpmn-tab-radius': `${tab.radius}px`, '--bpmn-tab-reserve': `${(issue || showLink ? 20 : 0) + (chevron ? chevronDepth(box.h, box.w) : 0)}px` }}>
            <span className='bpmn-node-badge' data-testid='bpmn-node-badge' style={look.color ? { '--bpmn-badge': look.color, '--bpmn-badge-text': textOn(look.color) } : undefined}>{badge}</span>
            {noteNumber}
          </div>
          )
        : noteNumber}
      {showLink && <span className='bpmn-node-link' data-testid='bpmn-node-link' aria-hidden='true'>↗</span>}
      {canvas.quickMenuId === id && (
        <QuickMenuToolbar id={id} x={positionAbsoluteX} width={box.w} panelOpen={canvas.panelOpen}>
          {canvas.renderQuickMenu(node)}
        </QuickMenuToolbar>
      )}
      {canvas.editable && selected && isResizable(node) && (
        // Keyed on the stored size, as LaneNode's controls are: one keeps the
        // box it measured when it mounted. Not on the live size, which would
        // remount it under the pointer.
        <NodeResizeControl
          key={`${nodeSize(data.node).width}x${nodeSize(data.node).height}`}
          position='bottom-right'
          className='bpmn-node-resize'
          minWidth={MIN_NODE_SIZE.width}
          minHeight={MIN_NODE_SIZE.height}
          maxWidth={MAX_NODE_SIZE.width}
          maxHeight={MAX_NODE_SIZE.height}
          onResize={(_event, params) => canvas.onNodeResizing(id, params)}
          onResizeEnd={(_event, params) => canvas.onNodeResize(id, params)}
        />
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
