// Bali::BpmnEditor `full_page:` («Exit» waits for the save, and a failed one
// offers «Retry» or «Exit without saving») and the «Expand» of
// `chrome: :minimal`.

const PAGE = '/bali/bpmn_editor/full_page'
const CLOSE = '/lookbook/preview/bali/bpmn_editor/default'
const SAVE = { method: 'PUT', url: /\/diagram(\?.*)?$/ }

// An edit through a host event: one more revision to save.
const edit = (label) => {
  cy.contains('.react-flow__node-bpmn', 'Validar factura').invoke('attr', 'data-id').then((nodeId) => {
    cy.get('[data-controller="bpmn-editor"]').then(($host) => {
      $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reference-created', {
        bubbles: true, detail: { client_node_id: nodeId, reference: { id: '6', label } }
      }))
    })
  })
  cy.contains('.react-flow__node-bpmn', label).should('exist')
}

const visitPage = (query = '') => {
  cy.visit(`${PAGE}${query}`, { onBeforeLoad (win) { cy.stub(win, 'confirm').as('confirm').returns(true) } })
  cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
}

describe('BPMN editor full page', () => {
  it('draws the header with the save status in it', () => {
    visitPage()
    cy.get('header [data-bpmn-page-exit]').should('have.attr', 'href', CLOSE)
    cy.get('header h1').should('contain', 'Pago a proveedores')
    cy.get('header [data-bpmn-page-save-status] [data-testid="bpmn-save-status"]').should('contain', 'Borrador guardado')
    cy.get('[data-testid="bpmn-save-status"]').should('have.length', 1)
    cy.get('[data-testid="bpmn-page-host-notice"]').should('be.visible')
    cy.window().then((win) => {
      const page = win.document.querySelector('.bali-bpmn-page').getBoundingClientRect()
      expect(Math.round(page.bottom)).to.equal(win.innerHeight)
    })
  })

  it('«Exit» waits for the pending save, then leaves', () => {
    let answeredAt = null
    cy.intercept(SAVE, (request) => {
      request.on('after:response', () => { answeredAt = Date.now() })
      request.reply({ delay: 1500, body: { ...request.body.diagram, version: request.body.version + 1 } })
    }).as('save')
    visitPage()
    // A Turbo visit, not the prefetch a hover over the link makes.
    cy.document().then((doc) => { doc.addEventListener('turbo:visit', () => { doc.defaultView.visitedAt ??= Date.now() }) })
    edit('Slow procedure')
    cy.get('[data-bpmn-page-exit]').click()
    cy.get('[data-bpmn-page-exit]').should('have.attr', 'aria-busy', 'true')
    cy.wait('@save').its('request.body.diagram.nodes').should((nodes) => {
      expect(nodes.map((n) => n.name)).to.include('Slow procedure')
    })
    cy.location('pathname').should('eq', CLOSE)
    cy.window().its('visitedAt').should((visitedAt) => { expect(visitedAt).to.be.at.least(answeredAt) })
    cy.get('@confirm').should('not.have.been.called')
  })

  // Without autosave the Turbo visit guard asks before leaving with a change;
  // «Exit» saved it already and must not ask again.
  it('«Exit» without autosave saves what is left and does not ask to confirm', () => {
    cy.intercept(SAVE).as('save')
    visitPage('?autosave=false')
    edit('Unsaved procedure')
    cy.get('[data-testid="bpmn-save-status"]').should('contain', 'Cambios sin guardar')
    cy.get('[data-bpmn-page-exit]').click()
    cy.wait('@save')
    cy.location('pathname').should('eq', CLOSE)
    cy.get('@confirm').should('not.have.been.called')
  })

  it('a failed save keeps the person on the page, and «Retry» saves and leaves', () => {
    let refuse = true
    cy.intercept(SAVE, (request) => {
      if (refuse) request.reply({ statusCode: 422, body: { errors: ['The app refused the draft.'] } })
      else request.reply({ body: { ...request.body.diagram, version: request.body.version + 1 } })
    }).as('save')
    visitPage()
    edit('Refused procedure')
    cy.get('[data-bpmn-page-exit]').click()
    cy.wait('@save')
    cy.get('[data-testid="bpmn-exit-failed"]').should('be.visible').and('contain', 'No se pudieron guardar los cambios')
    cy.location('pathname').should('not.eq', CLOSE)
    cy.then(() => { refuse = false })
    cy.get('[data-testid="bpmn-exit-retry"]').click()
    cy.wait('@save').its('response.statusCode').should('eq', 200)
    cy.location('pathname').should('eq', CLOSE)
  })

  it('«Exit without saving» leaves at once and sends nothing more', () => {
    cy.intercept(SAVE, { statusCode: 422, body: { errors: ['The app refused the draft.'] } }).as('save')
    visitPage()
    edit('Dropped procedure')
    cy.get('[data-bpmn-page-exit]').click()
    cy.wait('@save')
    cy.get('[data-testid="bpmn-exit-failed"]').should('be.visible')
    cy.get('[data-testid="bpmn-exit-discard"]').click()
    cy.location('pathname').should('eq', CLOSE)
    // Neither the Turbo visit guard nor the unmount sends the dropped change.
    cy.wait(500)
    cy.get('@save.all').should('have.length', 1)
    cy.get('@confirm').should('not.have.been.called')
  })

  it('closing the dialog stays on the page with the change still unsaved', () => {
    cy.intercept(SAVE, { statusCode: 422, body: { errors: ['The app refused the draft.'] } }).as('save')
    visitPage()
    edit('Kept procedure')
    cy.get('[data-bpmn-page-exit]').click()
    cy.get('[data-testid="bpmn-exit-failed"]').should('be.visible').type('{esc}')
    cy.get('[data-testid="bpmn-exit-failed"]').should('not.exist')
    cy.location('pathname').should('not.eq', CLOSE)
    cy.get('[data-testid="bpmn-save-status"]').should('contain', 'No se pudo guardar')
  })
})

