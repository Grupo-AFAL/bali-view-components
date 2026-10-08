// The list SlimSelect opens, as slim_select.css draws it. Bali does not load SlimSelect's own
// stylesheet, so whatever SlimSelect 4 renders that the stylesheet used to hide or lay out
// shows up unstyled — these pin the two pieces that did.
describe('SlimSelect list', () => {
  // 4.x opens the list as a modal below 768px unless told otherwise, and Bali has no rules
  // for `.ss-modal-*`: the options did not show at all.
  it('opens as a dropdown under the trigger on a phone', () => {
    cy.viewport(375, 720)
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').click()

    cy.get('.ss-content.ss-open .ss-option').first().should('be.visible')
    cy.document().then(doc => {
      expect(doc.querySelector('.ss-modal-overlay'), 'SlimSelect modal overlay').to.equal(null)

      const trigger = doc.querySelector('.ss-main').getBoundingClientRect()
      const list = doc.querySelector('.ss-content.ss-open').getBoundingClientRect()
      expect(list.top, 'list top vs trigger bottom').to.be.at.least(trigger.bottom - 1)
    })
  })

  // From 3.6 the list carries a live region (`.ss-status`) that reads out "5 results
  // available"; SlimSelect's stylesheet is what keeps it off screen.
  it('keeps the search-result announcement for screen readers only', () => {
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').click()
    cy.get('.ss-content.ss-open .ss-search input').type('Option')

    cy.get('.ss-content.ss-open .ss-status').should($status => {
      const box = $status[0].getBoundingClientRect()
      expect($status.text(), 'announcement').to.not.equal('')
      expect(box.width, 'width').to.be.at.most(1)
      expect(box.height, 'height').to.be.at.most(1)
    })
  })
})
