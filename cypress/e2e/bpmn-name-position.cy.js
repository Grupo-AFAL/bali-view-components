// Bali::BpmnEditor (#1694): the name of an event, a gateway or a data element
// placed by hand (`label_position`) and turned to read upwards
// (`label_orientation`). Where each puts the name is model/labels.js's, tested
// in test/javascript/bpmn_editor/labels.test.js.

const PREVIEW = '/bali/bpmn_editor/placed_names'
const DIAGRAM = /\/diagram(\?.*)?$/
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
// Where the name is drawn, measured against the shape.
const nameSide = (name) => nodeNamed(name).then(($node) => {
  const label = $node.find('[data-testid="bpmn-node-name"]')[0].getBoundingClientRect()
  const shape = $node.find('svg.bpmn-node-shape')[0].getBoundingClientRect()
  return label.bottom <= shape.top + 1 ? 'above' : label.top >= shape.bottom - 1 ? 'below' : 'beside'
})
// Whether the name's box stands taller than wide: a turned name's does.
const nameStands = (name) => nodeNamed(name).find('[data-testid="bpmn-node-name"]').then(($label) => {
  const box = $label[0].getBoundingClientRect()
  return box.height > box.width
})
const lastSaved = (name, check) => cy.get('@save.all').should((calls) => {
  expect(calls.length, 'a save').to.be.greaterThan(0)
  check(calls[calls.length - 1].request.body.diagram.nodes.find((n) => n.name === name))
})

describe('BPMN editor name position and direction', () => {
  it('draws the stored positions read-only, and the rest where the editor puts them', () => {
    cy.visit(`${PREVIEW}?editable=false`)
    nameSide('Factura recibida').should('eq', 'above')
    nameSide('¿La factura es válida?').should('eq', 'below')
    nameSide('Pago realizado').should('eq', 'below')
    nameStands('Pago realizado').should('eq', true)
    nameStands('Fin').should('eq', false)
  })

  it('turns a name to read upwards and back, where it is, and «Horizontal» sends null', () => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(PREVIEW)
    nodeNamed('¿La factura es válida?').click()
    cy.get('[data-testid="bpmn-label-orientation"] [data-choice="horizontal"]').should('have.attr', 'aria-pressed', 'true')
    cy.get('[data-testid="bpmn-label-orientation"] [data-choice="vertical"]').click().should('have.attr', 'aria-pressed', 'true')
    nameStands('¿La factura es válida?').should('eq', true)
    nameSide('¿La factura es válida?').should('eq', 'below')
    lastSaved('¿La factura es válida?', (node) => expect([node.label_orientation, node.label_position]).to.deep.eq(['vertical', 'bottom']))

    cy.get('[data-testid="bpmn-label-orientation"] [data-choice="horizontal"]').click()
    nameStands('¿La factura es válida?').should('eq', false)
    lastSaved('¿La factura es válida?', (node) => expect(node.label_orientation).to.eq(null))
  })

  it('moves a name above from the properties panel, saves it, and «Auto» sends null', () => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(PREVIEW)
    nodeNamed('Pago realizado').click()
    cy.get('[data-testid="bpmn-label-position"] [data-choice="default"]').should('have.attr', 'aria-pressed', 'true')
    cy.get('[data-testid="bpmn-label-position"] [data-choice="top"]').click().should('have.attr', 'aria-pressed', 'true')
    nameSide('Pago realizado').should('eq', 'above')
    lastSaved('Pago realizado', (node) => expect(node.label_position).to.eq('top'))
    cy.get('.react-flow__edge').should('have.length', 8)

    cy.get('[data-testid="bpmn-label-position"] [data-choice="default"]').click()
    nameSide('Pago realizado').should('eq', 'below')
    lastSaved('Pago realizado', (node) => expect(node.label_position).to.eq(null))
  })

  it('offers neither for an activity, which holds its own name', () => {
    cy.visit(PREVIEW)
    nodeNamed('Validar factura').click()
    cy.get('[data-testid="bpmn-properties"]').should('contain', 'Nombre')
    cy.get('[data-testid="bpmn-label-position"]').should('not.exist')
    cy.get('[data-testid="bpmn-label-orientation"]').should('not.exist')
  })
})
