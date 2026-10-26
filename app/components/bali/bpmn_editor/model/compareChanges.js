import { laneNodeId } from './flow.js'
import { paletteKeyFor } from './catalog.js'
import { DIFF_MARKS, diffMark } from '../canvas/diffMarks.js'

// What changed, element by element: every node and lane that was added,
// removed or changed, with where to find it in each drawing — the comparison's
// list of changes (chrome/CompareView.jsx) and the export's `changes`.
// `overlay` (diff.js overlayView) gives each entry its id in the overlay.
export function changesOf (base, current, diff, overlay = null) {
  const entries = []
  const before = new Map([...diff.identity].map(([baseId, currentId]) => [currentId, (base.nodes || []).find((n) => String(n.id) === baseId)]))
  const laneBefore = new Map([...diff.lanePairs].map(([baseId, currentId]) => [currentId, (base.lanes || []).find((l) => String(l.id) === baseId)]))
  const docs = { baseDoc: base, currentDoc: current }
  const drawnAs = (kind, id) => (overlay && overlay.drawnAs[kind].get(String(id))) || String(id)
  for (const lane of current.lanes || []) {
    const state = diff.current.lanes[String(lane.id)]
    if (state) entries.push({ key: `cl:${lane.id}`, kind: 'lane', state, reasons: diff.current.reasons[String(lane.id)], element: lane, before: laneBefore.get(String(lane.id)), side: 'current', id: laneNodeId(lane.id), overlayId: laneNodeId(lane.id), ...docs })
  }
  for (const node of current.nodes || []) {
    const state = diff.current.nodes[String(node.id)]
    if (state) entries.push({ key: `cn:${node.id}`, kind: 'node', state, reasons: diff.current.reasons[String(node.id)], element: node, before: before.get(String(node.id)), side: 'current', id: String(node.id), overlayId: String(node.id), ...docs })
  }
  for (const lane of base.lanes || []) {
    if (diff.base.lanes[String(lane.id)] !== 'removed') continue
    entries.push({ key: `bl:${lane.id}`, kind: 'lane', state: 'removed', element: lane, side: 'base', id: laneNodeId(lane.id), overlayId: laneNodeId(drawnAs('lanes', lane.id)), ...docs })
  }
  for (const node of base.nodes || []) {
    if (diff.base.nodes[String(node.id)] !== 'removed') continue
    entries.push({ key: `bn:${node.id}`, kind: 'node', state: 'removed', element: node, side: 'base', id: String(node.id), overlayId: drawnAs('nodes', node.id), ...docs })
  }
  return entries
}

const laneName = (doc, id, t) => {
  const lane = (doc.lanes || []).find((l) => String(l.id) === String(id))
  return lane ? lane.name || t('lane_unnamed') : '—'
}

// The words of a change: what it was and what it is, for the reasons the
// diff gave (diff.js). Type and lane by name, the name itself.
export function detailOf (entry, t) {
  if (entry.state !== 'changed' || !entry.before) return []
  const typeName = (node) => t(`palette_${paletteKeyFor(node)}`)
  return (entry.reasons || []).map((reason) => {
    if (entry.kind === 'node' && reason === 'type') return `${t('compare_detail_type')}: ${typeName(entry.before)} → ${typeName(entry.element)}`
    if (entry.kind === 'node' && reason === 'lane') return `${t('compare_detail_lane')}: ${laneName(entry.baseDoc, entry.before.lane_id, t)} → ${laneName(entry.currentDoc, entry.element.lane_id, t)}`
    if (reason === 'name') return `${t('compare_detail_name')}: ${entry.before.name || t('compare_unnamed')} → ${entry.element.name || t('compare_unnamed')}`
    return t(`compare_detail_${reason}`)
  })
}

// The changes as data, for a host that prints them as a table: one row per
// entry of changesOf, in its order, with the words the list shows.
export function changeRows (base, current, diff, t) {
  return changesOf(base, current, diff).map((entry) => {
    const mark = diffMark(entry.state, entry.reasons)
    const doc = entry.side === 'base' ? entry.baseDoc : entry.currentDoc
    return {
      state: entry.state,
      mark,
      label: t(DIFF_MARKS[mark].label),
      kind: entry.kind,
      id: String(entry.element.id),
      type: entry.kind === 'node' ? entry.element.type : null,
      name: entry.element.name || '',
      lane: entry.kind === 'node' ? laneName(doc, entry.element.lane_id, t) : null,
      reasons: entry.reasons || [],
      detail: detailOf(entry, t)
    }
  })
}
