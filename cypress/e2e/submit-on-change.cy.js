// #717 PR2 — the connect guard and the `debouncedSubmit` action of submit-on-change.
//
// A submit is counted by intercepting the GET the form makes, never by reading the page:
// the form GETs its own URL, so the only difference between "not submitted yet" and
// "submitted" is the query string on the request. Asserting on the rendered value would
// pass on the initial render too.
//
// The preview's select carries `data-inner-html`, and that is load-bearing: rich option
// markup makes SlimSelect rewrite the native <select> during initialization, and the
// rewrite dispatches a `change` on it. Measured against this same preview with
// `skip-initial-value="false"`, the page navigates to
// `?form_record[select]=1&form_record[text]=` on its own before anything is touched.
const PREVIEW = '/bali/submit_on_change/default'

// Only a submit carries a query string — `cy.visit(PREVIEW)` does not, so the initial
// page load never matches.
const spyOnSubmits = () => cy.intercept('GET', '**/bali/submit_on_change/default?*').as('submit')

describe('SubmitOnChangeController', () => {
  it('does not submit while SlimSelect initializes', () => {
    spyOnSubmits()
    cy.visit(PREVIEW)

    // The widget being built is what would have fired the phantom change; wait for it
    // rather than for a bare timeout, so the assertion cannot pass by arriving early.
    cy.get('.ss-main').should('exist')
    cy.wait(500)

    cy.get('@submit.all').should('have.length', 0)
    cy.location('search').should('eq', '')
  })

  it('submits as soon as the select changes', () => {
    spyOnSubmits()
    cy.visit(PREVIEW)
    cy.get('.ss-main').should('exist')

    cy.get('.ss-main').click()
    cy.get('.ss-content .ss-list .ss-option').contains('Comedy').click()

    cy.wait('@submit').its('request.url').should('include', 'form_record%5Bselect%5D=2')
    cy.get('@submit.all').should('have.length', 1)
  })

  it('submits once after the delay when typing, not once per keystroke', () => {
    spyOnSubmits()
    cy.visit(PREVIEW)
    cy.get('.ss-main').should('exist')

    // Four keystrokes well inside the 300ms default: without the debounce this is four
    // submits, and the count below is what tells them apart.
    cy.get('#form_record_text').type('noir')

    cy.wait('@submit').its('request.url').should('include', 'form_record%5Btext%5D=noir')
    cy.get('@submit.all').should('have.length', 1)
  })
})
