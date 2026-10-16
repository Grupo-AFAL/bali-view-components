// The text colour a review-note number takes on its tag's colour: black or
// white, whichever contrasts more (WCAG 2.1 relative luminance). The theme's
// base-100 it used before is dark in a dark theme, and a host's #2563eb under
// dark text read at 3.3:1.
const channel = (c) => {
  const v = c / 255
  return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
}

export function parseHex (color) {
  const m = /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(String(color || '').trim())
  if (!m) return null
  const hex = m[1].length === 3 ? m[1].split('').map((c) => c + c).join('') : m[1]
  return [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16))
}

export function luminance ([r, g, b]) {
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

export function contrast (a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi + 0.05) / (lo + 0.05)
}

const WHITE = [255, 255, 255]
const BLACK = [17, 24, 39] // #111827, the darkest text Bali sets

// '#ffffff' or '#111827' for a hex colour; null for anything else (a CSS
// variable), and the stylesheet's own fallback applies.
export function textOn (color) {
  const rgb = parseHex(color)
  if (!rgb) return null
  return contrast(rgb, WHITE) >= contrast(rgb, BLACK) ? '#ffffff' : '#111827'
}
