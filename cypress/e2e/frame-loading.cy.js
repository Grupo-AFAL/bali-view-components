// The Bali::Frame swap is pure CSS on [busy] (`:has(> turbo-frame[busy])`).
// It has to be MEASURED in a real browser: a broken @import or a badly written
// selector would pass the component's render tests (which only look at the server
// markup, without CSS or Turbo). Here [busy] is toggled the way Turbo does on
// every load and the COMPUTED visibility is asserted.
describe('Bali::Frame: loading swap with [busy]', () => {
  const frame = 'turbo-frame#frame-preview-default'

  it('without [busy]: the frame shows, the placeholder is hidden', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).should('be.visible')
    cy.get('.frame-loading').should('not.be.visible')
  })

  it('with [busy]: the frame is hidden and the placeholder appears', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).invoke('attr', 'busy', '')
    cy.get('.frame-loading').should('be.visible')
    cy.get(frame).should('not.be.visible')
  })

  it('removing [busy] (load finished) brings the frame back and hides the placeholder', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).invoke('attr', 'busy', '')
    cy.get('.frame-loading').should('be.visible')
    cy.get(frame).invoke('removeAttr', 'busy')
    cy.get(frame).should('be.visible')
    cy.get('.frame-loading').should('not.be.visible')
  })
})
