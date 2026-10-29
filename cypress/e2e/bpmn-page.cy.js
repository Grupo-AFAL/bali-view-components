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

  it('stops above the app layout\'s bottom padding with --bali-bpmn-page-bottom', () => {
    // The dummy's admin layout (application.css sets the property); a path
    // under the baseUrl would land in /lookbook/preview. Tall enough for the
    // page's 36rem minimum below the topbar.
    cy.viewport(1280, 900)
    cy.visit('http://localhost:3001/admin/process_flows/1/edit')
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 3)
    cy.get('main').should(($main) => {
      const main = $main[0]
      const page = main.querySelector('.bali-bpmn-page').getBoundingClientRect()
      const padding = parseFloat(getComputedStyle(main.querySelector('.app-layout-body-container')).paddingBottom)
      expect(main.scrollHeight, 'the layout does not scroll').to.equal(main.clientHeight)
      expect(page.bottom, 'bottom').to.be.closeTo(main.getBoundingClientRect().bottom - padding, 1)
    })
  })

  it('keeps the document\'s own status current when the app gives none', () => {
    visitPage('?mode=document')
    cy.get('header .tag-component').should('have.text', 'Borrador v1')
    cy.intercept({ method: 'GET', url: /\/diagram(\?.*)?$/ }, (req) => {
      req.continue((res) => { res.body = { ...res.body, status_label: 'Finalizado v1' } })
    }).as('fetch')
    cy.get('[data-controller="bpmn-editor"]').then(($host) => { $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reload')) })
    cy.wait('@fetch')
    cy.get('header .tag-component').should('have.length', 1).and('have.text', 'Finalizado v1')
  })

  it('shows the save status in the top bar while the editor is in full screen', () => {
    cy.visit(PAGE, { onBeforeLoad: (win) => fakeFullscreen(win) })
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.contains('button', 'Pantalla completa').click()
    cy.get('.bpmn-chrome [data-testid="bpmn-save-status"]').should('contain', 'Borrador guardado')
    cy.get('[data-testid="bpmn-save-status"]').should('have.length', 1)
    cy.contains('button', 'Salir de pantalla completa').click()
    cy.get('header [data-bpmn-page-save-status] [data-testid="bpmn-save-status"]').should('exist')
    cy.get('.bpmn-chrome [data-testid="bpmn-save-status"]').should('not.exist')
  })

  // The app cancels the visit «Exit» starts: the person stays, and leaving
  // with a later change asks again.
  it('a visit the app cancels gives the leave guard back', () => {
    cy.intercept(SAVE).as('save')
    visitPage('?autosave=false')
    cy.document().then((doc) => { doc.addEventListener('turbo:before-visit', (event) => event.preventDefault(), { once: true }) })
    edit('Saved procedure')
    cy.get('header [data-bpmn-page-exit]').click()
    cy.wait('@save')
    cy.location('pathname').should('include', '/full_page')
    cy.contains('.react-flow__node-bpmn', 'Saved procedure').invoke('attr', 'data-id').then((nodeId) => {
      cy.get('[data-controller="bpmn-editor"]').then(($host) => {
        $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reference-created', {
          bubbles: true, detail: { client_node_id: nodeId, reference: { id: '7', label: 'Later procedure' } }
        }))
      })
    })
    cy.contains('.react-flow__node-bpmn', 'Later procedure').should('exist')
    cy.window().then((win) => { win.Turbo.visit(CLOSE) })
    cy.get('@confirm').should('have.been.calledOnce')
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

  it('a request of the page failing meanwhile does not send the dropped change', () => {
    cy.intercept(SAVE, { statusCode: 422, body: { errors: ['The app refused the draft.'] } }).as('save')
    visitPage()
    // A lazy frame or a prefetch failing as the visit starts: not the visit.
    cy.document().then((doc) => {
      doc.addEventListener('turbo:before-visit', () => {
        doc.dispatchEvent(new CustomEvent('turbo:fetch-request-error', { bubbles: true, detail: {} }))
      }, { once: true })
    })
    edit('Dropped procedure')
    cy.get('[data-bpmn-page-exit]').click()
    cy.wait('@save')
    cy.get('[data-testid="bpmn-exit-discard"]').click()
    cy.location('pathname').should('eq', CLOSE)
    cy.wait(500)
    cy.get('@save.all').should('have.length', 1)
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
