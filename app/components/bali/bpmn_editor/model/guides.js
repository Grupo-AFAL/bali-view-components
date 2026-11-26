// The alignment guides shown while elements are dragged: a line through the
// centres of a dragged element and of the ones it will line up with.
//
// A guide is a promise about the drop, not a hint about the pointer: the
// local arrangement (arrange.js) puts a dropped element's centre on the grid,
// so the line shows exactly while the centre's grid line is the one another
// element already stands on. Centres, not edges, for the same reason the
// arrangement snaps them: an event, a gateway and a task in one row differ in
// size and share a centre line.
import { nodeBox, orientationOf } from './geometry.js'
import { nodeLabelBox } from './labels.js'
import { GRID } from './arrange.js'

// The 4 px between an event and its name are no stretch to draw a line in.
const SPECK = 4
const snap = (value) => Math.round(value / GRID) * GRID
const AXES = [
  { center: 'cx', start: 'y', size: 'h', line: (at, from, to) => ({ x1: at, y1: from, x2: at, y2: to }) },
  { center: 'cy', start: 'x', size: 'w', line: (at, from, to) => ({ x1: from, y1: at, x2: to, y2: at }) }
]

// `doc` holds the dragged nodes where the pointer has them; `movingIds` says
// which. Returns the lines in pool coordinates, each with its ends and its
// `axis`: 'x' for a vertical line (a shared centre x), 'y' for a horizontal one.
// A line is drawn in the stretches between shapes and the names outside
// them only: through an activity it crossed out its name.
export function alignmentGuides (doc, movingIds) {
  const moving = new Set([...movingIds].map(String))
  const boxes = (doc.nodes || []).filter((n) => n.type !== 'group').map((n) => ({ box: nodeBox(n), moving: moving.has(String(n.id)) }))
  // What the line may not cross: every shape, and every name drawn outside one.
  const orientation = orientationOf(doc)
  const drawn = (doc.nodes || []).filter((n) => n.type !== 'group').flatMap((n) => [nodeBox(n), nodeLabelBox(n, orientation)]).filter(Boolean)
  const dragged = boxes.filter((b) => b.moving)
  const still = boxes.filter((b) => !b.moving)
  const guides = []
  for (const [index, axis] of AXES.entries()) {
    const across = index === 0 ? ['x', 'w'] : ['y', 'h']
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
    for (const [at, { from, to }] of lines) {
      const covered = drawn.filter((b) => b[across[0]] < at && at < b[across[0]] + b[across[1]])
        .map((b) => [b[axis.start], b[axis.start] + b[axis.size]]).sort((a, b) => a[0] - b[0])
      let cursor = from
      for (const [start, end] of covered) {
        if (start >= to) break
        if (start - cursor > SPECK) guides.push({ axis: index === 0 ? 'x' : 'y', ...axis.line(at, cursor, start) })
        cursor = Math.max(cursor, end)
      }
      if (to - cursor > SPECK) guides.push({ axis: index === 0 ? 'x' : 'y', ...axis.line(at, cursor, to) })
    }
  }
  return guides
}
