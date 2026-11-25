// Where the quick menu opens beside the selected element, in the canvas'
// own pixels: the first place where it covers no other element and stays
// inside the canvas. Next to a neighbour the menu took the clicks meant for
// it: with «Validate invoice» selected, its icons lay over the gateway
// 130 px on.

// The menu as it opens with every pick (269 × 58 px measured), before «More»:
// placed by the size it opens at, so growing does not move it from under the
// pointer that opened it.
export const MENU_SIZE = { w: 272, h: 60 }
export const MENU_OFFSET = 14
const EDGE = 8

// In order of preference: [side, align, the menu's top-left corner for the
// element's box `n`]. Side and align are NodeToolbar's.
export const MENU_PLACES = [
  ['right', 'start', (n) => ({ x: n.x + n.w + MENU_OFFSET, y: n.y })],
  ['left', 'start', (n) => ({ x: n.x - MENU_OFFSET - MENU_SIZE.w, y: n.y })],
  ['bottom', 'start', (n) => ({ x: n.x, y: n.y + n.h + MENU_OFFSET })],
  ['bottom', 'end', (n) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y + n.h + MENU_OFFSET })],
  ['top', 'start', (n) => ({ x: n.x, y: n.y - MENU_OFFSET - MENU_SIZE.h })],
  ['top', 'end', (n) => ({ x: n.x + n.w - MENU_SIZE.w, y: n.y - MENU_OFFSET - MENU_SIZE.h })]
]

// The index in MENU_PLACES for the element at `me`, with `others` on the
// canvas and `pane` its size (less the open properties panel), or -1 when
// every place is taken. `current` is where the menu is now: it stays there
// while that place is still free, so a pan or a zoom that frees a place
// further up the list does not make it jump.
export function menuPlace (me, others, pane, current = -1) {
  const free = ([, , corner]) => {
    const { x, y } = corner(me)
    if (x < EDGE || y < EDGE || x + MENU_SIZE.w > pane.w - EDGE || y + MENU_SIZE.h > pane.h - EDGE) return false
    return !others.some((o) => x < o.x + o.w && o.x < x + MENU_SIZE.w && y < o.y + o.h && o.y < y + MENU_SIZE.h)
  }
  if (current >= 0 && free(MENU_PLACES[current])) return current
  return MENU_PLACES.findIndex(free)
}
