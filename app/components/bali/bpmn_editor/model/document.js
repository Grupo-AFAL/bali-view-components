// The document as the island holds it: the Bali::BpmnEditor::Data contract,
// with the collections always present. Keys the island does not know are
// kept, so a save never drops what the host (or an imported file) put there.
import { autoLayout, needsLayout } from './layout.js'

const COLLECTIONS = ['lanes', 'nodes', 'edges', 'annotations', 'stencil', 'issues']

// A document without coordinates is laid out with `layoutOptions`
// (autoLayout's mode and page).
export function normalize (data, layoutOptions) {
  const doc = { ...(data || {}) }
  for (const key of COLLECTIONS) doc[key] = Array.isArray(doc[key]) ? doc[key] : []
  doc.orientation = doc.orientation === 'vertical' ? 'vertical' : 'horizontal'
  doc.pool = { x: 0, y: 0, ...(doc.pool || {}) }
  return needsLayout(doc) ? autoLayout(doc, layoutOptions) : doc
}

// Ids minted on the client: `prefix` + the first free number, so the same
// edits always mint the same ids (the property tests replay sessions by
// seed). The server may keep or replace them.
export function newId (doc, prefix) {
  const taken = new Set([...doc.lanes, ...doc.nodes, ...doc.edges, ...(doc.annotations || [])].map((e) => String(e.id)))
  let n = taken.size + 1
  while (taken.has(`${prefix}${n}`)) n++
  return `${prefix}${n}`
}

export const findNode = (doc, id) => doc.nodes.find((n) => String(n.id) === String(id)) || null
export const findLane = (doc, id) => doc.lanes.find((l) => String(l.id) === String(id)) || null
export const findEdge = (doc, id) => doc.edges.find((e) => String(e.id) === String(id)) || null
export const outgoing = (doc, id) => doc.edges.filter((e) => String(e.source) === String(id))
export const incoming = (doc, id) => doc.edges.filter((e) => String(e.target) === String(id))

// What the save request carries: the document minus what only the server
// writes (`issues` and `stencil` come back fresh with every 200).
export function forSave (doc) {
  const { issues, stencil, ...rest } = doc
  return rest
}
