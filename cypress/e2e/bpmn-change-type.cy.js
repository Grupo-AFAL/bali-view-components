// Bali::BpmnEditor (#1694): a gateway or an event changes type from its
// properties panel, where it stands — replacing it used to mean deleting it,
// and its connections with it.

const EDITABLE = '/bali/bpmn_editor/playground'
const DIAGRAM = /\/diagram(\?.*)?$/
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
const lastSaved = (check) => cy.get('@save.all').should((calls) => {
  expect(calls.length, 'a save').to.be.greaterThan(0)
  check(calls[calls.length - 1].request.body.diagram)
})

describe('BPMN editor: changing an element’s type', () => {
  beforeEach(() => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(`${EDITABLE}?palette=full`)
  })

  it('turns the decision into an inclusive gateway, keeping its two ways out and their labels', () => {
    nodeNamed('¿La factura es válida?').click()
    cy.get('[data-testid="bpmn-node-type"]').should('have.value', 'exclusive_gateway').select('inclusive_gateway')
    cy.get('[data-node-type="inclusive_gateway"]').should('have.attr', 'title', '¿La factura es válida?')
    cy.get('.react-flow__edge').should('have.length', 8)
    lastSaved((diagram) => {
      const gateway = diagram.nodes.find((n) => n.name === '¿La factura es válida?')
      expect(gateway.type).to.eq('inclusive_gateway')
      const out = diagram.edges.filter((e) => e.source === gateway.id)
      expect(out.map((e) => e.label).sort()).to.deep.eq(['No', 'Sí'])
      expect(diagram.edges.filter((e) => e.target === gateway.id)).to.have.length(1)
    })
    // One undo step puts the decision back.
    cy.get('button[aria-label="Deshacer"]').click()
    cy.get('[data-node-type="exclusive_gateway"]').should('have.attr', 'title', '¿La factura es válida?')
  })

  it('offers an event the events of its own group, and nothing to an activity', () => {
    nodeNamed('Factura recibida').click()
    cy.get('[data-testid="bpmn-node-type"] option').then(($options) => {
      const keys = [...$options].map((o) => o.value)
      expect(keys).to.include.members(['start_event', 'timer_start_event', 'message_start_event'])
      expect(keys).not.to.include('end_event')
    })
    cy.get('[data-testid="bpmn-node-type"]').select('timer_start_event')
    lastSaved((diagram) => {
      const start = diagram.nodes.find((n) => n.name === 'Factura recibida')
      expect(start.event_definition).to.deep.eq({ kind: 'timer' })
      expect(diagram.edges.some((e) => e.source === start.id)).to.eq(true)
    })
    // The start event's quick menu lies over the activity next to it.
    cy.get('[data-testid="bpmn-properties"] button[aria-label="Cerrar"]').click()
    nodeNamed('Validar factura').click()
    cy.get('[data-testid="bpmn-properties"]').should('contain', 'Nombre')
    cy.get('[data-testid="bpmn-node-type"]').should('not.exist')
  })
})
