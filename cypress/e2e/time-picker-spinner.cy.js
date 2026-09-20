// Hours, minutes and seconds are `input[type=number]`. Chrome stopped honoring
// `appearance: textfield` for that input type, so on whichever field the mouse is over it
// draws ITS spinner in addition to the arrows flatpickr paints in `.numInputWrapper`: two pairs
// in the same column, and the native one —bigger, darker, with its own grey track—
// mounted over the only one of the two that is wired to the calendar value.
//
// The check runs against the CSSOM and not against computed styles on purpose:
// `getComputedStyle(input, '::-webkit-inner-spin-button').appearance` returns the value of
// the input, not of the pseudo — measured, it still says `textfield` with the rule applied
// and the arrows already gone. Reading the rules checks what can be checked without eyes:
// that the declaration reaches the browser through the build and that nothing later
// reverts it.
const spinnerRules = doc =>
  [...doc.styleSheets]
    .flatMap(sheet => {
      try {
        return [...sheet.cssRules]
      } catch {
        return [] // cross-origin sheet
      }
    })
    .filter(
      rule =>
        rule.selectorText &&
        /\.flatpickr-time input::-webkit-(inner|outer)-spin-button/.test(rule.selectorText)
    )

describe('Time picker: the native spinner', () => {
  beforeEach(() => {
    cy.visit('/bali/form/time/default')
    // `.flatpickr-input` is the real field, and flatpickr turns it into `type=hidden` when
    // it mounts its altInput. The one you see, the one that opens the calendar, is the altInput.
    cy.get('input.input:visible').click()
    cy.get('.flatpickr-time input.flatpickr-minute').should('be.visible')
  })

  it('is turned off on the three fields of the row', () => {
    cy.document().then(doc => {
      const rules = spinnerRules(doc)

      expect(rules.length, 'the sheet ships the rule').to.be.greaterThan(0)
      rules.forEach(rule => {
        const value = rule.style.appearance || rule.style.webkitAppearance
        expect(value, `${rule.selectorText} turns it off`).to.equal('none')
      })
    })
  })

  it('the arrows that remain are the flatpickr ones, one pair per column', () => {
    cy.get('.flatpickr-time .numInputWrapper').each($wrapper => {
      const arrows = $wrapper[0].querySelectorAll('span.arrowUp, span.arrowDown')
      expect(arrows.length, 'one pair per column').to.equal(2)
    })
  })
})
