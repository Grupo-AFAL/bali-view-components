// Regression cover for #652: changing the operator wiped the chosen value, and the empty
// condition then travelled as a blank Ransack predicate that the server drops in silence.
//
// The DataTable preview is used rather than a bare Filters one because it is the only
// scenario wired the way a real listing is — quick search included — and Apply reads both
// forms.
describe('ConditionController', () => {
  const container = '[data-condition-target="valueContainer"]'
  const value = () => cy.get('[data-condition-target="value"]')
  const hint = () => cy.get('[data-condition-target="hint"]')
  const operator = () => cy.get('[data-condition-target="operator"]')

  // The value widget for a select attribute is a SlimSelect, which hides the real <select>
  // and renders its own trigger and option list.
  const pickValue = (label) => {
    cy.get(`${container} .ss-main`).click()
    cy.get('.ss-content .ss-option').contains(label).click()
  }

  const checkOption = (optionValue) => {
    cy.get(`${container} [data-multi-select-target="trigger"]`).click()
    cy.get(`${container} input[value="${optionValue}"]`).check()
  }

  beforeEach(() => {
    cy.visit('/bali/data_table/complete')
    cy.get('.filters button').contains('Filters').click()
    cy.get('[data-condition-target="attribute"]').select('genre')
  })

  it('keeps the chosen value when the operator changes but the widget does not', () => {
    pickValue('Drama')
    value().should('have.value', 'Drama')

    operator().select('not_eq')

    value().should('have.value', 'Drama')
    value().should('have.attr', 'name', 'q[g][0][genre_not_eq]')
    hint().should('not.have.class', 'is-shown')
  })

  it('carries the chosen value into the multi-value widget', () => {
    pickValue('Drama')

    operator().select('in')

    cy.get(`${container} input[value="Drama"]`).should('be.checked')
    cy.get(`${container} input[value="Comedy"]`).should('not.be.checked')
  })

  it('drops several values rather than silently keeping one, and says so', () => {
    pickValue('Drama')
    operator().select('in')
    checkOption('Comedy')

    operator().select('eq')

    value().should('have.value', '')
    hint().should('have.class', 'is-shown')
  })

  it('says so as soon as a chosen value is cleared, before Apply is pressed', () => {
    pickValue('Drama')
    hint().should('not.have.class', 'is-shown')

    pickValue('Select...')

    hint().should('have.class', 'is-shown')
  })

  context('on Apply', () => {
    // The form is read at the moment it is submitted, with the navigation cancelled: that
    // is the only place where what actually travels can be observed.
    const captureSubmission = () => {
      cy.window().then((win) => {
        const form = win.document.querySelector('[data-filters-target="form"]')
        win.__submitted = null
        form.addEventListener('submit', (event) => {
          event.preventDefault()
          win.__submitted = Array.from(new win.FormData(form))
            .filter(([key]) => key.startsWith('q['))
            .map(([key]) => key)
        })
      })
    }

    const apply = () => cy.get('.filters button').contains('Apply').click()
    const submitted = () => cy.window().its('__submitted')

    it('leaves a condition with no value out of the request', () => {
      captureSubmission()

      apply()

      submitted().should('deep.equal', ['q[g][0][m]'])
    })

    it('leaves a value typed without an attribute out of the request', () => {
      cy.get('[data-condition-target="attribute"]').select('')
      value().type('orphan')
      captureSubmission()

      apply()

      submitted().should('deep.equal', ['q[g][0][m]'])
    })

    it('sends the condition the user did fill in', () => {
      pickValue('Drama')
      captureSubmission()

      apply()

      submitted().should('deep.equal', ['q[g][0][m]', 'q[g][0][genre_eq]'])
    })

    it('flags the condition it had to leave out', () => {
      captureSubmission()

      apply()

      hint().should('have.class', 'is-shown')
    })
  })
})
