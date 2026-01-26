describe('TabsController', () => {
  context('default tabs', () => {
    beforeEach(() => {
      cy.visit('/bali/tabs/default')
    })

    it('sets tab active on click', () => {
      // DaisyUI tabs use direct <a role="tab" class="tab"> elements (no li wrapper)
      cy.get('[role="tablist"] .tab:nth-child(2)').click()
      cy.get('[role="tablist"] .tab:nth-child(2)').should('have.class', 'tab-active')
    })

    it('shows a tab content on click', () => {
      cy.get('[role="tablist"] .tab:nth-child(2)').click()

      cy.get('.tabs-content [role="tabpanel"]:nth-child(2)').should(
        'not.have.class',
        'hidden'
      )
      cy.get('.tabs-content [role="tabpanel"]:nth-child(2)').should(
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
      // In DaisyUI, data-content-loaded is set on the tab element itself (not li)
      cy.get('[role="tablist"] .tab:nth-child(3)').should(
        'not.have.attr',
        'data-content-loaded'
      )

      cy.get('[role="tablist"] .tab:nth-child(3)').click()
      cy.get('[role="tablist"] .tab:nth-child(3)').should('have.attr', 'data-content-loaded')
    })
  })
})
