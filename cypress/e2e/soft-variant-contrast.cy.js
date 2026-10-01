import { paintedContrast } from '../support/painted_contrast'

// The text colour of the soft, outline and dash variants, which only exists in
// compiled CSS and so cannot be seen by a component test.
//
// daisyUI 5 paints `.alert-soft`/`.badge-soft` with the ACCENT colour as text
// over an 8% tint of that same accent, and `-outline`/`-dash` with the accent
// over the bare page. On a light theme the accent is light by design — it is a
// background colour — so the text was light-on-light: measured on the `afal`
// theme before the override, soft warning 1.63:1, success 1.83, info 1.99, error
// 2.55, and outline/dash 1.69 · 1.92 · 2.10 · 2.75, against the AA floor of 4.5.
// Bali's override mixes the accent 40% into base-content instead, which
// contrasts with base-100 on every theme by construction (#1126).
//
// The override is unlayered on purpose: daisyUI emits its components inside
// `@layer utilities`, and layers beat specificity, so the same rule in
// `@layer components` would lose however specific it was. That is exactly what
// this spec guards — a well-meaning move into a layer would pass every Ruby
// test and silently bring the illegible text back.
describe('tinted variant text contrast', () => {
  const AA = 4.5
  const ALERTS = '.alert-soft, .alert-outline, .alert-dash'
  const TAGS = '.badge-soft, .badge-outline, .badge-dash'

  // The three Bali themes plus daisyUI's own pair: the fix has to hold where the
  // `*-content` token would NOT have (a dark theme puts a dark `*-content`
  // over a dark tint — measured at 1.03–1.48 with that token).
  const THEMES = ['light', 'dark', 'afal', 'afal-dark', 'costa-norte']

  // Any CSS colour string → [r, g, b], through a 1px canvas. Chrome serialises
  // `color-mix()` results as `oklab(…)` and the theme tokens as `oklch(…)`;
  // parsing those by hand is where a spec like this goes wrong, and the canvas
  // resolves whatever the browser itself can paint.
  const rgb = (doc, css) => {
    const canvas = doc.createElement('canvas')
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext('2d')
    ctx.fillStyle = css
    ctx.fillRect(0, 0, 1, 1)
    return [...ctx.getImageData(0, 0, 1, 1).data].slice(0, 3)
  }

  // The alert's body is a `<span>`; the icon is skipped because it deliberately
  // keeps the accent (see below).
  const textOf = (el) => el.querySelector('span:not(.icon-component)') || el

  const withTheme = (theme, fn) => {
    cy.document().then((doc) => {
      doc.documentElement.setAttribute('data-theme', theme)
      fn(doc)
    })
  }

  // Nothing is measured while a colour transition runs: its first frame still
  // paints the previous theme, which can pass (docs/reference/testing-traps.md).
  const everyTextReadsAtAA = (theme, selector, fewest) => {
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

    cy.get(selector).should(($els) => {
      const els = $els.toArray()
      expect(els.flatMap(el => el.getAnimations({ subtree: true })), 'colour transitions settled').to.have.length(0)
      expect(els, 'the preview renders soft, outline and dash').to.have.length.greaterThan(fewest)

      els.forEach((el) => {
        expect(paintedContrast(textOf(el)), `${theme}: ${el.className}`).to.be.at.least(AA)
      })
    })
  }

  THEMES.forEach((theme) => {
    it(`every tinted alert reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/alert/all_combinations')
      everyTextReadsAtAA(theme, ALERTS, 11)
    })

    it(`every tinted tag reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/tag/all_combinations')
      everyTextReadsAtAA(theme, TAGS, 20)
    })
  })

  // The other half of the decision: the alert's icon is what still says "warning"
  // at a glance, so it keeps daisyUI's accent rather than the mixed text colour.
  ;['soft', 'outline', 'dash'].forEach((style) => {
    it(`keeps the accent colour on the ${style} alert icon`, () => {
      cy.visit(`/bali/alert/soft_block?style=${style}`)

      withTheme('afal', (doc) => {
        const alert = doc.querySelector(`.alert-${style}.alert-warning`)
        const icon = alert.querySelector('.icon-component')
        const text = alert.querySelector('span:not(.icon-component)')
        const accent = getComputedStyle(alert).getPropertyValue('--alert-color')

        expect(rgb(doc, getComputedStyle(icon).color), 'icon is the accent').to.deep.equal(rgb(doc, accent))
        expect(rgb(doc, getComputedStyle(text).color), 'text is not').to.not.deep.equal(rgb(doc, accent))
      })
    })
  })

  // And the ring of an outline tag: daisyUI draws it with `border-color:
  // currentColor`, so once the text stops being the accent the border has to be
  // restated from `--badge-color` or the pill loses its colour altogether.
  it('keeps the accent colour on the outline tag border', () => {
    cy.visit('/bali/alert/soft_block?style=outline')

    withTheme('afal', (doc) => {
      const tag = doc.querySelector('.badge-outline.badge-warning')
      const accent = getComputedStyle(tag).getPropertyValue('--badge-color')

      expect(rgb(doc, getComputedStyle(tag).borderTopColor), 'border is the accent').to.deep.equal(rgb(doc, accent))
      expect(rgb(doc, getComputedStyle(tag).color), 'text is not').to.not.deep.equal(rgb(doc, accent))
    })
  })
})
