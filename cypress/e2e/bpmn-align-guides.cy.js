// Bali::BpmnEditor (#1694): alignment guides while an element is dragged.
// When each line shows is model/guides.js's, tested in
// test/javascript/bpmn_editor/guides.test.js; here, that the canvas draws it
// during the drag and takes it away on the drop.

const EDITABLE = '/bali/bpmn_editor/playground'
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
// One event per frame, as a mouse sends them (see bpmn-resize.cy.js).
const nextFrame = () => cy.window().then((win) => new Cypress.Promise((resolve) => win.requestAnimationFrame(() => win.requestAnimationFrame(resolve))))

describe('BPMN editor alignment guides', () => {
  it('draws a line through the row while an element moves along it, and none after the drop', () => {
    cy.visit(EDITABLE)
    cy.get('[data-testid="bpmn-align-guides"]').should('not.exist')
    nodeNamed('Registrar pago').then(($node) => {
      const view = $node[0].ownerDocument.defaultView
      const box = $node[0].getBoundingClientRect()
      const at = (dx) => ({ eventConstructor: 'MouseEvent', view, button: 0, buttons: 1, clientX: box.left + box.width / 2 + dx, clientY: box.top + box.height / 2 })
      cy.wrap($node).trigger('mousedown', at(0))
      nextFrame()
      cy.get('body').trigger('mousemove', at(-20))
      nextFrame()
      cy.get('body').trigger('mousemove', at(-40))
      // «Programar transferencia» and «Pago realizado» stand on the same row.
      cy.get('[data-testid="bpmn-align-guides"] line').should('have.length', 1).and('have.attr', 'data-axis', 'y')
      cy.get('body').trigger('mouseup', at(-40))
      cy.get('[data-testid="bpmn-align-guides"]').should('not.exist')
    })
  })
})
