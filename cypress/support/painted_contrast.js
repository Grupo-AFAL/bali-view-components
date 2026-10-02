// WCAG contrast of an element's text as it is PAINTED: its colour at the colour's alpha times
// every `opacity` between it and the first opaque background, composited over that background on
// a 1px canvas. `getComputedStyle().color` carries only the colour's alpha: read that way the
// SplitView filter count reported 6.38:1 while it painted 2.92:1 (#1202). Every translucent
// background on the way is painted over that ground first, the farthest first: SideMenu's active
// item reads 5.25:1 against the bare page and 4.51 over its own primary/10 tint (#1221).
//
// Two things it still does not see: the `opacity` of the node that carries a tint is not applied
// to the tint, which on a light theme measures the tint darker than it paints (the safe side), and
// the background of a pseudo-element.
//
// `over` is where the search for that background starts. Text starts at its own element; a shape
// drawn in its `color` — a WorkflowSteps segment, filled with `bg-current` — would find its own
// fill and measure 1:1 against itself, so it starts at the parent.

export const luminance = ([r, g, b]) => {
  const channel = (v) => {
    v /= 255
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
  }
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

export const paintedContrast = (el, { over = el } = {}) => {
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

  let opacity = 1
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
  const text = paint(win.getComputedStyle(el).color, opacity)
  const [high, low] = [luminance(text), luminance(ground)].sort((x, y) => y - x)
  return (high + 0.05) / (low + 0.05)
}

// The luminance of colours painted one over the other, in order, on a 1px canvas: a
// translucent border has to land on what it is drawn over, or it reads as its opaque ink.
export const paintedLuminance = (doc, ...colours) => {
  const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 })
    .getContext('2d', { willReadFrequently: true })
  colours.forEach((colour) => {
    ctx.fillStyle = colour
    ctx.fillRect(0, 0, 1, 1)
  })
  const pixel = [...ctx.getImageData(0, 0, 1, 1).data]
  // A canvas hands back a translucent pixel un-premultiplied — the bare ink — so a colour
  // with nothing opaque under it would measure as if it were solid.
  if (pixel[3] !== 255) throw new Error(`paintedLuminance: ${colours.join(' over ')} is not opaque`)
  return luminance(pixel)
}
