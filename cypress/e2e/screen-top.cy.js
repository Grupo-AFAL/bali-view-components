// The `screen-top` utility controller: any container learns where it starts,
// for CSS that runs it down to the bottom of the window.
describe('screen-top controller', () => {
  const top = (el) => el.style.getPropertyValue('--bali-screen-top')
  const offset = (win, el) => `${Math.round(el.getBoundingClientRect().top + win.scrollY)}px`

  it('keeps the container top in --bali-screen-top as content above it changes', () => {
    cy.visit('/bali/card/styles')
    cy.document().then((doc) => {
      const box = doc.createElement('div')
      box.dataset.testid = 'screen-top-box'
      box.dataset.controller = 'screen-top'
      doc.body.prepend(box)
    })
    cy.get('[data-testid="screen-top-box"]').should(($box) => {
      const win = $box[0].ownerDocument.defaultView
      expect(top($box[0]), 'connected').to.equal(offset(win, $box[0]))
    })

    cy.document().then((doc) => {
      const banner = doc.createElement('div')
      banner.style.height = '120px'
      doc.body.prepend(banner)
    })
    cy.get('[data-testid="screen-top-box"]').should(($box) => {
      const win = $box[0].ownerDocument.defaultView
      expect(parseInt(top($box[0]), 10), 'below the banner').to.be.at.least(120)
      expect(top($box[0]), 'after the banner').to.equal(offset(win, $box[0]))
    })
  })
})
