// What the rule catalogues share: reading a flow through the context the
// engine builds (engine.js `context`).
import { edgeType } from '../catalog.js'

export const sequence = (edges) => edges.filter((e) => edgeType(e) === 'sequence_flow')
export const words = (name) => String(name || '').trim().toLowerCase()
export const isJoin = (ctx, node) => ctx.inc(node).length > 1 && ctx.out(node).length <= 1
export const isSplit = (ctx, node) => ctx.out(node).length > 1
export const kind = (node) => node.event_definition && node.event_definition.kind
export const each = (list, test, build) => list.filter(test).map(build)

// A name like "Lane 3" or "New activity" — a word from the generic list,
// optionally followed by a number.
export function generic (name, list) {
  const n = words(name).replace(/\s*\d+$/, '').trim()
  return n !== '' && list.includes(n)
}

// A splitting gateway that takes a decision (exclusive, inclusive, Yes/No).
export const isDecision = (ctx, node) => (node.type === 'exclusive_gateway' || node.type === 'inclusive_gateway') && isSplit(ctx, node)
// The gateway a split's paths must close with (COM-19); null when the
// matrix sets none (complex gateway).
export const CLOSING = { exclusive_gateway: 'exclusive_gateway', inclusive_gateway: 'inclusive_gateway', parallel_gateway: 'parallel_gateway', event_based_gateway: 'exclusive_gateway' }
// Elements of an external participant: another process, joined by message flows.
export const externalLanes = (ctx) => new Set((ctx.doc.lanes || []).filter((l) => l.kind === 'external').map((l) => String(l.id)))

// A translated string inside a check.
export function say (ctx, key) {
  return ctx.translate ? ctx.translate(key) : key
}
