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
      // «Programar transferencia» and «Pago realizado» stand on the same row:
      // one line in each stretch between the three shapes, none through them.
      cy.get('[data-testid="bpmn-align-guides"] line').should('have.length', 2).each(($line) => {
        expect($line.attr('data-axis')).to.eq('y')
        const [from, to] = [$line.attr('x1'), $line.attr('x2')].map(Number)
        Cypress.$('.react-flow__node-bpmn').each((_i, node) => {
          const at = new DOMMatrix(getComputedStyle(node).transform)
          const [left, right] = [at.e, at.e + node.offsetWidth]
          const onRow = Math.abs(at.f + node.offsetHeight / 2 - Number($line.attr('y1'))) < node.offsetHeight / 2
          if (onRow) expect(Math.min(to, right) - Math.max(from, left), `over ${node.dataset.id}`).to.be.at.most(0)
        })
      })
      cy.get('body').trigger('mouseup', at(-40))
      cy.get('[data-testid="bpmn-align-guides"]').should('not.exist')
    })
  })
})
