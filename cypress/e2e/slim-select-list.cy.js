// The list SlimSelect opens, as slim_select.css draws it. Bali does not load SlimSelect's own
// stylesheet, so whatever SlimSelect 4 renders that the stylesheet used to hide or lay out
// shows up unstyled — these pin the two pieces that did.
describe('SlimSelect list', () => {
  // 4.x opens the list as a modal below 768px unless told otherwise, and Bali has no rules
  // for `.ss-modal-*`: measured at 375px, no backdrop, a list narrower than the trigger and its
  // options unpainted under the search row — which still pass `be.visible`, so the overlay and
  // the geometry are what this checks.
  it('opens as a dropdown under the trigger on a phone', () => {
    cy.viewport(375, 720)
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').click()

    cy.get('.ss-content.ss-open .ss-option').first().should('be.visible')
    cy.document().then(doc => {
      expect(doc.querySelector('.ss-modal-overlay'), 'SlimSelect modal overlay').to.equal(null)

      const trigger = doc.querySelector('.ss-main').getBoundingClientRect()
      const list = doc.querySelector('.ss-content.ss-open').getBoundingClientRect()
      expect(list.top, 'list top vs trigger bottom').to.be.within(trigger.bottom - 1, trigger.bottom + 12)
      expect(list.width, 'list width vs trigger width').to.be.closeTo(trigger.width, 1)
    })
  })

  // The list is portaled to <body>, so it is found through the trigger's `aria-controls`; a
  // lookup by class picks the first list on the page, which on a form with two densities
  // belongs to the other select.
  it('gives the compact class to the list of each compact select, and to no other', () => {
    cy.visit('/bali/form/sizes/comparison')

    cy.get('.slim-select .ss-main').should('have.length.at.least', 2)
    cy.get('.slim-select').should(wrappers => {
      const compact = wrappers.toArray().map(wrapper => {
        const listId = wrapper.querySelector('.ss-main').getAttribute('aria-controls')
        const content = wrapper.ownerDocument.getElementById(listId).closest('.ss-content')
        return [wrapper.classList.contains('slim-select-sm'), content.classList.contains('slim-select-sm-content')]
      })
      expect(compact.map(([select]) => select), 'compact selects on the page').to.include(true).and.include(false)
      compact.forEach(([select, list], i) => expect(list, `list ${i} compact like its select`).to.equal(select))
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