// Headless Chrome refuses a full screen the test asks for (it is no user
// gesture), and the spec runs inside Cypress's frame: both are stubbed.
const fakeFullscreen = (win, { enabled = true } = {}) => {
  let current = null
  Object.defineProperty(win.document, 'fullscreenEnabled', { configurable: true, get: () => enabled })
  Object.defineProperty(win.document, 'fullscreenElement', { configurable: true, get: () => current })
  win.requested = []
  win.Element.prototype.requestFullscreen = function () {
    win.requested.push(this)
    current = this
    win.document.dispatchEvent(new win.Event('fullscreenchange'))
    return Promise.resolve()
  }
  win.document.exitFullscreen = () => {
    current = null
    win.document.dispatchEvent(new win.Event('fullscreenchange'))
    return Promise.resolve()
  }
}

describe('BPMN editor minimal chrome «Expand»', () => {
  const MINIMAL = '/bali/bpmn_editor/compare_flows?chrome=minimal'

  it('puts the editor in full screen and back', () => {
    cy.visit(MINIMAL, { onBeforeLoad: (win) => fakeFullscreen(win) })
    cy.get('.bpmn-editor.is-minimal').should('exist')
    cy.get('[data-testid="bpmn-expand"]').should('have.attr', 'aria-label', 'Ampliar').click()
    cy.window().its('requested').should('have.length', 1)
    cy.window().then((win) => { expect(win.requested[0]).to.equal(win.document.querySelector('.bpmn-editor')) })
    cy.get('.bpmn-editor').should('have.class', 'h-screen').and('have.class', 'is-minimal')
    cy.get('[data-testid="bpmn-expand"]').should('have.attr', 'aria-label', 'Salir de pantalla completa').click()
    cy.get('.bpmn-editor').should('not.have.class', 'h-screen')
    cy.get('[data-testid="bpmn-expand"]').should('have.attr', 'aria-label', 'Ampliar')
  })

  it('is not offered where the browser allows no full screen', () => {
    cy.visit(MINIMAL, { onBeforeLoad: (win) => fakeFullscreen(win, { enabled: false }) })
    cy.get('.bpmn-editor.is-minimal [data-testid="bpmn-node"]').should('exist')
    cy.get('[data-testid="bpmn-expand"]').should('not.exist')
  })
})
