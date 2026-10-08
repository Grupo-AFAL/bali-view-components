import { errorInk, paintedContrast, paintedPixel } from '../support/painted_contrast'
import { THEMES, useTheme } from '../support/themes'

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
// contrasts with base-100 on every theme by construction (#1126). Error takes
// text-soft-error's own ink, the red of the FormBuilder's errors (#1333).
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

  // Every theme, daisyUI's own pair included: the fix has to hold where the
  // `*-content` token would NOT have (a dark theme puts a dark `*-content`
  // over a dark tint — measured at 1.01–1.48 with that token).

  // The alert's body, the `<div>` #1126 reported unreadable: inside the title's
  // column when there is a title, straight under the alert when there is not.
  const ALERT_BODY = ':scope > .flex-col > div:last-child, :scope > div:not(.flex-col)'

  const expectErrorInk = (els, count, theme) => {
    const errors = els.filter(el => el.matches('.alert-error, .badge-error'))
    expect(errors, 'error variants').to.have.length(count)
    errors.forEach((el) => {
      const doc = el.ownerDocument
      expect(paintedPixel(doc, getComputedStyle(el).color), `${theme}: ${el.className} in text-soft-error's ink`).to.deep.equal(errorInk(doc))
    })
  }

  // Nothing is measured while a transition runs anywhere in the document: its
  // first frame still paints the previous theme — on the text, or on the
  // ancestor an outline variant takes its ground from — and that frame can pass
  // (docs/reference/testing-traps.md). None of the three previews animates on
  // its own, so the document does go still.
  const expectSettled = (el) => {
    expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  }

  it('every tinted alert reads at AA on every theme', () => {
    cy.visit('/bali/alert/all_combinations')
    THEMES.forEach((theme) => {
      useTheme(theme)

      cy.get(ALERTS).should(($alerts) => {
        const alerts = $alerts.toArray()
        expectSettled(alerts[0])
        expect(alerts, 'soft, outline and dash alerts').to.have.length.at.least(15)

        alerts.forEach((alert) => {
          expect(paintedContrast(alert.querySelector(ALERT_BODY)), `${theme}: ${alert.className}`).to.be.at.least(AA)
        })
        expectErrorInk(alerts, 3, theme)
      })
    })
  })

  it('every tinted tag reads at AA on every theme', () => {
    cy.visit('/bali/tag/all_combinations')
    THEMES.forEach((theme) => {
      useTheme(theme)

      cy.get(TAGS).should(($tags) => {
        const tags = $tags.toArray()
        expectSettled(tags[0])
        expect(tags, 'soft, outline and dash tags').to.have.length.at.least(52)

        tags.forEach((tag) => {
          expect(paintedContrast(tag), `${theme}: ${tag.className}`).to.be.at.least(AA)
        })
        expectErrorInk(tags, 6, theme)
      })
    })
  })

  // The other half of the decision: the alert's icon is what still says "warning"
  // at a glance, so it keeps daisyUI's accent rather than the mixed text colour.
  ;['soft', 'outline', 'dash'].forEach((style) => {
    it(`keeps the accent colour on the ${style} alert icon`, () => {
      cy.visit(`/bali/alert/soft_block?style=${style}`)
      useTheme('afal')

      cy.get(`.alert-${style}.alert-warning`).should(([alert]) => {
        expectSettled(alert)
        const doc = alert.ownerDocument
        const icon = alert.querySelector('.icon-component')
        const body = alert.querySelector(ALERT_BODY)
        const accent = getComputedStyle(alert).getPropertyValue('--alert-color')

        expect(paintedPixel(doc, getComputedStyle(icon).color), 'icon is the accent').to.deep.equal(paintedPixel(doc, accent))
        expect(paintedPixel(doc, getComputedStyle(body).color), 'text is not').to.not.deep.equal(paintedPixel(doc, accent))
      })
    })
  })

  // And the ring of an outline tag: daisyUI draws it with `border-color:
  // currentColor`, so once the text stops being the accent the border has to be
  // restated from `--badge-color` or the pill loses its colour altogether.
  it('keeps the accent colour on the outline tag border', () => {
    cy.visit('/bali/alert/soft_block?style=outline')
    useTheme('afal')

    cy.get('.badge-outline.badge-warning').should(([tag]) => {
      expectSettled(tag)
      const doc = tag.ownerDocument
      const accent = getComputedStyle(tag).getPropertyValue('--badge-color')

      expect(paintedPixel(doc, getComputedStyle(tag).borderTopColor), 'border is the accent').to.deep.equal(paintedPixel(doc, accent))
      expect(paintedPixel(doc, getComputedStyle(tag).color), 'text is not').to.not.deep.equal(paintedPixel(doc, accent))
    })
  })
})
