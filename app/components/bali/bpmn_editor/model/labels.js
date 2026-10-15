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

const CHAR = 6.4 // average glyph width of the 11.5px label font
const LINE = 14
const MAX_WIDTH = 140
const GAP = 4

export function textBlock (text, maxWidth = MAX_WIDTH) {
  const length = String(text || '').trim().length
  if (!length) return null
  const raw = length * CHAR
  const w = Math.min(maxWidth, Math.max(24, Math.ceil(raw)))
  const lines = Math.min(3, Math.ceil(raw / maxWidth))
  return { w, h: lines * LINE, lines }
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
    return { x: box.cx - GAP - block.w, y: box.y - GAP - block.h, w: block.w, h: block.h, lines: block.lines }
  }
  if (orientation === 'vertical' && categoryOf(node) === CATEGORY.event) {
    return { x: box.x + box.w + GAP + 2, y: box.cy - block.h / 2, w: block.w, h: block.h, lines: block.lines }
  }
  return { x: box.cx - block.w / 2, y: box.y + box.h + GAP, w: block.w, h: block.h, lines: block.lines }
}

// The pending-issue triangle, on the top-right corner of the shape.
export function badgeBox (node) {
  const box = nodeBox(node)
  return { x: box.x + box.w - 9, y: box.y - 9, w: 18, h: 16 }
}

// The side of a node its own label occupies: no connection may use that port.
export function labelSide (node, orientation = 'horizontal') {
  if (!hasExternalLabel(node) || !String(node.name || '').trim()) return null
  if (categoryOf(node) === CATEGORY.gateway) return null // above-left: clear of every port
  return orientation === 'vertical' && categoryOf(node) === CATEGORY.event ? 'right' : 'bottom'
}

export const EDGE_LABEL = { char: 6.6, height: 18, pad: 12 }
export const edgeLabelSize = (label) => ({ w: Math.ceil(String(label).length * EDGE_LABEL.char + EDGE_LABEL.pad), h: EDGE_LABEL.height })
