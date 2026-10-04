// The themes the gem ships — the files test_the_expected_themes_ship_with_the_gem lists in
// test/bali/themes_test.rb — and, for the contrast guards, daisyUI's own pair besides.
export const BALI_THEMES = ['afal', 'afal-dark', 'costa-norte', 'costa-norte-dark']
export const THEMES = ['light', 'dark', ...BALI_THEMES]

// The colour a theme token computes to inside `el`, in the form `getComputedStyle().color` reports
// it, so the two compare as strings.
export const token = (el, name) => {
  const probe = el.ownerDocument.createElement('span')
  probe.style.color = `var(--color-${name})`
  el.append(probe)
  const { color } = el.ownerDocument.defaultView.getComputedStyle(probe)
  probe.remove()
  return color
}
