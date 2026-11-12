// `controls:`, `activity_shape: "chevron"` and `lock_orientation: :vertical`
// on the macroprocess map preview: the default chrome is zoom, «Center» and
// full screen — no minimap, no legend —, every activity is a chevron a
// connection enters by its notch, and the lanes, stored horizontal, stand
// side by side.

const MAP = '/bali/bpmn_editor/macroprocess_map'
const SHOTS = 'bpmn-macroprocess'
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
const lanesStand = (orientation) => cy.get('[data-testid="bpmn-lane"]').should(($lanes) => {
  const [first, second] = [...$lanes].map((lane) => lane.getBoundingClientRect())
  const sideBySide = Math.abs(first.top - second.top) < 1 && second.left > first.left
  expect(sideBySide, `lanes ${orientation}`).to.equal(orientation === 'vertical')
})

describe('the macroprocess map', () => {
  beforeEach(() => cy.viewport(1280, 800))

  it('shows only the zoom, «Center» and full screen by default', () => {
    cy.visit(MAP)
    cy.get('[data-testid="bpmn-node"]').should('have.length', 7)
    cy.get('[data-testid="bpmn-zoom-in"]').should('be.visible')
    cy.get('[data-testid="bpmn-zoom-out"]').should('be.visible')
    cy.get('[data-testid="bpmn-center"]').should('be.visible')
    cy.contains('.bpmn-view-toolbar button', 'Pantalla completa').should('be.visible')
    cy.get('.react-flow__minimap').should('not.exist')
    cy.get('.bpmn-legend').should('not.exist')
    lanesStand('vertical')
    cy.screenshot(`${SHOTS}/default-chrome`)
  })

  it('shows the minimap and the legend when the app asks, and hides the zoom when it says so', () => {
    cy.visit(`${MAP}?minimap=true&legend=true&hidden=all`)
    cy.get('[data-testid="bpmn-node"]').should('have.length', 7)
    cy.get('.react-flow__minimap').should('be.visible')
    cy.get('.bpmn-legend').should('exist')
    cy.get('[data-testid="bpmn-zoom-in"], [data-testid="bpmn-center"]').should('not.exist')
    cy.contains('.bpmn-view-toolbar button', 'Pantalla completa').should('not.exist')
  })

  it('draws every activity as a chevron, entered by its notch', () => {
    // Horizontal lanes: the connection into the billing process reaches it from the side.
    cy.visit(`${MAP}?lock_orientation=horizontal`)
    // The outline is the shape's first element; the [+] is a rect after it.
    nodeNamed('Facturación').find('.bpmn-node-shape > g > :first-child').should('match', 'path')
    // That connection ends past the box's left edge, in the notch.
    nodeNamed('Facturación').find('.bpmn-node-shape').then(($shape) => {
      const box = $shape[0].getBoundingClientRect()
      cy.get('.react-flow__edge[data-id="e1"] path.react-flow__edge-path').then(($path) => {
        const length = $path[0].getTotalLength()
        const end = $path[0].getPointAtLength(length)
        const matrix = $path[0].getScreenCTM()
        const x = end.x * matrix.a + matrix.e
        expect(x, 'the arrow tip, on screen').to.be.greaterThan(box.left + 4)
      })
    })
    cy.screenshot(`${SHOTS}/chevrons`)
  })

  it('exports the chevrons as drawn', () => {
    cy.visit(MAP, {
      onBeforeLoad (win) {
        win.document.addEventListener('bali-bpmn:exported', (event) => { win.exported = event.detail })
      }
    })
    cy.get('[data-testid="bpmn-node"]').should('have.length', 7)
    cy.get('[data-controller="bpmn-editor"]').then(($editor) => {
      $editor[0].dispatchEvent(new CustomEvent('bali-bpmn:export', { detail: { request_id: 'map', format: 'svg', frame: false } }))
    })
    cy.window().its('exported.svg').then((svg) => {
      const doc = new window.DOMParser().parseFromString(svg, 'image/svg+xml')
      const chevron = (p) => /^M1,1 L[\d.]+,1 L[\d.]+,[\d.]+ L[\d.]+,[\d.]+ L1,[\d.]+ L[\d.]+,[\d.]+ Z$/.test(p.getAttribute('d'))
      expect([...doc.querySelectorAll('path:not([data-appearance])')].filter(chevron), 'one chevron per activity').to.have.length(7)
      // The app's colour over six of them follows the outline too.
      expect([...doc.querySelectorAll('path[data-appearance]')].filter(chevron)).to.have.length(6)
    })
  })

  it('keeps the cards for a process flow', () => {
    cy.visit(`${MAP}?activity_shape=card`)
    nodeNamed('Facturación').find('.bpmn-node-shape > g > :first-child').should('match', 'rect')
  })
})

describe('the playground with chevrons', () => {
  it('edits a chevron diagram and keeps its shape after the save', () => {
    cy.intercept('PUT', '**/diagram*').as('save')
    cy.visit('/bali/bpmn_editor/playground?activity_shape=chevron')
    nodeNamed('Validar factura').find('.bpmn-node').should('have.class', 'is-chevron')
    cy.get('[data-testid="bpmn-auto-layout"]').click()
    cy.wait('@save', { timeout: 8000 }).its('request.body.diagram').should('have.property', 'activity_shape', 'chevron')
    nodeNamed('Validar factura').find('.bpmn-node').should('have.class', 'is-chevron')
    cy.screenshot(`${SHOTS}/playground-chevrons`)
  })

  it('turns a vertical diagram to horizontal lanes when the app forces them', () => {
    cy.visit('/bali/bpmn_editor/playground?orientation=vertical&lock_orientation=horizontal')
    cy.get('[data-testid="bpmn-orientation"]').should('not.exist')
    lanesStand('horizontal')
  })

  it('turns a horizontal diagram to vertical lanes when the app forces them, with no switch', () => {
    cy.intercept('PUT', '**/diagram*').as('save')
    cy.visit('/bali/bpmn_editor/playground?activity_shape=chevron&lock_orientation=vertical')
    cy.get('[data-testid="bpmn-auto-layout"]').should('be.visible')
    cy.get('[data-testid="bpmn-orientation"]').should('not.exist')
    lanesStand('vertical')
    cy.get('[data-testid="bpmn-auto-layout"]').click()
    cy.wait('@save', { timeout: 8000 }).its('request.body.diagram').should('include', { orientation: 'vertical', activity_shape: 'chevron' })
    lanesStand('vertical')
    cy.screenshot(`${SHOTS}/playground-vertical`)
  })
})
