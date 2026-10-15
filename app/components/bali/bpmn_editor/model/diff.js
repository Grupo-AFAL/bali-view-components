// What changed between two versions of a document, by element id — the
// contract carries stable ids across saves. An element is "changed" when what
// it says or where it belongs changed (name, type, description, lane, the
// event kind, the reference; for a connection its ends and label), not when
// it merely moved.
const NODE_KEYS = ['name', 'type', 'documentation', 'lane_id']
const EDGE_KEYS = ['source', 'target', 'label', 'type']
const LANE_KEYS = ['name', 'kind']

const same = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null)

function compare (before, after, keys, extra = () => false) {
  const old = new Map((before || []).map((e) => [String(e.id), e]))
  const now = new Map((after || []).map((e) => [String(e.id), e]))
  const result = {}
  for (const [id, element] of now) {
    const previous = old.get(id)
    if (!previous) result[id] = 'added'
    else if (keys.some((k) => !same(previous[k], element[k])) || extra(previous, element)) result[id] = 'changed'
  }
  for (const id of old.keys()) if (!now.has(id)) result[id] = 'removed'
  return result
}

export function diffDocuments (base, current) {
  const nodes = compare(base.nodes, current.nodes, NODE_KEYS, (a, b) =>
    !same(a.event_definition && a.event_definition.kind, b.event_definition && b.event_definition.kind) ||
    !same(a.reference && a.reference.id, b.reference && b.reference.id))
  const edges = compare(base.edges, current.edges, EDGE_KEYS)
  const lanes = compare(base.lanes, current.lanes, LANE_KEYS)
  const count = (map, state) => Object.values(map).filter((s) => s === state).length
  return {
    nodes,
    edges,
    lanes,
    summary: {
      added: count(nodes, 'added') + count(edges, 'added') + count(lanes, 'added'),
      removed: count(nodes, 'removed') + count(edges, 'removed') + count(lanes, 'removed'),
      changed: count(nodes, 'changed') + count(edges, 'changed') + count(lanes, 'changed')
    }
  }
}

// The current document plus, drawn where they used to be, the nodes and
// connections the base had and the current one dropped — the overlay view.
export function overlayDocument (base, current) {
  const ids = new Set((current.nodes || []).map((n) => String(n.id)))
  const edgeIds = new Set((current.edges || []).map((e) => String(e.id)))
  const removedNodes = (base.nodes || []).filter((n) => !ids.has(String(n.id)))
  const removedEdges = (base.edges || []).filter((e) => !edgeIds.has(String(e.id)))
  return { ...current, nodes: [...current.nodes, ...removedNodes], edges: [...current.edges, ...removedEdges] }
}
