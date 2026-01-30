describe('TabsController', () => {
  context('default tabs', () => {
    beforeEach(() => {
      cy.visit('/bali/tabs/basic')
    })

    it('sets tab active on click', () => {
      // DaisyUI tabs use direct <a role="tab" class="tab"> elements (no li wrapper)
      // Use .first() to target only the component preview, not Lookbook's own tabs
      cy.get('[role="tablist"] .tab:nth-child(2)').first().click()
      cy.get('[role="tablist"] .tab:nth-child(2)').first().should('have.class', 'tab-active')
    })

    it('shows a tab content on click', () => {
      cy.get('[role="tablist"] .tab:nth-child(2)').first().click()

      cy.get('.tabs-content [role="tabpanel"]:nth-child(2)').first().should(
        'not.have.class',
        'hidden'
      )
      cy.get('.tabs-content [role="tabpanel"]:nth-child(2)').first().should(
        'contain',
        'Tab two content'
      )
    })
  })

  context('tabs content on demand', () => {
    beforeEach(() => {
      cy.visit('/bali/tabs/on_demand')
    })

    it('load tab content on click', () => {
      // In DaisyUI, data-content-loaded is set on the tab element itself (not li)
      // Use .first() to target only the component preview, not Lookbook's own tabs
      cy.get('[role="tablist"] .tab:nth-child(3)').first().should(
        'not.have.attr',
        'data-content-loaded'
      )

      cy.get('[role="tablist"] .tab:nth-child(3)').first().click()
      cy.get('[role="tablist"] .tab:nth-child(3)').first().should('have.attr', 'data-content-loaded')
    })
  })
})
