// The editor's shortcuts stay off the canvas while a dialog is over it or the
// comparison hides it, and leaving full screen without the button (Esc, the
// browser's own way out) fits the diagram again.

const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
const viewport = () => cy.get('.react-flow__viewport').invoke('attr', 'style')

describe('the editor’s shortcuts', () => {
  beforeEach(() => cy.viewport(1400, 900))

  it('leave the selection alone while the pending issues are open over it', () => {
    cy.visit('/bali/bpmn_editor/playground')
    nodeNamed('Validar factura').click()
    cy.get('[data-testid="bpmn-pending-button"]').click()
    cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible')
    cy.focused().type('{del}{downarrow}')
    cy.focused().type('{esc}')
    nodeNamed('Validar factura').should('exist')
  })

  it('leave the hidden canvas alone while the comparison is open', () => {
    cy.visit('/bali/bpmn_editor/review?editable=true')
    nodeNamed('Validar factura').click()
    cy.get('[data-testid="bpmn-compare-button"]').click()
    cy.get('.bpmn-compare').should('be.visible').click('center')
    cy.get('body').type('{del}')
    cy.get('[data-testid="bpmn-compare-button"]').click()
    nodeNamed('Validar factura').should('exist')
  })
})

describe('leaving full screen without the button', () => {
  it('fits the diagram back into the editor', () => {
    cy.viewport(1400, 900)
    cy.visit('/bali/bpmn_editor/playground', { onBeforeLoad: fakeFullscreen })
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.wait(600)
    viewport().then((before) => {
      cy.contains('button', 'Pantalla completa').click()
      cy.wait(600)
      viewport().should('not.eq', before)
      // What Esc does: the browser leaves full screen and only tells the page.
      cy.window().then((win) => win.leaveFullscreen())
      viewport().should('eq', before)
    })
  })
})

// Headless Chrome refuses a full screen the test asks for (it is no user
// gesture): the API is stubbed, as in bpmn-page.cy.js.
function fakeFullscreen (win) {
  let current = null
  Object.defineProperty(win.document, 'fullscreenElement', { configurable: true, get: () => current })
  const change = (element) => { current = element; win.document.dispatchEvent(new win.Event('fullscreenchange')); return Promise.resolve() }
  win.Element.prototype.requestFullscreen = function () { return change(this) }
  win.document.exitFullscreen = () => change(null)
  win.leaveFullscreen = () => change(null)
}
