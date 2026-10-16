// The phone template's arrows and title sat in a Columns that stacks under 768px, so on every
// phone they took three rows. 320px is where the Spanish title wraps onto two lines.
describe('Calendar phone template', () => {
  const box = (el) => el.getBoundingClientRect()

  ;[375, 320].forEach((width) => {
    it(`keeps an arrow either side of the title at ${width}px`, () => {
      cy.viewport(width, 812)
      cy.visit('/bali/calendar/mobile?start_date=2026-10-14&locale=es')

      cy.get('.day-view').should(($view) => {
        const [prev, next] = [...$view.find('a[title]')].map(box)
        const title = box($view.find('span.text-lg')[0])

        expect(prev.right, 'previous arrow ends before the title').to.be.at.most(title.left)
        expect(next.left, 'next arrow starts after the title').to.be.at.least(title.right)
        ;[prev, next].forEach((arrow) => {
          const middle = (arrow.top + arrow.bottom) / 2
          expect(middle, 'arrow on the title\'s row').to.be.within(title.top, title.bottom)
        })
      })
    })
  })
})
