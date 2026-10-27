// A panel that draws the frame itself: the editor with `bordered: false`, a
// Bali::Card `style: :flush` header with the app's own divider, and the
// comparison bar without the pieces `review: { compare_bar: }` turns off.

const CARD = '/bali/bpmn_editor/in_a_card'

const frame = ($el) => {
  const style = window.getComputedStyle($el[0])
  return { border: style.borderTopWidth, radius: style.borderTopLeftRadius, shadow: style.boxShadow }
}

describe('BPMN editor inside a card', () => {
  it('draws no frame of its own, and the flush header only the app\'s divider', () => {
    cy.visit(CARD)
    cy.get('[data-testid="bpmn-card-panel"] [data-testid="bpmn-node"]').should('have.length.at.least', 3)
    cy.get('.bpmn-editor').should(($editor) => {
      expect(frame($editor)).to.deep.equal({ border: '0px', radius: '0px', shadow: 'none' })
    })
    cy.get('[data-testid="bpmn-card-panel"] > .card').should(($card) => {
      expect(frame($card)).to.deep.equal({ border: '0px', radius: '0px', shadow: 'none' })
      expect(window.getComputedStyle($card[0]).borderBottomWidth).to.equal('1px')
    })
    cy.get('[data-testid="bpmn-card-panel"]').screenshot('bpmn-in-a-card/frameless')
  })

  it('keeps its frame with bordered on', () => {
    cy.visit(`${CARD}?bordered=true`)
    cy.get('[data-testid="bpmn-card-panel"] [data-testid="bpmn-node"]').should('have.length.at.least', 3)
    cy.get('.bpmn-editor').should(($editor) => {
      const { border, radius, shadow } = frame($editor)
      expect(border).to.equal('1px')
      expect(radius).not.to.equal('0px')
      expect(shadow).not.to.equal('none')
    })
  })

  it('leaves out the comparison bar\'s pieces the app turns off, never its switches', () => {
    cy.visit(`${CARD}?compare=true`)
    cy.get('[data-testid="bpmn-compare"]').should('be.visible')
    cy.get('[data-testid="bpmn-compare-only-changes"]').should('exist')
    cy.get('[data-testid="bpmn-compare-sync"]').should('exist')
    ;['bpmn-compare-title', 'bpmn-compare-by-name', 'bpmn-compare-exit', 'bpmn-compare-caption'].forEach((id) => {
      cy.get(`[data-testid="${id}"]`).should('not.exist')
    })
    cy.get('[data-testid="bpmn-card-panel"]').screenshot('bpmn-in-a-card/compare-bar-trimmed')
  })

  it('shows every piece by default', () => {
    cy.visit(`${CARD}?compare=true&title=true&match_note=true&exit=true&captions=true`)
    cy.get('[data-testid="bpmn-compare-title"]').should('contain', 'Alta de cliente')
    cy.get('[data-testid="bpmn-compare-by-name"]').should('exist')
    cy.get('[data-testid="bpmn-compare-exit"]').should('exist')
    cy.get('[data-testid="bpmn-compare-caption"]').should('have.length', 2)
  })
})
