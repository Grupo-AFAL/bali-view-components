// How the APP wants a lane or a node to look (`appearance`): a colour, dimmed,
// a short badge. Server data, like `stencil` and `issues`: the editor draws it
// and never sends it back (document.js forSave). Bali gives it no meaning —
// the app decides what a colour or a badge says and explains it in the legend.
//
// Mirror Bali::BpmnEditor::Data::APPEARANCE_COLLECTIONS, APPEARANCE_KEYS and
// BADGE_MAX (contract_test.rb).
export const APPEARANCE_COLLECTIONS = ['lanes', 'nodes']
export const APPEARANCE_KEYS = ['color', 'dimmed', 'badge']
export const BADGE_MAX = 24

const HEX = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i

// What of an element's `appearance` can be drawn, or null. Data validated it
// on the server; a document built in the browser is read just as defensively.
export function appearanceOf (element) {
  const a = element && element.appearance
  if (!a || typeof a !== 'object') return null
  const color = typeof a.color === 'string' && HEX.test(a.color.trim()) ? a.color.trim() : null
  const dimmed = a.dimmed === true
  const badge = typeof a.badge === 'string' && a.badge.trim() ? a.badge.trim().slice(0, BADGE_MAX) : null
  return color || dimmed || badge ? { color, dimmed, badge } : null
}

// Whether any lane or node of the document has a badge to show — what the
// «Show badges» switch needs before it is offered at all.
export function hasBadges (doc) {
  return Boolean(doc && APPEARANCE_COLLECTIONS.some((key) => (doc[key] || []).some((element) => {
    const look = appearanceOf(element)
    return look && look.badge
  })))
}

export function withoutAppearance (element) {
  if (!element || !('appearance' in element)) return element
  const { appearance, ...rest } = element
  return rest
}
