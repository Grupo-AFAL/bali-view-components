// Bali::BpmnEditor (#1694): the name of an event, a gateway or a data element
// placed by hand (`label_position`). Where each position puts the name is
// model/labels.js's, tested in test/javascript/bpmn_editor/labels.test.js.

const PREVIEW = '/bali/bpmn_editor/placed_names'
const DIAGRAM = /\/diagram(\?.*)?$/
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
// Where the name is drawn, measured against the shape.
const nameSide = (name) => nodeNamed(name).then(($node) => {
  const label = $node.find('[data-testid="bpmn-node-name"]')[0].getBoundingClientRect()
  const shape = $node.find('svg.bpmn-node-shape')[0].getBoundingClientRect()
  return label.bottom <= shape.top + 1 ? 'above' : label.top >= shape.bottom - 1 ? 'below' : 'beside'
})
const lastSaved = (name, check) => cy.get('@save.all').should((calls) => {
  expect(calls.length, 'a save').to.be.greaterThan(0)
  check(calls[calls.length - 1].request.body.diagram.nodes.find((n) => n.name === name))
})

describe('BPMN editor name position', () => {
  it('draws the stored positions read-only, and the rest where the editor puts them', () => {
    cy.visit(`${PREVIEW}?editable=false`)
    nameSide('Factura recibida').should('eq', 'above')
    nameSide('¿La factura es válida?').should('eq', 'below')
    nameSide('Pago realizado').should('eq', 'below')
  })

  it('moves a name above from the properties panel, saves it, and «Auto» sends null', () => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(PREVIEW)
    nodeNamed('Pago realizado').click()
    cy.get('[data-testid="bpmn-label-position"] [data-choice="auto"]').should('have.attr', 'aria-pressed', 'true')
    cy.get('[data-testid="bpmn-label-position"] [data-choice="top"]').click().should('have.attr', 'aria-pressed', 'true')
    nameSide('Pago realizado').should('eq', 'above')
    lastSaved('Pago realizado', (node) => expect(node.label_position).to.eq('top'))
    cy.get('.react-flow__edge').should('have.length', 8)

    cy.get('[data-testid="bpmn-label-position"] [data-choice="auto"]').click()
    nameSide('Pago realizado').should('eq', 'below')
    lastSaved('Pago realizado', (node) => expect(node.label_position).to.eq(null))
  })

  it('offers no position for an activity, which holds its own name', () => {
    cy.visit(PREVIEW)
    nodeNamed('Validar factura').click()
    cy.get('[data-testid="bpmn-properties"]').should('contain', 'Nombre')
    cy.get('[data-testid="bpmn-label-position"]').should('not.exist')
  })
})
