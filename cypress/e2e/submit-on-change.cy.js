// #717 PR2 — the connect guard and the `debouncedSubmit` action of submit-on-change.
//
// A submit is counted by intercepting the GET the form makes, never by reading the page:
// the form GETs its own URL, so the only difference between "not submitted yet" and
// "submitted" is the query string on the request. Asserting on the rendered value would
// pass on the initial render too.
//
// The connect guard is for the `change` SlimSelect 3.x dispatched on the native <select> while
// it built its widget over the preview's `data-inner-html` options: measured then with
// `skip-initial-value="false"`, the page navigated to `?form_record[select]=1&form_record[text]=`
// on its own. 4.5.0 dispatches none, so loading the page no longer reaches the guard, and the
// first two tests dispatch that `change` themselves.
const PREVIEW = '/bali/submit_on_change/default'

// Only a submit carries a query string — `cy.visit(PREVIEW)` does not, so the initial
// page load never matches.
const spyOnSubmits = () => cy.intercept('GET', '**/bali/submit_on_change/default?*').as('submit')

const form = () => cy.get('form[data-controller="submit-on-change"]')

// Moving the form connects its controller again, and the `change` goes out before the frame the
// guard waits for: Stimulus connects from a MutationObserver, whose callback runs ahead of the
// `await`.
const changeAsTheFormConnects = () =>
  form().then(async ([element]) => {
    element.parentNode.append(element)
    await Promise.resolve()

    const { Event } = element.ownerDocument.defaultView
    element.querySelector('#form_record_select').dispatchEvent(new Event('change', { bubbles: true }))
  })

describe('SubmitOnChangeController', () => {
  beforeEach(() => {
    spyOnSubmits()
    cy.visit(PREVIEW)
    cy.get('.ss-main').should('exist')
  })

  it('drops a change fired in the frame the form connects in', () => {
    changeAsTheFormConnects()
    cy.wait(500)

    cy.get('@submit.all').should('have.length', 0)
    cy.location('search').should('eq', '')
  })

  it('submits that change with skip-initial off', () => {
    form().invoke('attr', 'data-submit-on-change-skip-initial-value', 'false')
    changeAsTheFormConnects()

    cy.wait('@submit').its('request.url').should('include', 'form_record%5Bselect%5D=1')
  })

  it('submits as soon as the select changes', () => {
    cy.get('.ss-main').click()
    cy.get('.ss-content .ss-list .ss-option').contains('Comedy').click()

    cy.wait('@submit').its('request.url').should('include', 'form_record%5Bselect%5D=2')
    cy.get('@submit.all').should('have.length', 1)
  })

  it('submits once after the delay when typing, not once per keystroke', () => {
    // Four keystrokes well inside the 300ms default: without the debounce this is four
    // submits, and the count below is what tells them apart.
    cy.get('#form_record_text').type('noir')

    cy.wait('@submit').its('request.url').should('include', 'form_record%5Btext%5D=noir')
    cy.get('@submit.all').should('have.length', 1)
  })
})

// A `required` field still empty must not block the re-render that `action`/`method` set up,
// and must keep blocking the form's own submit. The submitter that carries `formaction` is the
// only one the controller creates, so it is the only path that skips validation.
describe('SubmitOnChangeController with a required field empty', () => {
  const pickComedy = () => cy.get('#form_record_select').select('Comedy')

  it('re-renders through action/method without validating', () => {
    cy.intercept('GET', '**/bali/submit_on_change/refresh?*').as('refresh')
    cy.visit('/bali/submit_on_change/refresh')

    pickComedy()

    cy.wait('@refresh').its('request.url').should('include', 'form_record%5Bselect%5D=2')
  })

  it('still validates when the form submits itself', () => {
    cy.intercept('GET', '**/bali/submit_on_change/validated?*').as('submit')
    cy.visit('/bali/submit_on_change/validated')
    cy.window().then(w => cy.spy(w.HTMLFormElement.prototype, 'requestSubmit').as('requestSubmit'))

    pickComedy()

    // The change reached requestSubmit, and validation alone stopped the request
    cy.get('@requestSubmit').should('have.been.calledOnce')
    cy.get('@submit.all').should('have.length', 0)
    cy.location('search').should('eq', '')
  })
})
