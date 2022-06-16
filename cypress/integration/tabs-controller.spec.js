describe('TabsController', () => {
  context('default tabs', () => {
    beforeEach(() => {
      cy.visit('/bali/tabs/default')
    })

    it('sets tab active on click', () => {
      cy.get('.tabs li:nth-child(2) a').click()
      cy.get('.tabs li:nth-child(2)').should('have.class', 'is-active')
    })

    it('shows a tab content on click', () => {
      cy.get('.tabs li:nth-child(2) a').click()

      cy.get('.tabs-content div:nth-child(2)').should(
        'not.have.class',
        'is-hidden'
      )
      cy.get('.tabs-content div:nth-child(2)').should(
        'contain',
        'Tab two content'
      )
    })
  })

  context('tabs content on demand', () => {
    beforeEach(() => {
      cy.visit('/bali/tabs/on_demand_content')
    })

    it('load tab content on click', () => {
      cy.get('.tabs li:nth-child(3)').should('not.have.attr', 'data-tab-content-loaded')

      cy.get('.tabs li:nth-child(3) a').click()
      cy.get('.tabs li:nth-child(3)').should('have.attr', 'data-tab-content-loaded')
    })
  })
})
