// The text colour of the soft variants, which only exists in compiled CSS and so
// cannot be seen by a component test.
//
// daisyUI 5 paints `.alert-soft` and `.badge-soft` with the ACCENT colour as text
// over an 8% tint of that same accent. On a light theme the accent is light by
// design — it is a background colour — so the text was light-on-light: measured
// on the `afal` theme before the override, warning 1.63:1, success 1.83, info
// 1.99, error 2.55 against the AA floor of 4.5. Bali's override mixes the accent
// 40% into base-content instead, which contrasts with base-100 on every theme
// by construction (#1126).
//
// The override is unlayered on purpose: daisyUI emits its components inside
// `@layer utilities`, and layers beat specificity, so the same rule in
// `@layer components` would lose however specific it was. That is exactly what
// this spec guards — a well-meaning move into a layer would pass every Ruby
// test and silently bring the illegible text back.
describe('soft variant text contrast', () => {
  const AA = 4.5

  // Both Bali themes plus daisyUI's own pair: the fix has to hold where the
  // `*-content` token would NOT have (a dark theme puts a dark `*-content`
  // over a dark tint — measured at 1.03–1.48 with that token).
  const THEMES = ['afal', 'afal-dark', 'light', 'dark']

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

  const luminance = ([r, g, b]) => {
    const channel = (v) => {
      v /= 255
      return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
    }
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
  }

  const contrast = (doc, foreground, background) => {
    const [high, low] = [luminance(rgb(doc, foreground)), luminance(rgb(doc, background))].sort((a, b) => b - a)
    return (high + 0.05) / (low + 0.05)
  }

  // The text node's colour against the element's own background. The alert's
  // body is a `<span>`; the icon is skipped because it deliberately keeps the
  // accent (see below).
  const textContrast = (doc, el) => {
    const text = el.querySelector('span:not(.icon-component)') || el
    return contrast(doc, getComputedStyle(text).color, getComputedStyle(el).backgroundColor)
  }

  const withTheme = (theme, fn) => {
    cy.document().then((doc) => {
      doc.documentElement.setAttribute('data-theme', theme)
      fn(doc)
    })
  }

  THEMES.forEach((theme) => {
    it(`every soft alert reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/alert/all_combinations')

      withTheme(theme, (doc) => {
        const alerts = [...doc.querySelectorAll('.alert-soft')]
        expect(alerts, 'the preview renders soft alerts').to.have.length.greaterThan(3)

        alerts.forEach((el) => {
          expect(textContrast(doc, el), `${theme}: ${el.className}`).to.be.at.least(AA)
        })
      })
    })

    it(`every soft tag reads at AA on the ${theme} theme`, () => {
      cy.visit('/bali/tag/all_combinations')

      withTheme(theme, (doc) => {
        const tags = [...doc.querySelectorAll('.badge-soft')]
        expect(tags, 'the preview renders soft tags').to.have.length.greaterThan(6)

        tags.forEach((el) => {
          expect(textContrast(doc, el), `${theme}: ${el.className}`).to.be.at.least(AA)
        })
      })
    })
  })

  // The other half of the decision: the alert's icon is what still says "warning"
  // at a glance, so it keeps daisyUI's accent rather than the mixed text colour.
  it('keeps the accent colour on the soft alert icon', () => {
    cy.visit('/bali/alert/soft_block')

    withTheme('afal', (doc) => {
      const alert = doc.querySelector('.alert-soft.alert-warning')
      const icon = alert.querySelector('.icon-component')
      const text = alert.querySelector('span:not(.icon-component)')
      const accent = getComputedStyle(alert).getPropertyValue('--alert-color')

      expect(rgb(doc, getComputedStyle(icon).color), 'icon is the accent').to.deep.equal(rgb(doc, accent))
      expect(rgb(doc, getComputedStyle(text).color), 'text is not').to.not.deep.equal(rgb(doc, accent))
    })
  })
})
