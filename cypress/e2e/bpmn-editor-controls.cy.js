// Bali::BpmnEditor: the properties panel's controls (button groups, the
// multi-select chips), the image outputs on names an HTML serialiser writes
// as entities XML does not have, and Esc inside a SplitView's detail.

const EDITABLE = '/bali/bpmn_editor/playground'
const PANEL = '[data-testid="bpmn-properties"]'
const undoButton = () => cy.get('button[aria-label="Deshacer"]')

// An element from the palette into the first lane; the new element is selected.
const place = (key) => {
  cy.get(`[data-palette-key="${key}"]`).click()
  cy.get('[data-testid="bpmn-lane"]').first().then(($lane) => {
    const lane = $lane[0].getBoundingClientRect()
    const pane = $lane[0].ownerDocument.querySelector('.react-flow__pane').getBoundingClientRect()
    cy.get('.react-flow__pane').click(lane.left - pane.left + lane.width * 0.7, lane.top - pane.top + lane.height / 2)
  })
}

describe('BPMN editor properties panel', () => {
  beforeEach(() => {
    cy.intercept('PUT', /\/diagram(\?.*)?$/).as('save')
    cy.visit(EDITABLE)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
  })

  // A <label> around a button group forwards a click on its caption to the
  // first button: «Vertical» aligned the selection, an undo step out of nothing.
  it('does not run the first alignment on a click on the alignment caption', () => {
    cy.get('.react-flow__pane').click(5, 5)
    cy.get('body').type('{ctrl}a')
    cy.get(PANEL).contains('Alineación').click()
    cy.get('[data-testid="bpmn-notice"]').should('not.exist')
    undoButton().should('be.disabled')
    cy.get(PANEL).find('[role="group"]').should('have.attr', 'aria-labelledby').then((id) => {
      cy.get(`[id="${id}"]`).should('have.text', 'Alineación')
    })
  })

  it('does not reset the port, and the route, on a click on the port caption', () => {
    cy.get('.react-flow__edge').first().click({ force: true })
    cy.get(PANEL).contains('Puerto de salida').click()
    undoButton().should('be.disabled')
  })

  // WCAG 2.1.1: each chip is a checkbox the keyboard reaches and Space toggles.
  it('reaches and toggles the multi-select chips from the keyboard', () => {
    place('user_task')
    cy.get(PANEL).contains('Sistemas').should('be.visible')
    cy.get(PANEL).contains('label', 'ERP').find('input[type="checkbox"]').as('erp')
      .should('not.be.checked').and('not.have.css', 'display', 'none')
    cy.get(PANEL).contains('label', 'Duración').find('input[type="number"]').focus()
    cy.press(Cypress.Keyboard.Keys.TAB)
    cy.focused().should('have.attr', 'type', 'checkbox').parent('label').should('have.text', 'ERP')
    cy.press(Cypress.Keyboard.Keys.SPACE)
    cy.get('@erp').should('be.checked')
    cy.get('@erp').parent('label').should('have.class', 'badge-primary')
    // The focus is drawn on the chip, where the eye is.
    cy.get('@erp').parent('label').should(($chip) => {
      expect(getComputedStyle($chip[0]).outlineStyle).not.to.eq('none')
    })
    // Saved: a pending change would hold the next visit at beforeunload.
    cy.get('@save.all').should((calls) => {
      expect(calls.some((call) => JSON.stringify(call.request.body).includes('"erp"')), 'a save with the chip').to.eq(true)
    })
    cy.get('[data-testid="bpmn-save-status"]').should('contain', 'Borrador guardado')
  })
})

describe('BPMN editor exports', () => {
  // U+00A0 in a name: HTML serialisation writes it as `&nbsp;`, an entity XML
  // does not define, so the .svg did not parse and the PNG never loaded.
  const NAME = 'Alta de proveedor'
  const svgFile = () => `${Cypress.config('downloadsFolder')}/alta-de-proveedor.svg`

  beforeEach(() => {
    cy.visit(`${EDITABLE}?name=${encodeURIComponent(NAME)}`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
  })

  it('downloads well-formed SVG for a name with a no-break space', () => {
    cy.get('button[aria-label="Descargar SVG"]').click()
    cy.readFile(svgFile()).should((svg) => {
      expect(svg).not.to.contain('&nbsp;')
      const parsed = new DOMParser().parseFromString(svg, 'image/svg+xml')
      expect(parsed.querySelector('parsererror'), 'XML parser error').to.eq(null)
      expect(parsed.documentElement.textContent).to.contain(NAME)
    })
  })

  it('downloads the PNG for that name', () => {
    cy.get('button[aria-label="Descargar imagen"]').click()
    cy.readFile(`${Cypress.config('downloadsFolder')}/alta-de-proveedor.png`, 'binary', { timeout: 10000 })
      .should((png) => expect(png.slice(1, 4)).to.eq('PNG'))
  })

  it('says so when the image cannot be made', () => {
    cy.window().then((win) => {
      win.Image = class {
        get src () { return '' }
        set src (_value) { setTimeout(() => this.onerror(new win.Event('error'))) }
      }
    })
    cy.get('button[aria-label="Descargar imagen"]').click()
    cy.get('[data-testid="bpmn-notice"][role="alert"]').should('contain', 'No se pudo')
  })
})

describe('BPMN editor inside a SplitView detail', () => {
  const FLOW = '[data-testid="bpmn-split-flow"]'
  const split = () => cy.get('.split-view-component--collapsible')

  // A read-only selection is a pointer, not an edit: the Esc that drops it
  // still closes the detail (the 50/50 view's map selects «the one open»).
  it('lets the Esc that drops a read-only selection close the detail too', () => {
    cy.viewport(1440, 1000)
    cy.visit('/bali/bpmn_editor/split_view')
    cy.contains('#split_map_bpmn .react-flow__node-bpmn', 'Alta de proveedor').click()
    split().should('have.attr', 'data-split-state', 'open')
    cy.get(`${FLOW} [data-testid="bpmn-node"]`).should('have.length.greaterThan', 3)
    cy.contains(`${FLOW} .react-flow__node-bpmn`, 'Validar').click()
    cy.get(`${FLOW} .bpmn-node.is-selected`).should('have.length', 1)
    split().then(($split) => {
      $split[0].closes = 0
      $split[0].addEventListener('split-view:close', () => { $split[0].closes++ })
    })
    cy.focused().type('{esc}')
    split().should('have.attr', 'data-split-state', 'closed')
    split().its('0.closes').should('eq', 1)
  })
})

describe('BPMN editor Escape', () => {
  // The editor's listener mounts after a SplitView's, which skips a prevented
  // Esc: letting go of an editable selection must say it took the key.
  it('takes the Esc that drops an editable selection, and not the next one', () => {
    cy.visit(EDITABLE)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.window().then((win) => {
      win.escapes = []
      win.addEventListener('keydown', (event) => { if (event.key === 'Escape') win.escapes.push(event.defaultPrevented) })
    })
    cy.get('.react-flow__node-bpmn').first().click()
    cy.get('.bpmn-node.is-selected').should('have.length', 1)
    cy.focused().type('{esc}')
    cy.get('.bpmn-node.is-selected').should('not.exist')
    cy.focused().type('{esc}')
    cy.window().its('escapes').should('deep.equal', [true, false])
  })
})
