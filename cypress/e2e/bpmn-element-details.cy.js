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

  it('lists the selected element’s pending issues in its properties panel', () => {
    cy.visit(EDITABLE)
    cy.get('[data-testid="bpmn-node"][title="Fin"]').click()
    cy.get('[data-testid="bpmn-properties"] [data-testid="bpmn-element-issues"] li').should('have.length', 1)
      .and('have.attr', 'data-rule', 'R07').and('contain', 'Indica cómo termina el flujo')
    // An element nothing is held against shows no section.
    cy.get('[data-testid="bpmn-node"][title="Validar factura"]').click()
    cy.get('[data-testid="bpmn-properties"]').should('contain', 'Nombre')
    cy.get('[data-testid="bpmn-element-issues"]').should('not.exist')
  })
})
