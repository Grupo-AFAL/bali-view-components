// Bali::BpmnEditor: an activity's own size (`width`/`height`), from the corner
// handle or the properties panel, and «Auto» to give the default back.

const PREVIEW = '/bali/bpmn_editor/resized_activities'
const PANEL = '[data-testid="bpmn-properties"]'
const nodeNamed = (name) => cy.contains('[data-testid="bpmn-node"]', name)
// The size the shape is drawn at, in document units (the canvas zoom aside).
const drawnSize = (name) => nodeNamed(name).find('svg.bpmn-node-shape').then(($svg) => [Number($svg.attr('width')), Number($svg.attr('height'))])
const undoButton = () => cy.get('button[aria-label="Deshacer"]')
const redoButton = () => cy.get('button[aria-label="Rehacer"]')
// The node as the latest save sent it (saves are debounced, so retried).
const lastSaved = (name, check) => cy.get('@save.all').should((calls) => {
  expect(calls.length, 'a save').to.be.greaterThan(0)
  check(calls[calls.length - 1].request.body.diagram.nodes.find((n) => n.name === name))
})

// xyflow's resizer is a d3-drag: it starts on the handle's mousedown, reads
// the event's `view`, and follows mousemove/mouseup on that window — which
// events on the body reach; triggered on cy.window() they never did.
const dragHandle = (dx, dy) => {
  cy.get('.bpmn-node-resize').then(($handle) => {
    const view = $handle[0].ownerDocument.defaultView
    const box = $handle[0].getBoundingClientRect()
    const at = (x, y) => ({ eventConstructor: 'MouseEvent', view, button: 0, buttons: 1, clientX: box.left + box.width / 2 + x, clientY: box.top + box.height / 2 + y })
    cy.wrap($handle).trigger('mousedown', at(0, 0))
    cy.get('body').trigger('mousemove', at(dx / 2, dy / 2))
    cy.get('body').trigger('mousemove', at(dx, dy))
    cy.get('body').trigger('mouseup', at(dx, dy))
  })
}

describe('BPMN editor activity size', () => {
  it('draws the stored sizes read-only, with no handle', () => {
    cy.visit(`${PREVIEW}?editable=false`)
    drawnSize('Validar la factura contra').should('deep.equal', [230, 100])
    drawnSize('Programar transferencia').should('deep.equal', [210, 64])
    nodeNamed('Validar la factura contra').click()
    cy.get('.bpmn-node-resize').should('not.exist')
  })

  describe('editable', () => {
    beforeEach(() => {
      cy.intercept('PUT', /\/diagram(\?.*)?$/).as('save')
      cy.visit(PREVIEW)
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    })

    it('offers the handle on a selected activity only, never on an event or a gateway', () => {
      cy.get('.bpmn-node-resize').should('not.exist')
      nodeNamed('Factura recibida').click()
      cy.get('.bpmn-node-resize').should('not.exist')
      cy.get(PANEL).find('[data-testid="bpmn-node-size"]').should('not.exist')
      nodeNamed('Registrar pago').click()
      cy.get('.bpmn-node-resize').should('have.length', 1)
      cy.get(PANEL).find('[data-testid="bpmn-node-size"] button').should('have.attr', 'aria-pressed', 'true').and('be.disabled')
    })

    it('resizes by the corner in one undo step, and «Auto» gives the default back', () => {
      nodeNamed('Registrar pago').click()
      dragHandle(120, 60)
      drawnSize('Registrar pago').should(([w, h]) => {
        expect(w, 'wider').to.be.greaterThan(150)
        expect(h, 'taller').to.be.greaterThan(64)
      }).then(([w, h]) => {
        cy.get(PANEL).find('input[aria-label="Ancho"]').should('have.value', String(w))
        cy.get(PANEL).find('input[aria-label="Alto"]').should('have.value', String(h))
      })
      lastSaved('Registrar pago', (saved) => expect(saved.width).to.be.greaterThan(150))

      undoButton().click()
      drawnSize('Registrar pago').should('deep.equal', [150, 64])
      redoButton().click()
      drawnSize('Registrar pago').its(0).should('be.greaterThan', 150)

      cy.get(PANEL).find('[data-testid="bpmn-node-size"] button').should('have.attr', 'aria-pressed', 'false').click()
      drawnSize('Registrar pago').should('deep.equal', [150, 64])
      lastSaved('Registrar pago', (saved) => {
        expect(saved).to.have.property('width', null)
        expect(saved).to.have.property('height', null)
      })
      undoButton().click()
      drawnSize('Registrar pago').its(0).should('be.greaterThan', 150)
    })

    it('takes a typed size on Enter, clamped to the limits', () => {
      nodeNamed('Programar transferencia').click()
      cy.get(PANEL).find('input[aria-label="Ancho"]').clear().type('5000{enter}')
      drawnSize('Programar transferencia').should('deep.equal', [800, 64])
      cy.get(PANEL).find('input[aria-label="Ancho"]').should('have.value', '800')
      cy.get(PANEL).find('input[aria-label="Alto"]').clear().type('120{enter}')
      drawnSize('Programar transferencia').should('deep.equal', [800, 120])
    })
  })
})

// The playground's fields carry a `maxlength:` (the owner's note, 280; the
// description, `fields: { documentation: { maxlength: 1000 } }`).
describe('BPMN editor field limits', () => {
  it('stops typing at the maxlength of a field and of the description', () => {
    cy.visit('/bali/bpmn_editor/playground')
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.contains('[data-testid="bpmn-node"]', 'Registrar pago').click()
    cy.get(PANEL).contains('label', 'Nota del responsable').find('textarea')
      .should('have.attr', 'maxlength', '280')
      .type('x'.repeat(300), { delay: 0 })
      .should(($el) => expect($el.val()).to.have.length(280))
    cy.get(PANEL).contains('label', 'Descripción').find('textarea').should('have.attr', 'maxlength', '1000')
  })
})
