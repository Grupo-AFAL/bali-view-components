// Where names and markers sit around the shapes, as boxes the canvas draws
// from, the router steers around and the quality metric checks — one source
// for all three, so a label is never drawn where the router thinks it is not.
//
// Conventions (Camunda, "Creating readable process models"): an event's name
// under it, a gateway's above it — to the LEFT of the top port, so a branch
// leaving upwards does not run through it — a data element's under it. In
// vertical lanes the flow runs down through an event's bottom, so its name
// goes to the right. Activities, annotations and groups hold their own text.
import { categoryOf, CATEGORY } from './catalog.js'
import { nodeBox } from './geometry.js'
import { appearanceOf } from './appearance.js'
import { textLength, cutText } from './text.js'

// Average glyph width of the 11.5 px semibold label font. 6.4 cut names off:
// «Tiempo (captura)» measured 6.9 px a glyph in Chromium and wrapped into a
// line its box did not have.
const CHAR = 7
// A word all in capitals (an acronym, a gateway named «AND») is wider:
// capitals measured 8 px on average and 10 at most (M, W), and «AND» was cut
// to «A…» in the 24 px its three glyphs were given.
const CAPITAL = 10
const isAcronym = (word) => word.length > 1 && word === word.toUpperCase() && word !== word.toLowerCase()
const wordWidth = (word) => word.length * (isAcronym(word) ? CAPITAL : CHAR)
const LINE = 14
const MAX_WIDTH = 100
const GAP = 4

// Lines as the browser breaks them — at spaces, a word too long for one line
// running over as many as it needs — up to 3.
export function textBlock (text, maxWidth = MAX_WIDTH) {
  const words = String(text || '').trim().split(/\s+/).filter(Boolean)
  if (!words.length) return null
  let lines = 1
  let line = 0
  let widest = 0
  for (const word of words) {
    const width = wordWidth(word)
    if (line && line + CHAR + width <= maxWidth) { line += CHAR + width; continue }
    if (line) { widest = Math.max(widest, line); lines++ }
    lines += Math.max(0, Math.ceil(width / maxWidth) - 1)
    line = Math.min(width, maxWidth)
  }
  widest = Math.max(widest, line)
  lines = Math.min(3, lines)
  return { w: Math.min(maxWidth, Math.max(24, Math.ceil(widest))), h: lines * LINE, lines }
}

export const hasExternalLabel = (node) => {
  const category = categoryOf(node)
  return category === CATEGORY.event || category === CATEGORY.gateway || category === CATEGORY.data
}

// Where a person put the name of an event, a gateway or a data element
// (`node.label_position`); absent or null, the conventions above. Mirrors
// Bali::BpmnEditor::Data::LABEL_POSITIONS (contract_test.rb).
export const LABEL_POSITIONS = ['top', 'bottom']
export const labelPosition = (node) => (hasExternalLabel(node) && LABEL_POSITIONS.includes(node.label_position) ? node.label_position : null)

// A name turned to read upwards (`node.label_orientation: 'vertical'`), as a
// horizontal lane's does; absent, null or 'horizontal', across. Mirrors
// Bali::BpmnEditor::Data::LABEL_ORIENTATIONS (contract_test.rb).
export const LABEL_ORIENTATIONS = ['horizontal', 'vertical']
export const labelVertical = (node) => hasExternalLabel(node) && node.label_orientation === 'vertical'

// Where the name goes around its shape: 'above' and 'below-left' beside a
// port, which stays free; 'below' under the shape and 'right' beside it,
// which take that port (labelSide).
function labelPlace (node, orientation) {
  const gateway = categoryOf(node) === CATEGORY.gateway
  const position = labelPosition(node)
  if (position === 'top' || (gateway && !position)) return 'above'
  // A gateway's bottom port is a branch's way out: its name asked below keeps
  // to the left of it, as above.
  if (gateway) return 'below-left'
  // In vertical lanes the flow leaves an event by its bottom.
  if (!position && orientation === 'vertical' && categoryOf(node) === CATEGORY.event) return 'right'
  return 'below'
}

// The side of its box a name's lines keep to — the end of the box nearest the
// port it sits beside. Turned, a name reads upwards: it starts at the bottom.
const ALIGN = {
  across: { above: 'end', 'below-left': 'end', below: 'middle', right: 'start' },
  upwards: { above: 'start', 'below-left': 'end', below: 'end', right: 'middle' }
}

// A name beside a port keeps off the arrowhead of a connection that ends
// there: 10.5 px wide at the 1.5 px line, 12 the open one of a message flow.
const PORT_GAP = 6
// …and off the row its shape stands in, as tall as an activity (64 px): an
// activity may then come as close to a gateway as to another activity, the
// gateway's name passing over it. Under the 4 px it used to keep, the name
// reached 3 px into the activity's height and kept it its own width away.
const ROW = 64
const BADGE_OVER = 9

