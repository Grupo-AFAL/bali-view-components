// The arrows, the title and the period switch share one row that could not wrap: at 390px the
// month view's page measured 414px, and the year view's 364px at 320 (at 390 it already fit).
describe('Calendar header', () => {
  const views = {
    month: { path: '/bali/calendar/default', widths: [390, 320] },
    year: { path: '/bali/calendar/year', widths: [320] }
  }

  Object.entries(views).forEach(([view, { path, widths }]) => {
    widths.forEach((width) => {
      it(`fits the ${view} view into ${width}px without scrolling the page sideways`, () => {
        cy.viewport(width, 844)
        cy.visit(path)

        cy.get('.calendar-component .header').should('be.visible')
        cy.document().should((doc) => {
          const { scrollWidth, clientWidth } = doc.documentElement
          expect(scrollWidth, `scrollWidth of a page ${clientWidth}px wide`).to.equal(clientWidth)
        })
      })
    })
  })
})
