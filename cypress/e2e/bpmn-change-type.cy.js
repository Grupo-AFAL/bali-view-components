// Bali::BpmnEditor (#1694): a task, a gateway or an event changes type from its
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

  it('offers an event the events of its own group', () => {
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
  })

  it('turns a task into another kind of task, and offers a sub-process nothing', () => {
    nodeNamed('Registrar pago').click()
    cy.get('[data-testid="bpmn-node-type"]').should('have.value', 'task').find('option').then(($options) => {
      const keys = [...$options].map((o) => o.value)
      expect(keys).to.include.members(['task', 'user_task', 'service_task', 'manual_task'])
      expect(keys).not.to.include('sub_process')
    })
    cy.get('[data-testid="bpmn-node-type"]').select('manual_task')
    cy.get('[data-node-type="manual_task"]').should('have.attr', 'title', 'Registrar pago')
    lastSaved((diagram) => {
      const task = diagram.nodes.find((n) => n.name === 'Registrar pago')
      expect(task.type).to.eq('manual_task')
      expect(diagram.edges.filter((e) => e.source === task.id || e.target === task.id)).to.have.length(2)
    })
    // A sub-process is tied to an entity of the app: it is no kind of task.
    cy.get('[data-testid="bpmn-properties"] button[aria-label="Cerrar"]').click()
    cy.get('[data-palette-key="sub_process"]').click()
    cy.get('[data-testid="bpmn-lane"]').last().then(($lane) => {
      const lane = $lane[0].getBoundingClientRect()
      const pane = $lane[0].closest('.react-flow').querySelector('.react-flow__pane')
      const box = pane.getBoundingClientRect()
      cy.wrap(pane).click(lane.left - box.left + lane.width * 0.2, lane.top - box.top + lane.height / 2)
    })
    cy.get('[data-testid="bpmn-properties"]').should('contain', 'Nombre')
    cy.get('.react-flow__node-bpmn.selected [data-node-type="sub_process"]').should('exist')
    cy.get('[data-testid="bpmn-node-type"]').should('not.exist')
  })
})