// The name's box (pool-relative), or null when the name is drawn inside the
// shape or there is none. `vertical`: its lines run up the box, side by side,
// instead of across it one under another.
export function nodeLabelBox (node, orientation = 'horizontal', { room = false } = {}) {
  if (!hasExternalLabel(node)) return null
  const block = textBlock(node.name)
  if (!block) return null
  const box = nodeBox(node)
  const vertical = labelVertical(node)
  const place = labelPlace(node, orientation)
  const [w, h] = vertical ? [block.h, block.w] : [block.w, block.h]
  const size = { w, h, lines: block.lines, align: ALIGN[vertical ? 'upwards' : 'across'][place], ...(vertical ? { vertical } : {}) }
  // `room`: where the name stood before it was lifted off the row — GAP from
  // the shape and from the port. A lane is fitted to that box (arrange.js
  // footprint), so the lift takes 12 px of the lane's padding and moves
  // nothing: fitted to the drawn box, every lane with a gateway in its first
  // row grew 10 px at the first edit of a saved diagram.
  if (place === 'above') {
    // To the left of the top port, above the app's badge tab, which reaches
    // 8 px over the top-left corner. An event's name asked above goes where a
    // gateway's is: clear of the port, and of the pending badge on the right.
    const look = appearanceOf(node)
    const top = box.y - (look && look.badge ? BADGE_TAB.height / 2 : 0)
    if (room) return { x: box.cx - GAP - w, y: top - GAP - h, ...size }
    return { x: box.cx - PORT_GAP - w, y: Math.min(top - GAP, box.cy - ROW / 2 - BADGE_OVER) - h, ...size }
  }
  if (place === 'below-left') {
    if (room) return { x: box.cx - GAP - w, y: box.y + box.h + GAP, ...size }
    return { x: box.cx - PORT_GAP - w, y: Math.max(box.y + box.h + GAP, box.cy + ROW / 2), ...size }
  }
  // Past the pending badge, which overhangs the top-right corner by 9 px: a
  // name of two or three lines reaches up beside it.
  if (place === 'right') return { x: box.x + box.w + 12, y: box.cy - h / 2, ...size }
  return { x: box.cx - w / 2, y: box.y + box.h + GAP, ...size }
}

// The pending-issue triangle, on the top-right corner of the shape — of a
// chevron's straight top edge, which ends before its point.
export function badgeBox (node, activityShape = 'card') {
  const box = nodeBox(node)
  const point = isChevron(node, activityShape) ? chevronDepth(box.h, box.w) : 0
  return { x: box.x + box.w - point - 9, y: box.y - 9, w: 18, h: 16 }
}

const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))

// What an activity draws in its own corners, shared by shapes.jsx (which
// draws it), the canvas name, the outputs and the tests, so they cannot drift.
//
// The collapsed sub-process [+] at the bottom centre (BPMN 2.0, Activities ›
// Sub-Process): its side and its gap to the bottom edge, for a height `h`.
export function markerZone (h) {
  const size = clamp(h * 0.22, 8, 14)
  const gap = clamp(h * 0.09, 1.5, 6)
  return { size, gap, height: size + gap }
}
export const hasBottomMarker = (node) => node.type === 'sub_process'

export const TASK_MARKER_TYPES = ['user_task', 'service_task', 'send_task', 'receive_task', 'script_task', 'business_rule_task', 'manual_task']
export const hasTaskMarker = (node) => TASK_MARKER_TYPES.includes(node.type)

// The task-type marker, 16 px at scale 1, in the top-left corner; under the
// badge tab when there is one (the tab's inner half ends at 8 px). In a
// chevron it moves right by half the notch, which reaches 10.5 px in at the
// marker's foot in the 64 px box.
export function taskMarkerAt (h, badge = false, activityShape = 'card', w = Infinity) {
  const scale = clamp(h / 64, 0.7, 1)
  const notch = activityShape === 'chevron' ? chevronDepth(h, w) / 2 : 0
  return { x: 6 * scale + notch, y: badge ? BADGE_TAB.height / 2 + 2 : 5 * scale, size: 16 * scale, scale }
}

export const activityRadius = (h) => Math.round(h * 0.1 * 10) / 10
// How far a chevron's point juts out on the right, and its notch cuts in on
// the left, for a height `h`: 16 px in the 64 px box.
// A quarter of its height, at most a third of its width: a tall, narrow chevron
// would cross its own outline (its notch past its point).
export const chevronDepth = (h, w = Infinity) => Math.round(Math.min(h * 0.25, w / 3) * 10) / 10
const isChevron = (node, activityShape) => activityShape === 'chevron' && categoryOf(node) === CATEGORY.activity

// The app's badge (node.appearance.badge): a tab across the top edge, half
// outside, flush with the left edge — of the bounding box for an event or a
// gateway. It stops short of the top-right corner while the pending marker or
// the link arrow is there (TOP_RIGHT), of a note number that follows it, and
// of a chevron's point, where the top edge ends.
// Width by the 10 px semibold font's average glyph.
export const BADGE_TAB = { height: 16, pad: 6, char: 6.2 }
const TOP_RIGHT = 20
const NOTE = 22

