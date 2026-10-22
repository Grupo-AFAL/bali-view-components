// Bali::BpmnEditor: what the save decides on is the latest committed state,
// not the last one React painted, and a server document without coordinates
// is laid out as the component's `layout:` / `page:` say.

const EDITABLE = '/bali/bpmn_editor/playground'
const DIAGRAM = /\/diagram(\?.*)?$/

const positions = () => Cypress.$('.react-flow__node-bpmn').toArray()
  .map((el) => [el.getAttribute('data-id'), el.style.transform]).sort()

describe('BPMN editor saving', () => {
  // A drawer's answer (a Turbo Stream) lands while the PUT is answered: its
  // update is not painted yet when the 200 is handled. That 200 must not
  // replace the document carrying it.
  it('keeps an edit committed while the save is answered, and saves it next', () => {
    cy.visit(`${EDITABLE}?autosave=false`, {
      onBeforeLoad (win) {
        const nativeFetch = win.fetch.bind(win)
        win.puts = []
        win.fetch = (url, options = {}) => {
          if (options.method !== 'PUT') return nativeFetch(url, options)
          const { diagram, version } = JSON.parse(options.body)
          // Answered by the test; its JSON resolves in microtasks, ahead of
          // React's render of an update made in the same task.
          const response = {
            ok: true,
            status: 200,
            redirected: false,
            headers: new win.Headers({ 'Content-Type': 'application/json' }),
            json: () => Promise.resolve({ ...diagram, version: (version || 0) + 1 })
          }
          return new Promise((resolve) => { win.puts.push({ diagram, answer: () => resolve(response) }) })
        }
      }
    })
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.contains('.react-flow__node-bpmn', 'Registrar pago').invoke('attr', 'data-id').as('nodeId')
    cy.contains('.react-flow__node-bpmn', 'Validar factura').invoke('attr', 'data-id').then((first) => {
      cy.get('[data-controller="bpmn-editor"]').then(($host) => {
        $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reference-created', {
          bubbles: true, detail: { client_node_id: first, reference: { id: '6', label: 'First procedure' } }
        }))
      })
    })
    cy.contains('.react-flow__node-bpmn', 'First procedure').should('exist')
    cy.contains('button', 'Guardar borrador').click()
    cy.window().its('puts').should('have.length', 1)
    cy.get('@nodeId').then((nodeId) => {
      cy.window().then((win) => {
        const host = win.document.querySelector('[data-controller="bpmn-editor"]')
        host.dispatchEvent(new win.CustomEvent('bali-bpmn:reference-created', {
          bubbles: true, detail: { client_node_id: nodeId, reference: { id: '7', label: 'Linked procedure' } }
        }))
        win.puts[0].answer()
      })
    })
    cy.contains('.react-flow__node-bpmn', 'Linked procedure').should('exist')
    cy.get('[data-testid="bpmn-save-status"]').should('not.contain', 'Borrador guardado')
    cy.contains('button', 'Guardar borrador').click()
    cy.window().its('puts').should('have.length', 2)
    cy.window().then((win) => {
      expect(win.puts[1].diagram.nodes.map((n) => n.name)).to.include('Linked procedure')
    })
  })

  // A 'reload' answered with a document without coordinates: laid out as on
  // load and as «Tidy up» does, with the component's compact layout.
  it('lays out a reloaded document without coordinates with the component layout', () => {
    cy.intercept('GET', DIAGRAM, (request) => {
      request.continue((response) => {
        response.body.nodes = response.body.nodes.map(({ x, y, ...node }) => node)
      })
    }).as('fetch')
    cy.visit(`${EDITABLE}?layout=compact`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.get('[data-controller="bpmn-editor"]').then(($host) => {
      $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reload', { bubbles: true }))
    })
    cy.wait('@fetch')
    cy.wait(500)
    cy.then(() => {
      const reloaded = positions()
      cy.get('[data-testid="bpmn-auto-layout"]').click()
      cy.wait(500)
      cy.then(() => expect(positions()).to.deep.equal(reloaded))
    })
  })
})
