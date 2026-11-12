// Each kind of element in its own colour, in every theme: yellow start,
// blue activity and Yes/No decision, orange gateway, red end (SoftExpert's
// convention). One custom property per kind on the editor, which an app may
// set and which the outputs carry.

const PLAYGROUND = '/bali/bpmn_editor/playground?sample=invoice'
const shapeOf = (name) => cy.contains('.react-flow__node-bpmn', name).find('.bpmn-node-shape > g > :first-child')
const rgb = (win, color) => {
  const pixel = win.document.createElement('canvas').getContext('2d', { willReadFrequently: true })
  pixel.fillStyle = '#fff'
  pixel.fillRect(0, 0, 1, 1)
  pixel.fillStyle = color
  pixel.fillRect(0, 0, 1, 1)
  return [...pixel.getImageData(0, 0, 1, 1).data.slice(0, 3)]
}
const luminance = (channels) => {
  const [r, g, b] = channels.map((c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4 })
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
const contrast = (a, b) => { const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05) }

describe('the colour of each kind of element', () => {
  beforeEach(() => cy.viewport(1400, 900))

  it('paints the start yellow, activities blue, gateways orange and the end red', () => {
    cy.visit(PLAYGROUND)
    shapeOf('Factura recibida').should('have.css', 'stroke', 'rgb(230, 195, 0)')
    shapeOf('Validar factura').should('have.css', 'stroke', 'rgb(21, 151, 201)')
    shapeOf('¿La factura es válida?').should('have.css', 'stroke', 'rgb(217, 119, 6)')
    shapeOf('Pago realizado').should('have.css', 'stroke', 'rgb(211, 47, 47)')
  })

  for (const theme of ['light', 'dark']) {
    it(`keeps an activity's name legible on its fill (${theme})`, () => {
      cy.visit(`${PLAYGROUND}&theme=${theme}`)
      cy.contains('.react-flow__node-bpmn', 'Validar factura').then(($node) => {
        const win = $node[0].ownerDocument.defaultView
        const fill = rgb(win, win.getComputedStyle($node[0].querySelector('.bpmn-node-shape > g > :first-child')).fill)
        const text = rgb(win, win.getComputedStyle($node[0].querySelector('.bpmn-label-inside')).color)
        expect(contrast(fill, text), `text ${text} on ${fill}`).to.be.at.least(4.5)
      })
    })
  }

  it('leaves the body of an activity the app colours to that colour alone', () => {
    cy.visit('/bali/bpmn_editor/default?appearance=true')
    shapeOf('Registrar pago').should('have.css', 'fill', 'oklch(1 0 0)')
  })

  // The app's sheet is in <head> before the island links flow.css after it.
  it("takes an app's colour for a kind from its stylesheet, in a layer or not, on the canvas and in the SVG", () => {
    cy.visit(PLAYGROUND, {
      onBeforeLoad (win) {
        win.document.addEventListener('bali-bpmn:exported', (event) => { win.exported = event.detail })
        const style = win.document.createElement('style')
        // Tailwind's own order first, as an app's build opens with it.
        style.textContent = '@layer theme, base, components, utilities; .bali-bpmn-editor { --bpmn-activity: #7c3aed } @layer components { .bali-bpmn-editor { --bpmn-end: #0f766e } }'
        win.document.head.appendChild(style)
      }
    })
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    shapeOf('Validar factura').should('have.css', 'stroke', 'rgb(124, 58, 237)')
    shapeOf('Pago realizado').should('have.css', 'stroke', 'rgb(15, 118, 110)')
    cy.get('[data-controller="bpmn-editor"]').then(($editor) => {
      $editor[0].dispatchEvent(new CustomEvent('bali-bpmn:export', { detail: { request_id: 'colors', format: 'svg', frame: false } }))
    })
    cy.window().its('exported.svg').should('contain', 'stroke="#7c3aed"')
  })
})
