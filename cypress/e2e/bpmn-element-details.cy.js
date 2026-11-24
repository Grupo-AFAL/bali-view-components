// Bali::BpmnEditor (#1694): what the canvas says about one element — its
// connection labels and its pending issues in the properties panel.

const EDITABLE = '/bali/bpmn_editor/playground'

describe('BPMN editor: an element’s details', () => {
  it('draws a connection label on a patch of canvas, without an outline', () => {
    cy.visit(EDITABLE)
    cy.get('.bpmn-edge-label rect').should('have.length.at.least', 2).each(($rect) => {
      expect(getComputedStyle($rect[0]).stroke).to.eq('none')
      expect(getComputedStyle($rect[0]).fill).not.to.eq('none')
    })
  })
})
