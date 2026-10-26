// What the host answers outside the save's 200: a save it refuses naming
// elements (`422 { errors, issues }`), and `bali_bpmn_reload` reaching the
// editor as a broadcast rather than as a drawer's response.

const EDITABLE = '/bali/bpmn_editor/playground'
const DIAGRAM = /\/diagram(\?.*)?$/

const placeTask = () => {
  cy.get('[data-palette-key="task"]').click()
  cy.get('[data-testid="bpmn-lane"]').eq(1).then(($lane) => {
    const lane = $lane[0].getBoundingClientRect()
    const pane = $lane[0].closest('.react-flow').querySelector('.react-flow__pane')
    const box = pane.getBoundingClientRect()
    cy.wrap(pane).click(lane.left - box.left + lane.width * 0.7, lane.top - box.top + lane.height / 2)
  })
}

describe('a save the server refuses with issues', () => {
  it('marks the elements it names, opens the pending panel and keeps the change unsaved', () => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(`${EDITABLE}?server=reject_save`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.contains('.react-flow__node-bpmn', 'Emitir factura').find('.bpmn-node-shape text').should('not.exist')
    placeTask()
    cy.wait('@save').its('response.statusCode').should('eq', 422)
    cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible')
      .and('contain', 'Esta actividad no tiene responsable en la app')
    cy.contains('.react-flow__node-bpmn', 'Emitir factura').find('.bpmn-node-shape text').should('have.text', '!')
    cy.get('[data-testid="bpmn-notice"]').should('contain', 'No se pudo guardar el borrador')
    cy.get('[data-testid="bpmn-save-status"]').should('not.contain', 'Borrador guardado')
    cy.screenshot('bpmn-host-answers/save-refused-with-issues')
  })

  it('opens the panel again only when the refusal names other issues', () => {
    // The placed task stays selected and its properties cover the lanes'
    // right side: the next ones go on the left of an empty stretch.
    const placeAnother = (lane) => {
      cy.get('[data-palette-key="task"]').click()
      cy.get('[data-testid="bpmn-lane"]').eq(lane).then(($lane) => {
        const box = $lane[0].getBoundingClientRect()
        const pane = $lane[0].closest('.react-flow').querySelector('.react-flow__pane')
        const origin = pane.getBoundingClientRect()
        cy.wrap(pane).click(box.left - origin.left + box.width * 0.3, box.top - origin.top + box.height / 2)
      })
    }
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit(`${EDITABLE}?server=reject_save`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    placeTask()
    cy.wait('@save').its('response.statusCode').should('eq', 422)
    cy.get('[data-testid="bpmn-pending-panel"]').find('button[aria-label^="Cerrar"]').first().click()
    cy.get('[data-testid="bpmn-pending-panel"]').should('not.exist')

    placeAnother(2)
    cy.wait('@save').then(({ response }) => {
      expect(response.statusCode).to.eq(422)
      const other = response.body.issues.map((issue) => ({ ...issue, message: 'Otra observación del servidor' }))
      cy.intercept('PUT', DIAGRAM, { statusCode: 422, body: { errors: ['Rechazado'], issues: other } }).as('other')
    })
    cy.get('[data-testid="bpmn-notice"]').should('contain', 'No se pudo guardar el borrador')
    cy.get('[data-testid="bpmn-pending-panel"]').should('not.exist')

    placeAnother(0)
    cy.wait('@other')
    cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible').and('contain', 'Otra observación del servidor')
  })
})

describe('bali_bpmn_reload as a broadcast', () => {
  // Someone else's change (an import running in the background) lands on the
  // server; the stream the helper renders reaches the page the way Turbo
  // applies a broadcast: `Turbo.renderStreamMessage`, or a <turbo-stream>
  // connected into the page — no drawer, no fetch of the editor's own.
  const changeOnTheServerAndBroadcast = (deliver) => {
    cy.get('[data-controller="bpmn-editor"]').then(($host) => {
      const editorId = $host.attr('id')
      const flowId = editorId.match(/(\d+)/)[1]
      // cy.request would put a path under the baseUrl's /lookbook/preview.
      const flowUrl = `${$host[0].ownerDocument.location.origin}/admin/process_flows/${flowId}`
      const diagramUrl = `${flowUrl}/diagram`
      cy.request(diagramUrl).its('body').then((doc) => {
        const nodes = doc.nodes.map((n) => (n.name === 'Emitir factura' ? { ...n, name: 'Factura importada' } : n))
        cy.request('PUT', diagramUrl, { diagram: { ...doc, nodes }, version: doc.version })
      })
      cy.request({ method: 'POST', url: `${flowUrl}/host_event`, form: true, body: { event: 'reload', editor_id: editorId }, headers: { Accept: 'text/vnd.turbo-stream.html' } })
        .its('body').then((stream) => {
          expect(stream).to.contain('action="bali_bpmn_event"').and.to.contain('event="reload"')
          cy.window().then((win) => deliver(win, stream))
        })
    })
  }

  beforeEach(() => {
    cy.intercept('GET', DIAGRAM).as('fetch')
    cy.visit(EDITABLE)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
  })

  it('reloads from Turbo.renderStreamMessage', () => {
    changeOnTheServerAndBroadcast((win, stream) => win.Turbo.renderStreamMessage(stream))
    cy.wait('@fetch')
    cy.contains('.react-flow__node-bpmn', 'Factura importada').should('exist')
    cy.get('[data-testid="bpmn-notice"]').should('contain', 'recarg')
  })

  it('reloads from a <turbo-stream> connected into the page', () => {
    changeOnTheServerAndBroadcast((win, stream) => win.document.body.insertAdjacentHTML('beforeend', stream))
    cy.wait('@fetch')
    cy.contains('.react-flow__node-bpmn', 'Factura importada').should('exist')
  })
})
