// `frame_options:` against its preview, whose frame carries `autoscroll`,
// `data-autoscroll-block="start"` and `lg:sticky lg:top-4`, and whose detail
// opens with a marker hidden from `lg` up. The two widths are the two halves of
// that recipe: stacked, a row click brings the detail into view; side by side,
// the page stays put and the pinned frame keeps the detail on screen.
//
// `scrollBehavior: false` on every click: Cypress otherwise scrolls the row into
// view itself and moves the very scrollY these tests measure.
describe('SplitView frame_options (#1279)', () => {
  const detailTitle = () => cy.get('.split-view-detail [data-testid="detail-title"]')

  it('scrolls the detail into view when the panes are stacked', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/split_view/frame_options')
    cy.get('#split-view-detail').should(($frame) => {
      expect($frame[0].getBoundingClientRect().top, 'detail top before the click').to.be.greaterThan(844)
    })

    cy.get('.split-view-row').eq(2).click({ scrollBehavior: false })

    detailTitle().should('exist')
    cy.get('.split-view-detail .card').should(($card) => {
      const { top, bottom } = $card[0].getBoundingClientRect()
      expect(top, 'card top').to.be.at.least(0)
      expect(bottom, 'card bottom').to.be.at.most(844)
    })
  })

  it('leaves the page where it was, with the detail beside the row, when the panes sit side by side', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/split_view/frame_options')
    // The pin's top set apart from the marker's 16px `scroll-mt-4`. With the two
    // equal, a visible marker already sits where Turbo would scroll it, so the
    // page stayed put without `lg:hidden`; with the pin at 80px it moved 64px.
    cy.get('#split-view-detail').then(($frame) => { $frame[0].style.top = '80px' })
    cy.window().then(win => win.scrollTo(0, 600))
    cy.window().its('scrollY').should('eq', 600)

    cy.get('.split-view-detail .empty-state-component').should('exist')
    cy.get('.split-view-row').eq(9).click({ scrollBehavior: false })

    // Turbo scrolls in the same task that inserts the new detail, so once the
    // title is in the frame the scroll has already happened or never will.
    detailTitle().should('exist')
    cy.window().its('scrollY').should('eq', 600)
    cy.get('.split-view-detail .card').should(($card) => {
      const { top, bottom } = $card[0].getBoundingClientRect()
      expect(top, 'card top').to.be.at.least(0)
      expect(bottom, 'card bottom').to.be.at.most(800)
    })
  })

  it('still pushes the selection into the URL, so advance: survives the merge', () => {
    cy.visit('/bali/split_view/frame_options')
    cy.get('.split-view-row').eq(2).click({ scrollBehavior: false })

    detailTitle().should('exist')
    cy.location('search').should('match', /^\?selected=\d+$/)
  })
})
