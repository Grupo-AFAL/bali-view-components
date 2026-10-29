// `.is-icon-only` on a Button or a button-styled Link: square at any width,
// the label out of view but still the button's accessible name.

const square = ($el) => {
  const box = $el[0].getBoundingClientRect()
  expect(Math.round(box.width), 'width equals height').to.equal(Math.round(box.height))
}

;[['button', '/bali/button/with_icon', 'Add Item'], ['a', '/bali/link/with_icons', 'Click me!']].forEach(([tag, preview, label]) => {
  describe(`${tag === 'a' ? 'Link' : 'Button'} .is-icon-only`, () => {
    // Link's previews are grouped: `with_icon` is the page's first button.
    const btn = () => cy.get(`${tag}.btn`).first()
    beforeEach(() => cy.viewport(1280, 800))

    it('draws the label beside the icon without it', () => {
      cy.visit(`${preview}?responsive=false`)
      btn().should(($btn) => {
        const box = $btn[0].getBoundingClientRect()
        expect(box.width, 'wider than tall').to.be.greaterThan(box.height + 20)
      })
      btn().find('.btn-label').should('be.visible').and('have.text', label)
    })

    it('goes square at a desktop width when the class is added at runtime, keeping its name', () => {
      cy.visit(`${preview}?responsive=false`)
      btn().invoke('addClass', 'is-icon-only').should(square)
      btn().find('.btn-label').should(($label) => {
        const box = $label[0].getBoundingClientRect()
        expect(box.width, 'label width').to.be.at.most(1)
        expect($label.css('display'), 'still in the accessibility tree').not.to.equal('none')
        expect($label.text()).to.equal(label)
      })
      btn().find('svg').should('be.visible')
      btn().invoke('removeClass', 'is-icon-only')
      btn().find('.btn-label').should('be.visible')
    })

    it('is square when rendered with the class', () => {
      cy.visit(`${preview}?icon_only=true`)
      btn().should('have.class', 'is-icon-only').and(square)
    })
  })
})
