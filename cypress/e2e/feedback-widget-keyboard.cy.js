// The panel is a Drawer whose only content is Opina's frame, and the Drawer's Tab trap left the
// frame out of what Tab can land on: with the ✕ as both ends of the trap, Tab and Shift+Tab
// from it came back to it, and Opina's form could not be reached from the keyboard.
describe('FeedbackWidget panel from the keyboard', () => {
  // The dummy app lives above the Lookbook preview path `baseUrl` points at.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const close = '#feedback-widget .drawer-header button'
  const expectFocusOnFrame = label => cy.document().should((doc) => {
    expect(doc.activeElement, label).to.equal(doc.querySelector('#feedback-widget iframe'))
  })

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/feedback-widget-demo`)
    cy.get('[data-action="feedback-widget#open"]').click()
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
    cy.get('#feedback-widget iframe').its('0.contentDocument.body').find('#go-deeper').should('exist')
  })

  it('reaches the frame with Tab from the ✕', () => {
    cy.get(close).focus()
    cy.press(Cypress.Keyboard.Keys.TAB)
    expectFocusOnFrame('Tab from the ✕')
  })

  // `cy.press` takes no modifiers; the wrap backwards is the trap's own handler.
  it('reaches the frame with Shift+Tab from the ✕', () => {
    cy.get(close).focus()
    cy.focused().trigger('keydown', { key: 'Tab', shiftKey: true })
    expectFocusOnFrame('Shift+Tab from the ✕')
  })
})
