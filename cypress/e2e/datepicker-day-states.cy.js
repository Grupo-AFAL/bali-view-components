// `.today` and `.selected` are as specific as `.flatpickr-disabled` and win on order alone
// (datepicker.css). The classes are added by hand: no preview disables today or a selected date.
const settled = el => expect(el.getAnimations(), 'no transition in flight').to.have.length(0)

describe('Datepicker day states', () => {
  beforeEach(() => {
    cy.visit('/bali/form/date/default')
    cy.get('form input.input:not([type="hidden"])').click()
    cy.get('.flatpickr-calendar.open .flatpickr-day.today').should('be.visible')
  })

  it('a disabled today keeps its ring', () => {
    cy.get('.flatpickr-calendar.open .flatpickr-day.today').then($today => {
      const ring = getComputedStyle($today[0]).borderTopColor
      expect(ring, 'the ring is painted').not.to.equal('rgba(0, 0, 0, 0)')

      $today[0].classList.add('flatpickr-disabled')
      cy.wrap($today).should($day => {
        settled($day[0])
        expect(getComputedStyle($day[0]).borderTopColor).to.equal(ring)
      })
    })
  })

  it('a disabled selected date stays filled', () => {
    cy.get('.flatpickr-calendar.open .flatpickr-day:not(.today):not(.prevMonthDay):not(.nextMonthDay)')
      .first()
      .then($day => {
        $day[0].classList.add('selected')
        cy.wrap($day).should($d => settled($d[0])).then(() => {
          const fill = getComputedStyle($day[0]).backgroundColor
          expect(fill, 'the fill is painted').not.to.equal('rgba(0, 0, 0, 0)')

          $day[0].classList.add('flatpickr-disabled')
          cy.wrap($day).should($d => {
            settled($d[0])
            expect(getComputedStyle($d[0]).backgroundColor).to.equal(fill)
          })
        })
      })
  })
})
