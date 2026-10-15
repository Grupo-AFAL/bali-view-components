// Bali::BpmnEditor (#1489): the island through the complete host circuit
// (loader, metas, entry, controller) and the main editing flow against the
// dummy's reference endpoints (Admin::ProcessFlows::*). The editable preview
// edits the seeded flow, so each test that writes resets it first through the
// diagram endpoint itself.

const EDITABLE = '/bali/bpmn_editor/editable'
// The previews live under the baseUrl; the dummy's endpoints at the root.
const root = () => Cypress.config('baseUrl').replace(/\/lookbook\/preview\/?$/, '')

const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)

// Puts the seeded flow back to the sample every test starts from — the one
// the read-only `default` preview draws — through the save contract itself.
const resetFlow = () => {
  cy.request('/bali/bpmn_editor/default').then(({ body }) => {
    const html = new DOMParser().parseFromString(body, 'text/html')
    const sample = JSON.parse(html.querySelector('[data-bpmn-editor-data-value]').dataset.bpmnEditorDataValue)
    cy.request(EDITABLE).then((page) => {
      const id = page.body.match(/bpmn_process_flow_(\d+)/)[1]
      cy.request(`${root()}/admin/process_flows/${id}/diagram.json`).then(({ body: current }) => {
        cy.request('PUT', `${root()}/admin/process_flows/${id}/diagram`, { diagram: sample, version: current.version })
      })
    })
  })
}

describe('BPMN editor island', () => {
  it('mounts read-only from the default preview, with lanes, nodes and connections', () => {
    cy.visit('/bali/bpmn_editor/default')
    cy.get('[data-controller="bpmn-editor"] .bpmn-editor').should('be.visible')
    cy.get('[data-testid="bpmn-lane"]').should('have.length', 3)
    cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    cy.get('.react-flow__edge').should('have.length', 8)
    cy.get('[data-testid="bpmn-save-status"]').should('not.exist')
    cy.get('.bali-bpmn-editor-skeleton').should('not.exist')
  })

  describe('editing', () => {
    beforeEach(() => {
      resetFlow()
      cy.intercept('PUT', '**/diagram').as('save')
      cy.visit(EDITABLE)
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    })

    it('places an element from the palette and autosaves the whole document', () => {
      cy.get('[data-palette-key="task"]').click()
      // An empty spot of the first lane, in the pane's own coordinates: the
      // lane body lets the click through to the pane, which places the element.
      cy.get('[data-testid="bpmn-lane"]').first().then(($lane) => {
        const lane = $lane[0].getBoundingClientRect()
        const pane = $lane[0].ownerDocument.querySelector('.react-flow__pane').getBoundingClientRect()
        cy.get('.react-flow__pane').click(lane.left - pane.left + lane.width * 0.7, lane.top - pane.top + lane.height / 2)
      })
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.wait('@save').then(({ request, response }) => {
        expect(request.body.diagram.nodes).to.have.length(10)
        expect(request.body).to.have.property('version')
        expect(response.statusCode).to.eq(200)
      })
      cy.get('[data-testid="bpmn-save-status"]').should('contain', 'Borrador guardado')
    })

    it('blocks a second outgoing connection from an activity and says why', () => {
      nodeNamed('Registrar pago').click()
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick="task"]').click()
      cy.get('[data-testid="bpmn-notice"]').should('contain', 'regla de entradas y salidas')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    })

    it('undoes and redoes with the keyboard', () => {
      nodeNamed('¿La factura es válida?').click()
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick="end_event"]').click()
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.get('body').type('{ctrl}z')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
      cy.get('body').type('{ctrl}y')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
    })

    it('does not finalize with errors: the pending panel opens instead', () => {
      cy.intercept('POST', '**/finalization').as('finalize')
      cy.get('[data-testid="bpmn-pending-button"]').should('contain', 'pendientes')
      cy.get('[data-testid="bpmn-finalize"]').click()
      cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible').find('[data-rule="R07"]').should('exist')
      cy.wait(300)
      cy.get('@finalize.all').should('have.length', 0)
      cy.get('[data-testid="bpmn-pending-panel"] [data-rule="R07"]').click()
      cy.get('[data-testid="bpmn-pending-panel"]').should('not.exist')
      cy.get('.react-flow__node-bpmn.selected').should('contain', 'Fin')
    })

    it('marks an external lane grey and its activities white', () => {
      cy.get('[data-testid="bpmn-lane"].is-external').should('have.length', 1)
      // Same shape, different fill: the external activity is drawn on the
      // page colour, the internal one on the tinted activity colour.
      nodeNamed('Emitir factura').find('.bpmn-node-shape rect').first().then(($external) => {
        nodeNamed('Validar factura').find('.bpmn-node-shape rect').first().should(($internal) => {
          expect($external.css('fill')).not.to.eq($internal.css('fill'))
        })
      })
      cy.get('[data-testid="bpmn-legend"]').should('contain', 'participante externo')
    })
  })
})
