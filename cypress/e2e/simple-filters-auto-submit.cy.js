// #725 PR2 — `auto_submit: true` per filter: the pills filter on click, without going
// through the Filter button.
//
// Submits are counted with `cy.intercept` on the form's GET and never by reading the DOM:
// the preview submits to its own URL, so the only thing that tells "nothing was sent" apart
// from "something was sent" is the request's query string. A checked pill proves nothing —
// the browser checks it on click, before the server answers.
const PREVIEW = '/bali/data_table/simple_filters/auto_submit'

// Only a submit carries a query string, so a bare `cy.visit(PREVIEW)` does not land here. A
// visit WITH a query does: when the starting URL carries state, the spy is armed afterwards.
const spyOnSubmits = () =>
  cy.intercept('GET', '**/simple_filters/auto_submit?*').as('submit')

describe('SimpleFilters with auto_submit', () => {
  beforeEach(() => {
    spyOnSubmits()
    cy.visit(PREVIEW)
    cy.get('form[data-controller="submit-on-change"]').should('exist')
  })

  it('sends nothing when the row loads', () => {
    cy.wait(500)

    cy.get('@submit.all').should('have.length', 0)
    cy.location('search').should('eq', '')
  })

  it('filters on a radio pill click, without touching Filter', () => {
    cy.get('input[type="radio"][value="published"]').check()

    cy.wait('@submit').its('request.url').should('include', 'q%5Bstatus_eq%5D=published')
    cy.get('@submit.all').should('have.length', 1)

    // The new URL has to be awaited before looking at the DOM: without that you read the old
    // page, where the pill is checked because the browser checked it and not because it came
    // back from the server.
    cy.location('search').should('include', 'q%5Bstatus_eq%5D=published')
    cy.get('input[type="radio"][value="published"]').should('be.checked')
  })

  it('filters on a toggle pill click', () => {
    cy.get('input[type="checkbox"][value="public"]').check()

    cy.wait('@submit').its('request.url').should('include', 'q%5Bkind_in%5D%5B%5D=public')
    cy.location('search').should('include', 'q%5Bkind_in%5D%5B%5D=public')
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')
  })

  // #996 — the native select auto-submits too: its change fires when the menu closes on a
  // selection, which is as finished a choice as a pill click.
  it('filters when choosing in the select, without touching Filter', () => {
    cy.get('select[name="q[genre_eq]"]').select('comedy')

    cy.wait('@submit').its('request.url').should('include', 'q%5Bgenre_eq%5D=comedy')
    cy.location('search').should('include', 'q%5Bgenre_eq%5D=comedy')
    cy.get('select[name="q[genre_eq]"]').should('have.value', 'comedy')
  })

  // The opt-in does not take the button with it: the filters that did not opt in still need it.
  it('leaves the Filter button in place', () => {
    cy.get('form[data-controller="submit-on-change"] button[type="submit"]').should('exist')
  })
})

// The multi group's accumulation starts from a URL that already carries the first pill,
// instead of chaining two clicks: between one and the other there is a Turbo visit, and the
// cached snapshot it restores first takes the second click to a node about to be discarded.
describe('SimpleFilters with auto_submit, multi group', () => {
  it('accumulates the second pill instead of replacing the first', () => {
    cy.visit(`${PREVIEW}?q%5Bkind_in%5D%5B%5D=public`)
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')

    // After the visit, so the spy does not count the initial load — which here does carry a query.
    spyOnSubmits()
    cy.get('input[type="checkbox"][value="private"]').check()

    cy.wait('@submit').its('request.url').should('include', 'private')
    cy.location('search').should('include', 'private')
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')
    cy.get('input[type="checkbox"][value="private"]').should('be.checked')
  })
})

describe('SimpleFilters without auto_submit', () => {
  // The control: the same pill row without the option mounts no controller and wires nothing,
  // which is what leaves any row that already existed untouched.
  it('does not mount submit-on-change or wire the pills', () => {
    cy.visit('/bali/data_table/simple_filters/toggle_group')

    cy.get('form[data-turbo-frame="_top"]').should('exist')
    cy.get('form[data-controller="submit-on-change"]').should('not.exist')
    cy.get('[data-action*="submit-on-change"]').should('not.exist')
  })
})
