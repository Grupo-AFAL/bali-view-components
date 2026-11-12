// A chevron activity selected, while reading and while editing, is outlined
// with its own shape, not the card's rounded box. And `title:` /
// `title_badge:` name what is being edited in the editor's own bar, there in
// full screen too, cut with «…» rather than pushing the editor out.

const PLAYGROUND = '/bali/bpmn_editor/playground'
const MAP = '/bali/bpmn_editor/macroprocess_map?lock_orientation=horizontal'
const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)
// The card's selection is the node's ::after; a chevron's, an SVG path in its shape.
const afterContent = ($node) => getComputedStyle($node[0], '::after').content

describe('selecting a chevron activity', () => {
  beforeEach(() => cy.viewport(1400, 900))

  it('outlines it as a chevron while reading', () => {
    cy.visit(MAP)
    nodeNamed('Facturación').click()
    nodeNamed('Facturación').find('.bpmn-node').should(($node) => expect(afterContent($node)).to.eq('none'))
    nodeNamed('Facturación').find('[data-testid="bpmn-node-selection"]').should('be.visible')
    // The ring keeps its 6 px off the shape at the notch and the point too, not only along the flat edges.
    nodeNamed('Facturación').find('.bpmn-node-shape').then(($shape) => {
      const [w, h] = [Number($shape.attr('width')), Number($shape.attr('height'))]
      const depth = Math.round(h * 0.25 * 10) / 10
      nodeNamed('Facturación').find('[data-testid="bpmn-node-selection"] path').last().invoke('attr', 'd').then((d) => {
        const xs = d.match(/-?[\d.]+(?=,)/g).map(Number)
        expect(xs[5], 'the notch').to.be.at.most(1 + depth - 6)
        expect(xs[2], 'the point').to.be.at.least(w - 1 + 6)
      })
    })
  })

  it('outlines it as a chevron while editing, and a card keeps its box', () => {
    cy.visit(`${PLAYGROUND}?activity_shape=chevron`)
    nodeNamed('Validar factura').click()
    nodeNamed('Validar factura').find('.bpmn-node').should(($node) => expect(afterContent($node)).to.eq('none'))
    nodeNamed('Validar factura').find('[data-testid="bpmn-node-selection"]').should('be.visible')

    cy.visit(PLAYGROUND)
    nodeNamed('Validar factura').click()
    nodeNamed('Validar factura').find('.bpmn-node').should(($node) => expect(afterContent($node)).not.to.eq('none'))
    nodeNamed('Validar factura').find('[data-testid="bpmn-node-selection"]').should('not.exist')
  })
})

describe('the title in the editor’s bar', () => {
  const title = 'Macroproceso: Operación de Restaurantes'
  const withTitle = (name) => `${PLAYGROUND}?title=${encodeURIComponent(name)}&title_badge=${encodeURIComponent('Modo edición')}`

  it('is cut with «…» on a narrow screen instead of pushing the editor out', () => {
    cy.viewport(700, 800)
    cy.visit(withTitle(`${title} con un nombre bastante largo para la barra`))
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.get('[data-testid="bpmn-title"]').should(($title) => {
      const editor = $title[0].closest('.bali-bpmn-editor').getBoundingClientRect()
      expect(editor.right, 'the editor inside the window').to.be.at.most(700)
      expect($title[0].getBoundingClientRect().right, 'the title inside the editor').to.be.at.most(editor.right)
      const h2 = $title[0].querySelector('h2')
      expect(h2.scrollWidth, 'cut').to.be.greaterThan(h2.clientWidth)
    })
  })

  it('names what is being edited, in full screen too', () => {
    cy.viewport(1400, 900)
    cy.visit(withTitle(title), { onBeforeLoad: fakeFullscreen })
    cy.get('[data-testid="bpmn-title"] h2').should('have.text', title).and('have.attr', 'title', title)
    cy.get('[data-testid="bpmn-title"]').should('contain', 'Modo edición')
    cy.contains('button', 'Pantalla completa').click()
    cy.get('[data-testid="bpmn-title"] h2').should('be.visible').and('have.text', title)
    cy.contains('button', 'Salir de pantalla completa').click()
  })
})

// Headless Chrome refuses a full screen the test asks for (it is no user
// gesture): the API is stubbed, as in bpmn-page.cy.js.
function fakeFullscreen (win) {
  let current = null
  Object.defineProperty(win.document, 'fullscreenElement', { configurable: true, get: () => current })
  const change = (element) => { current = element; win.document.dispatchEvent(new win.Event('fullscreenchange')); return Promise.resolve() }
  win.Element.prototype.requestFullscreen = function () { return change(this) }
  win.document.exitFullscreen = () => change(null)
}
