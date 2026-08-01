// Reads one tier of Bali's overlay stacking scale (app/assets/stylesheets/bali/z_index.css).
//
// Most overlays get their tier straight from CSS. This helper exists for the ones
// that have to hand a z-index to a third-party library instead: tippy.js writes
// the value as an inline style, which cannot carry a `var()` reference, so the
// tooltip and hovercard controllers resolve the tier at connect time. Reading it
// rather than repeating the number is what lets a host move `--bali-z-tooltip`
// and have the tooltips follow.
//
// FALLBACK is tippy's own documented default, used only when Bali's stylesheet is
// not on the page at all — in which case there is no scale to honour and the old
// behaviour is the least surprising one. It is deliberately not a copy of the
// scale's values: a second copy would drift.
const FALLBACK = 9999

export default function zIndexFor (tier) {
  const declared = window.getComputedStyle(document.documentElement)
    .getPropertyValue(`--bali-z-${tier}`)
  const parsed = parseInt(declared, 10)

  return Number.isNaN(parsed) ? FALLBACK : parsed
}
