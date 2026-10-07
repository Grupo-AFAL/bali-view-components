// #1371. The growth itself has worked since #723; what these cover is where it STOPS, in both
// directions — the two ends that were missing. Heights are read off the rendered box, because
// the controller writes them as an inline style and that is exactly what was going stale.
describe('Textarea auto-grow bounds', () => {
  const capped = () => cy.get('#auto_grow_capped')
  const prefilled = () => cy.get('#auto_grow_prefilled')
  const heightOf = $el => $el[0].getBoundingClientRect().height

  beforeEach(() => {
    cy.visit('/bali/form/text_area/auto_grow_bounds')
  })

  context('growing', () => {
    it('grows with the content', () => {
      capped().then($field => {
        const before = heightOf($field)
        capped().type('a line\n'.repeat(3), { delay: 0 })
        capped().should($grown => expect(heightOf($grown)).to.be.greaterThan(before))
      })
    })

    it('keeps the scrollbar away while the content fits', () => {
      capped().type('one line', { delay: 0 })
      capped().should($field => {
        expect(getComputedStyle($field[0]).overflowY).to.equal('hidden')
      })
    })
  })

  // The upper bound. Before the fix the controller wrote `overflow: hidden` once at setup, so
  // a `max-height` from the host clipped the text with no way to reach it: no scrollbar, no
  // scrolling, and therefore no way to cap an auto-grow field at all.
  context('at the cap', () => {
    beforeEach(() => {
      capped().type('a line\n'.repeat(40), { delay: 0 })
    })

    it('stops at the max-height the CSS gives it', () => {
      capped().should($field => {
        const max = parseFloat(getComputedStyle($field[0]).maxHeight)
        expect(max).to.be.greaterThan(0)
        expect(heightOf($field)).to.be.closeTo(max, 1)
      })
    })

    it('scrolls the overflow instead of hiding it', () => {
      capped().should($field => {
        expect(getComputedStyle($field[0]).overflowY).to.equal('auto')
        expect($field[0].scrollHeight).to.be.greaterThan($field[0].clientHeight)
      })
    })
  })

  // The lower bound. `form.reset()` clears the value WITHOUT firing `input`, so the inline
  // height from the last keystroke survived the reset: the field stayed grown and empty.
  context('on reset', () => {
    it('returns to the height it had empty', () => {
      capped().then($field => {
        const empty = heightOf($field)

        capped().type('a line\n'.repeat(6), { delay: 0 })
        capped().should($grown => expect(heightOf($grown)).to.be.greaterThan(empty))

        cy.get('button[type="reset"]').click()

        capped().should('have.value', '')
        capped().should($reset => expect(heightOf($reset)).to.equal(empty))
      })
    })

    // A field RENDERED with content measured its floor off that content, so it could never
    // shrink back to its `rows` — and a reset on such a form left it grown exactly like the
    // bug above.
    it('returns a pre-filled field to its rows, not to what it was rendered with', () => {
      prefilled().then($field => {
        const asRendered = heightOf($field)

        cy.get('button[type="reset"]').click()

        // Reset restores the rendered value, so this one does NOT shrink on reset…
        prefilled().should($after => expect(heightOf($after)).to.equal(asRendered))

        // …but emptying it by hand goes below what it was rendered with, down to two rows.
        prefilled().clear()
        prefilled().should($empty => expect(heightOf($empty)).to.be.lessThan(asRendered))
      })
    })
  })
})
