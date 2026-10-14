// #1440 — SimpleFilters' `multiple:` select is a `.slim-select-sm`, whose height was pinned at
// 32px: with four values in its 224px box the second row of chips came out cut, row 1 at -11px
// and row 2 ending at 43px. The chips are measured once their entry animation (`ss-valueIn`, a
// scale) has finished, since a scaled chip reports a smaller box than the one it lays out; with
// `fill: both` a finished one stays listed, so it is the running ones that are counted.
const PREVIEW = '/bali/data_table/simple_filters/multiple'

const running = el => el.getAnimations({ subtree: true }).filter(animation => animation.playState !== 'finished')

const pick = countries => {
  cy.get('.ss-main').click()
  countries.forEach(country => cy.contains('.ss-content.ss-open .ss-option', new RegExp(`^${country}$`)).click())
  cy.get('.ss-value').should('have.length', countries.length)
}

describe('SimpleFilters: a multiple select', () => {
  beforeEach(() => {
    cy.viewport(1280, 600)
    cy.visit(PREVIEW)
  })

  it('stays as tall as the Filter button with one row of chips', () => {
    pick(['USA', 'France'])

    cy.get('button[type="submit"]').then($submit => {
      cy.get('.ss-main').should($main => {
        expect(running($main[0])).to.have.length(0)
        expect($main[0].getBoundingClientRect().height).to.equal($submit[0].getBoundingClientRect().height)
      })
    })
  })

  it('grows a second row of chips instead of cutting it', () => {
    pick(['USA', 'France', 'Germany', 'Japan'])

    cy.get('.ss-main').should($main => {
      expect(running($main[0])).to.have.length(0)
      const box = $main[0].getBoundingClientRect()
      const chips = [...$main[0].querySelectorAll('.ss-value')].map(chip => chip.getBoundingClientRect())

      expect(new Set(chips.map(chip => chip.top)).size, 'rows of chips').to.be.greaterThan(1)
      chips.forEach(chip => {
        expect(chip.top, 'chip top').to.be.at.least(box.top)
        expect(chip.bottom, 'chip bottom').to.be.at.most(box.bottom)
      })
    })
  })
})