export function badgeTabBox (node, text, { topRight = false, note = false, activityShape = 'card' } = {}) {
  const box = nodeBox(node)
  const point = isChevron(node, activityShape) ? chevronDepth(box.h, box.w) : 0
  const { w, text: shown } = fitBadge(text, box.w - point - (topRight ? TOP_RIGHT : 0) - (note ? NOTE : 0))
  const radius = categoryOf(node) === CATEGORY.activity ? activityRadius(box.h) : 4
  return { x: box.x, y: box.y - BADGE_TAB.height / 2, w, h: BADGE_TAB.height, text: shown, radius }
}

// A badge's width and the text it shows within `max` px, cut with an ellipsis.
export function fitBadge (text, max) {
  const full = String(text)
  const w = Math.min(Math.max(BADGE_TAB.height, max), Math.ceil(textLength(full) * BADGE_TAB.char + BADGE_TAB.pad * 2))
  const fits = Math.max(1, Math.floor((w - BADGE_TAB.pad * 2) / BADGE_TAB.char))
  return { w, text: textLength(full) > fits ? `${cutText(full, Math.max(1, fits - 1))}…` : full }
}

// The name inside an activity: clear of the badge tab's inner half and of
// the [+]. Its first line is narrowed by `corner` on BOTH sides, so the name
// stays centred, while the task marker (6 + 16 px from the left) or the link
// arrow (16 px from the right, flow.css .bpmn-node-link) is there; the box
// starts low enough that the second line is already below them (21 px, or
// 26 under a badge). In the 64 px box: 4 lines bare, 3 under a badge or
// beside a corner, 2 over the [+].
const INSET = { x: 8, y: 4 }
const CORNER = 16
const LINK_BOTTOM = 21

export function insideLabelBox (node, { badge = false, link = false, activityShape = 'card' } = {}) {
  const box = nodeBox(node)
  const marker = hasTaskMarker(node) ? taskMarkerAt(box.h, badge, activityShape, box.w) : null
  const cornerBottom = Math.max(marker ? marker.y + marker.size : 0, link ? LINK_BOTTOM : 0)
  const top = Math.max(badge ? BADGE_TAB.height / 2 + 2 : INSET.y, cornerBottom - LINE)
  const bottom = hasBottomMarker(node) ? markerZone(box.h).height + 1 : INSET.y
  const h = Math.max(LINE, box.h - top - bottom)
  // A chevron's notch and point take its depth off each side at mid-height.
  const inset = INSET.x + (isChevron(node, activityShape) ? chevronDepth(box.h, box.w) : 0)
  const w = Math.max(0, box.w - inset * 2)
  return { x: box.x + inset, y: box.y + top, w, h, lines: Math.max(1, Math.floor(h / LINE)), corner: cornerBottom ? CORNER : 0 }
}

// Greedy word wrap by an average glyph width, for the outputs (the canvas'
// HTML labels wrap themselves): a word longer than a line is cut, as
// `overflow-wrap: anywhere` cuts it on screen; past `maxLines` the last line
// ends in an ellipsis, as `line-clamp` does.
export function wrap (text, maxChars, maxLines, firstChars = maxChars) {
  const width = Math.max(1, maxChars)
  const widthOf = (line) => (line === 0 ? Math.max(1, Math.min(width, firstChars)) : width)
  const pieces = String(text || '').split(/\s+/).filter(Boolean)
  const lines = []
  let current = ''
  while (pieces.length) {
    const room = widthOf(lines.length)
    const word = pieces.shift()
    if (current && textLength(`${current} ${word}`) <= room) { current = `${current} ${word}`; continue }
    if (current) { lines.push(current); current = ''; pieces.unshift(word); continue }
    if (textLength(word) <= room) { current = word; continue }
    // A word longer than the line, cut where the line ends.
    lines.push(cutText(word, room))
    pieces.unshift(Array.from(word).slice(room).join(''))
  }
  if (current) lines.push(current)
  if (lines.length > maxLines) {
    const kept = lines.slice(0, maxLines)
    kept[maxLines - 1] = `${cutText(kept[maxLines - 1], widthOf(maxLines - 1) - 1)}…`
    return kept
  }
  return lines
}

// The side of a node its own label occupies: no connection may use that port.
export function labelSide (node, orientation = 'horizontal') {
  if (!hasExternalLabel(node) || !String(node.name || '').trim()) return null
  return { above: null, 'below-left': null, right: 'right', below: 'bottom' }[labelPlace(node, orientation)]
}

export const EDGE_LABEL = { char: 6.6, height: 18, pad: 12 }
export const edgeLabelSize = (label) => ({ w: Math.ceil(String(label).length * EDGE_LABEL.char + EDGE_LABEL.pad), h: EDGE_LABEL.height })
