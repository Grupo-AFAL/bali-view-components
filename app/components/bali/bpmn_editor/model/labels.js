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

// Average glyph width of the 11.5 px semibold label font. 6.4 cut names off:
// «Tiempo (captura)» measured 6.9 px a glyph in Chromium and wrapped into a
// line its box did not have.
const CHAR = 7
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
    const width = word.length * CHAR
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

// The name's box (pool-relative), or null when the name is drawn inside the
// shape or there is none.
export function nodeLabelBox (node, orientation = 'horizontal') {
  if (!hasExternalLabel(node)) return null
  const block = textBlock(node.name)
  if (!block) return null
  const box = nodeBox(node)
  if (categoryOf(node) === CATEGORY.gateway) {
    // Above the app's badge tab, which reaches 8 px over the top-left corner.
    const look = appearanceOf(node)
    const top = box.y - (look && look.badge ? BADGE_TAB.height / 2 : 0)
    return { x: box.cx - GAP - block.w, y: top - GAP - block.h, w: block.w, h: block.h, lines: block.lines }
  }
  if (orientation === 'vertical' && categoryOf(node) === CATEGORY.event) {
    // Past the pending badge, which overhangs the top-right corner by 9 px: a
    // name of two or three lines reaches up beside it.
    return { x: box.x + box.w + 12, y: box.cy - block.h / 2, w: block.w, h: block.h, lines: block.lines }
  }
  return { x: box.cx - block.w / 2, y: box.y + box.h + GAP, w: block.w, h: block.h, lines: block.lines }
}

// The pending-issue triangle, on the top-right corner of the shape.
export function badgeBox (node) {
  const box = nodeBox(node)
  return { x: box.x + box.w - 9, y: box.y - 9, w: 18, h: 16 }
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
// badge tab when there is one (the tab's inner half ends at 8 px).
export function taskMarkerAt (h, badge = false) {
  const scale = clamp(h / 64, 0.7, 1)
  return { x: 6 * scale, y: badge ? BADGE_TAB.height / 2 + 2 : 5 * scale, size: 16 * scale, scale }
}

export const activityRadius = (h) => Math.round(h * 0.1 * 10) / 10

// The app's badge (node.appearance.badge): a tab across the top edge, half
// outside, flush with the left edge — of the bounding box for an event or a
// gateway. It stops short of the top-right corner while the pending marker or
// the link arrow is there (TOP_RIGHT), and of a note number that follows it.
// Width by the 10 px semibold font's average glyph.
export const BADGE_TAB = { height: 16, pad: 6, char: 6.2 }
const TOP_RIGHT = 20
const NOTE = 22

export function badgeTabBox (node, text, { topRight = false, note = false } = {}) {
  const box = nodeBox(node)
  const max = Math.max(BADGE_TAB.height, box.w - (topRight ? TOP_RIGHT : 0) - (note ? NOTE : 0))
  const full = String(text)
  const w = Math.min(max, Math.ceil(full.length * BADGE_TAB.char + BADGE_TAB.pad * 2))
  const fits = Math.max(1, Math.floor((w - BADGE_TAB.pad * 2) / BADGE_TAB.char))
  const shown = full.length > fits ? `${full.slice(0, Math.max(1, fits - 1))}…` : full
  const radius = categoryOf(node) === CATEGORY.activity ? activityRadius(box.h) : 4
  return { x: box.x, y: box.y - BADGE_TAB.height / 2, w, h: BADGE_TAB.height, text: shown, radius }
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

export function insideLabelBox (node, { badge = false, link = false } = {}) {
  const box = nodeBox(node)
  const marker = hasTaskMarker(node) ? taskMarkerAt(box.h, badge) : null
  const cornerBottom = Math.max(marker ? marker.y + marker.size : 0, link ? LINK_BOTTOM : 0)
  const top = Math.max(badge ? BADGE_TAB.height / 2 + 2 : INSET.y, cornerBottom - LINE)
  const bottom = hasBottomMarker(node) ? markerZone(box.h).height + 1 : INSET.y
  const h = Math.max(LINE, box.h - top - bottom)
  const w = Math.max(0, box.w - INSET.x * 2)
  return { x: box.x + INSET.x, y: box.y + top, w, h, lines: Math.max(1, Math.floor(h / LINE)), corner: cornerBottom ? CORNER : 0 }
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
    if (current && (current + ' ' + word).length <= room) { current = `${current} ${word}`; continue }
    if (current) { lines.push(current); current = ''; pieces.unshift(word); continue }
    if (word.length <= room) { current = word; continue }
    // A word longer than the line, cut where the line ends.
    lines.push(word.slice(0, room))
    pieces.unshift(word.slice(room))
  }
  if (current) lines.push(current)
  if (lines.length > maxLines) {
    const kept = lines.slice(0, maxLines)
    kept[maxLines - 1] = `${kept[maxLines - 1].slice(0, widthOf(maxLines - 1) - 1)}…`
    return kept
  }
  return lines
}

// The side of a node its own label occupies: no connection may use that port.
export function labelSide (node, orientation = 'horizontal') {
  if (!hasExternalLabel(node) || !String(node.name || '').trim()) return null
  if (categoryOf(node) === CATEGORY.gateway) return null // above-left: clear of every port
  return orientation === 'vertical' && categoryOf(node) === CATEGORY.event ? 'right' : 'bottom'
}

export const EDGE_LABEL = { char: 6.6, height: 18, pad: 12 }
export const edgeLabelSize = (label) => ({ w: Math.ceil(String(label).length * EDGE_LABEL.char + EDGE_LABEL.pad), h: EDGE_LABEL.height })
