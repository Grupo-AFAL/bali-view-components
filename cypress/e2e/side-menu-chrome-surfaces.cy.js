// A rail with its own `theme:` is chrome next to the page, and its hover, borders and the
// switcher's panel are meant to sit a step ABOVE the rail. daisyUI's `dark` and Bali's dark
// themes step base-200/300 DOWN from base-100 — the page sits under its cards — so inside the
// rail that panel measured 1.05–1.07:1 against the rail and its border went darker still.
describe('SideMenu chrome surfaces', () => {
  const luminance = (doc, colour) => {
    const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 })
      .getContext('2d', { willReadFrequently: true })
    ctx.fillStyle = colour
    ctx.fillRect(0, 0, 1, 1)
    return [...ctx.getImageData(0, 0, 1, 1).data].slice(0, 3)
      .map(v => v / 255)
      .map(v => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4))
      .reduce((sum, v, i) => sum + v * [0.2126, 0.7152, 0.0722][i], 0)
  }

  ;['dark', 'afal-dark', 'costa-norte-dark'].forEach((theme) => {
    it(`lifts the panel and the borders above a ${theme} rail`, () => {
      cy.visit(`/bali/side_menu/dark_chrome?theme=${theme}`)

      cy.get(`.side-menu-component[data-theme="${theme}"]`).should(($rail) => {
        const doc = $rail[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const rail = luminance(doc, style($rail[0]).backgroundColor)
        const panel = luminance(doc, style($rail[0].querySelector('.dropdown-content')).backgroundColor)
        const border = luminance(doc, style($rail[0].querySelector('.side-menu-expanded')).borderBottomColor)

        expect(panel, `${theme}: panel above the rail`).to.be.above(rail)
        expect(border, `${theme}: border above the panel`).to.be.above(panel)
      })
    })
  })
})
