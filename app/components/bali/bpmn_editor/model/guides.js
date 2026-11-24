// The alignment guides shown while elements are dragged: a line through the
// centres of a dragged element and of the ones it will line up with.
//
// A guide is a promise about the drop, not a hint about the pointer: the
// local arrangement (arrange.js) puts a dropped element's centre on the grid,
// so the line shows exactly while the centre's grid line is the one another
// element already stands on. Centres, not edges, for the same reason the
// arrangement snaps them: an event, a gateway and a task in one row differ in
// size and share a centre line.
import { nodeBox } from './geometry.js'
import { GRID } from './arrange.js'

const snap = (value) => Math.round(value / GRID) * GRID
const AXES = [
  { center: 'cx', start: 'y', size: 'h', line: (at, from, to) => ({ x1: at, y1: from, x2: at, y2: to }) },
  { center: 'cy', start: 'x', size: 'w', line: (at, from, to) => ({ x1: from, y1: at, x2: to, y2: at }) }
]

// `doc` holds the dragged nodes where the pointer has them; `movingIds` says
// which. Returns [{ axis: 'x' | 'y', x1, y1, x2, y2 }] in pool coordinates:
// 'x' is a vertical line (shared centre x), 'y' a horizontal one.
export function alignmentGuides (doc, movingIds) {
  const moving = new Set([...movingIds].map(String))
  const boxes = (doc.nodes || []).filter((n) => n.type !== 'group').map((n) => ({ box: nodeBox(n), moving: moving.has(String(n.id)) }))
  const dragged = boxes.filter((b) => b.moving)
  const still = boxes.filter((b) => !b.moving)
  const guides = []
  for (const [index, axis] of AXES.entries()) {
    const lines = new Map()
    for (const { box } of dragged) {
      const at = snap(box[axis.center])
      const aligned = still.filter((s) => s.box[axis.center] === at)
      if (!aligned.length) continue
      const spans = [box, ...aligned.map((s) => s.box)]
      const from = Math.min(...spans.map((b) => b[axis.start]), lines.has(at) ? lines.get(at).from : Infinity)
      const to = Math.max(...spans.map((b) => b[axis.start] + b[axis.size]), lines.has(at) ? lines.get(at).to : -Infinity)
      lines.set(at, { from, to })
    }
    for (const [at, { from, to }] of lines) guides.push({ axis: index === 0 ? 'x' : 'y', ...axis.line(at, from, to) })
  }
  return guides
}
