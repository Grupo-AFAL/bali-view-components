// The document as the island holds it: the Bali::BpmnEditor::Data contract,
// with the collections always present. Keys the island does not know are
// kept, so a save never drops what the host (or an imported file) put there.
import { autoLayout, needsLayout } from './layout.js'
import { withoutAppearance } from './appearance.js'

const COLLECTIONS = ['lanes', 'nodes', 'edges', 'annotations', 'stencil', 'issues']

// A document without coordinates is laid out with `layoutOptions`
// (autoLayout's mode and page).
export function normalize (data, layoutOptions) {
  const doc = { ...(data || {}) }
  for (const key of COLLECTIONS) doc[key] = Array.isArray(doc[key]) ? doc[key] : []
  doc.orientation = doc.orientation === 'vertical' ? 'vertical' : 'horizontal'
  doc.pool = { x: 0, y: 0, ...(doc.pool || {}) }
  doc.nodes = doc.nodes.map((n) => (namedByReference(n) && n.name !== n.reference.label ? { ...n, name: n.reference.label } : n))
  return needsLayout(doc) ? autoLayout(doc, layoutOptions) : doc
}

// A related procedure carries the official name of the one it cites (AFAL
// SUB-02): while linked, its name is the reference's label, not typed.
export const namedByReference = (node) => node.type === 'sub_process' && Boolean(node.reference && node.reference.label)

// Ids minted on the client: `prefix` + a random base-36 token, never a count.
// "First free number" hands a new element the id of the one just deleted,
// and a comparison by id (`match: :id` / `:auto`) against a published version
// then takes a deletion and a creation for a rename; a host's late
// `reference-created` for the deleted node lands on its heir. No document
// field could remember the deleted ids either: a host that maps the document
// onto its records drops keys it does not know. The server may keep or
// replace these ids; undo and redo restore whole documents, ids included.
const ID_ALPHABET = '0123456789abcdefghijklmnopqrstuvwxyz'
const ID_LENGTH = 6
const cryptoRandom = () => globalThis.crypto.getRandomValues(new Uint32Array(1))[0] / 4294967296
let idRandom = cryptoRandom

// Tests that replay an editing session by seed mint the same ids every run:
// `random` () → [0, 1); null restores the default.
export function mintIdsWith (random) {
  idRandom = random || cryptoRandom
}

export function newId (doc, prefix) {
  const taken = new Set([...doc.lanes, ...doc.nodes, ...doc.edges, ...(doc.annotations || [])].map((e) => String(e.id)))
  let id
  do {
    id = prefix
    for (let i = 0; i < ID_LENGTH; i++) id += ID_ALPHABET[Math.floor(idRandom() * ID_ALPHABET.length)]
  } while (taken.has(id))
  return id
}

export const findNode = (doc, id) => doc.nodes.find((n) => String(n.id) === String(id)) || null
export const findLane = (doc, id) => doc.lanes.find((l) => String(l.id) === String(id)) || null
export const findEdge = (doc, id) => doc.edges.find((e) => String(e.id) === String(id)) || null
export const outgoing = (doc, id) => doc.edges.filter((e) => String(e.source) === String(id))
export const incoming = (doc, id) => doc.edges.filter((e) => String(e.target) === String(id))

// What the save request carries: the document minus what only the server
// writes (`issues`, `stencil` and each node's `appearance` come back fresh
// with every 200).
export function forSave (doc) {
  const { issues, stencil, ...rest } = doc
  return { ...rest, nodes: (rest.nodes || []).map(withoutAppearance) }
}
