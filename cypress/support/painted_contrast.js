// WCAG contrast of what an element paints — its text unless told otherwise — as it is PAINTED:
// its colour at the colour's alpha times every `opacity` between it and the first opaque
// background, composited over that background on a 1px canvas. `getComputedStyle().color` carries
// only the colour's alpha: read that way the SplitView filter count reported 6.38:1 while it
// painted 2.92:1 (#1202). Every translucent background on the way is painted over that ground
// first, the farthest first: SideMenu's active item measured 5.25:1 against the bare page and
// 4.51 over its own primary/10 tint (#1221).
//
// What it still does not see: the `opacity` of the node that carries a tint is not applied to the
// tint, which on a light theme measures the tint darker than it paints (the safe side); a
// `background-image` or the background of a pseudo-element, which the caller hands over as
// `under`; and a `filter`, an inset `box-shadow`, an `opacity` above that background, a
// pseudo-element drawn over the text or a `::first-line` or `::first-letter` colour, which the
// caller has to rule out.
//
// `over` is where the search for that background starts. Text starts at its own element; a shape
// drawn in its `color` — a WorkflowSteps segment, filled with `bg-current` — would find its own
// fill and measure 1:1 against itself, so it starts at the parent.
//
// `property` is the colour measured, `color` unless told otherwise. A shape not drawn in `color`
// — an outline in `borderTopColor`, a line in `backgroundColor` — passes the property; a line is
// its own fill, so it starts at the parent too.
//
// `pseudo` reads the colour off a pseudo-element of `el` — an input's `::placeholder` — and that
// pseudo-element's own `opacity`, while the search for the ground still starts at `el`. daisyUI
// paints the placeholder inside an `.input` in full `base-content` at `opacity: .5`: read without
// that opacity, the Filters search placeholder measured 14.68:1 on `afal` and painted 3.05.
//
// `under` is a fill the shape sits straight on, inside the ground the search found. The colour is
// painted over it and measured against it and against that ground, and the lower of the two is
// the answer: the outline of a WorkflowSteps marker on its `::before` disc, in a base-200 card on
// `afal`, read 3.38:1 composited over the card alone and paints 3.17 (#1249).

export const luminance = ([r, g, b]) => {
  const channel = (v) => {
    v /= 255
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
  }
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

export const contrastRatio = (a, b) => (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)

const contrast = (a, b) => contrastRatio(luminance(a), luminance(b))

export const paintedContrast = (el, { over = el, property = 'color', pseudo, under } = {}) => {
  if (!over.contains(el)) throw new Error('paintedContrast: `over` has to be `el` or one of its ancestors')

  const win = el.ownerDocument.defaultView
  const canvas = el.ownerDocument.createElement('canvas')
  canvas.width = canvas.height = 1
  const ctx = canvas.getContext('2d', { willReadFrequently: true })
  const paint = (colour, alpha = 1) => {
    ctx.globalAlpha = alpha
    ctx.fillStyle = colour
    ctx.fillRect(0, 0, 1, 1)
    return [...ctx.getImageData(0, 0, 1, 1).data]
  }

  let opacity = pseudo ? parseFloat(win.getComputedStyle(el, pseudo).opacity) : 1
  let groundColour = 'white'
  const tints = []
  for (let node = el; node !== over; node = node.parentElement) {
    opacity *= parseFloat(win.getComputedStyle(node).opacity)
  }
  for (let node = over; node; node = node.parentElement) {
    const style = win.getComputedStyle(node)
    opacity *= parseFloat(style.opacity)
    ctx.clearRect(0, 0, 1, 1)
    const alpha = paint(style.backgroundColor)[3]
    if (alpha === 255) {
      groundColour = style.backgroundColor
      break
    }
    if (alpha > 0) tints.unshift(style.backgroundColor)
  }

  let ground = paint(groundColour)
  tints.forEach((tint) => { ground = paint(tint) })
  const bed = under ? paint(under) : ground
  const ink = paint(win.getComputedStyle(el, pseudo)[property], opacity)
  return Math.min(contrast(ink, ground), contrast(ink, bed))
}

// The 8-bit sRGB pixel of colours painted one over the other, in order, on a 1px canvas: a
// translucent border has to land on what it is drawn over, or it reads as its opaque ink.
export const paintedPixel = (doc, ...colours) => {
  const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 })
    .getContext('2d', { willReadFrequently: true })
  colours.forEach((colour) => {
    ctx.fillStyle = colour
    ctx.fillRect(0, 0, 1, 1)
  })
  const pixel = [...ctx.getImageData(0, 0, 1, 1).data]
  // A canvas hands back a translucent pixel un-premultiplied — the bare ink — so a colour
  // with nothing opaque under it would measure as if it were solid.
  if (pixel[3] !== 255) throw new Error(`paintedPixel: ${colours.join(' over ')} is not opaque`)
  return pixel.slice(0, 3)
}

export const paintedLuminance = (doc, ...colours) => luminance(paintedPixel(doc, ...colours))

// The pixel `text-soft-error` paints in the current theme: the ink the error variants of Alert,
// Tag and Button take.
export const errorInk = (doc) => {
  const probe = doc.createElement('span')
  probe.className = 'text-soft-error'
  doc.body.append(probe)
  const ink = paintedPixel(doc, doc.defaultView.getComputedStyle(probe).color)
  probe.remove()
  return ink
}
