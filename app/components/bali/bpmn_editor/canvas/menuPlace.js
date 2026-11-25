// Where the quick menu opens beside the selected element, in the canvas'
// own pixels: the first place where it covers no other element and stays
// inside the canvas. Next to a neighbour the menu took the clicks meant for
// it: with «Validate invoice» selected, its icons lay over the gateway
// 130 px on.

// The menu as it opens with every pick (269 × 58 px measured), before «More»:
// placed by the size it opens at, so growing does not move it from under the
// pointer that opened it.
export const MENU_SIZE = { w: 272, h: 60 }
const EDGE = 8

// How far from the element, nearest first: at 44 % zoom a 272 px menu found no
// free place 14 px from «Validate invoice» — the lane below is 60 px away —
// and went back over the gateway. Further out it clears the lane.
const OFFSETS = [14, 44, 74, 104]
const SIDES = [
  ['right', 'start', (n, by) => ({ x: n.x + n.w + by, y: n.y })],
  ['left', 'start', (n, by) => ({ x: n.x - by - MENU_SIZE.w, y: n.y })],
  ['bottom', 'start', (n, by) => ({ x: n.x, y: n.y + n.h + by })],
  ['bottom', 'end', (n, by) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y + n.h + by })],
  ['bottom', 'center', (n, by) => ({ x: n.x + (n.w - MENU_SIZE.w) / 2, y: n.y + n.h + by })],
  ['top', 'start', (n, by) => ({ x: n.x, y: n.y - by - MENU_SIZE.h })],
  ['top', 'end', (n, by) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y - by - MENU_SIZE.h })],
  ['top', 'center', (n, by) => ({ x: n.x + (n.w - MENU_SIZE.w) / 2, y: n.y - by - MENU_SIZE.h })]
]
// In order of preference: { side, align, offset } are NodeToolbar's; `corner`
// is the menu's top-left for the element's box.
export const MENU_PLACES = OFFSETS.flatMap((offset) => SIDES.map(([side, align, at]) => ({ side, align, offset, corner: (n) => at(n, offset) })))

// The index in MENU_PLACES for the element at `me`, with `others` on the
// canvas and `pane` its size (less the open properties panel), or -1 when
// every place is taken. `current` is where the menu is now: it stays there
// while that place is still free, so a pan or a zoom that frees a place
// further up the list does not make it jump.
export function menuPlace (me, others, pane, current = -1) {
  const free = ({ corner }) => {
    const { x, y } = corner(me)
    if (x < EDGE || y < EDGE || x + MENU_SIZE.w > pane.w - EDGE || y + MENU_SIZE.h > pane.h - EDGE) return false
    return !others.some((o) => x < o.x + o.w && o.x < x + MENU_SIZE.w && y < o.y + o.h && o.y < y + MENU_SIZE.h)
  }
  if (current >= 0 && free(MENU_PLACES[current])) return current
  return MENU_PLACES.findIndex(free)
}
