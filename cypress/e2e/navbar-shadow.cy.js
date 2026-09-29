// `box-shadow` does not come back as "none" when Tailwind turns it off: it comes back as the
// list of layers Tailwind builds from its custom properties, all of them zeroed. Comparing
// that against 'none' gives a false negative, so it is read layer by layer: a layer paints if
// its color does not have alpha 0 and one of its lengths is not 0.
const layers = value => (value === 'none' ? [] : value.split(/,\s*(?=rgba?\()/))

const paints = value =>
  layers(value).some(
    layer => !/^rgba\(\s*\d+,\s*\d+,\s*\d+,\s*0\s*\)/.test(layer) && /[1-9]\d*px/.test(layer)
  )

const shadow = $n => window.getComputedStyle($n[0]).boxShadow

describe('Navbar: the shadow', () => {
  it('is on, and comes from the stylesheet instead of a utility on the element', () => {
    cy.visit('/bali/navbar/default')

    cy.get('.navbar').should($n => {
      // The default is `.navbar { @apply shadow-sm }` in navbar/index.css. It has to live
      // there, inside @layer components, because that is the only place where the
      // `.is-transparent` rule can beat it.
      expect($n[0].className, 'no shadow utility in the attribute').to.not.match(
        /\bshadow-(sm|md|none)\b/
      )
      expect(paints(shadow($n)), 'the shadow shows').to.equal(true)
    })
  })

  it('`shadow: false` turns it off from @layer utilities', () => {
    cy.visit('/bali/navbar/default?shadow=false')

    cy.get('.navbar').should($n => {
      expect($n[0].className, 'carries shadow-none').to.match(/\bshadow-none\b/)
      expect(paints(shadow($n)), 'and no shadow is left').to.equal(false)
    })
  })

  // What was broken without anyone noticing: `.navbar.is-transparent { @apply shadow-none }`
  // lives in @layer components and lost against the `shadow-sm` the component itself put on
  // as a utility. Measured before the fix on this same preview, with `is-transparent` on the
  // element, box-shadow was still `0 1px 3px rgba(0,0,0,.1)`.
  it('a transparent navbar no longer keeps it, and is now transparent', () => {
    cy.visit('/bali/navbar/with_sidebar_burger?transparency=true')

    cy.get('.navbar').should('have.class', 'is-transparent')
    cy.get('.navbar').should($n => {
      const cs = window.getComputedStyle($n[0])

      expect(paints(shadow($n)), 'no shadow').to.equal(false)
      // The background lost for the same reason as the shadow, against the `bg-base-100` the
      // `color:` preset emitted as a utility. Measured before: `oklch(1 0 0)`.
      expect(cs.backgroundColor, 'and no background').to.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })
  })

  // The preset still paints when the navbar is NOT transparent — that is what the move to
  // @layer components could have broken silently.
  it('the color preset still paints the opaque navbar', () => {
    cy.visit('/bali/navbar/default?color=primary')

    cy.get('.navbar').should($n => {
      expect($n[0].className, 'Bali class, not a utility').to.match(/\bnavbar-primary\b/)
      expect(window.getComputedStyle($n[0]).backgroundColor).to.not.match(
        /rgba\(0, 0, 0, 0\)|transparent/
      )
    })
  })
})
