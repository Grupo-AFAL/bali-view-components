// `hold-others` on the submit-button controller: one launcher choice at a time.
//
// Each choice GETs the preview with `?choice=…`; the request is held open so the
// in-between state can be looked at, then let through.
const PREVIEW = '/bali/submit_button/launcher'

const holdSubmits = () => {
  let release
  const gate = new Promise(resolve => { release = resolve })
  cy.intercept('GET', '**/bali/submit_button/launcher?*', req => gate.then(() => req.continue())).as('choice')
  return () => release()
}

describe('SubmitButtonController hold-others', () => {
  it('holds the other choices and announces the pressed one while it works', () => {
    const release = holdSubmits()
    cy.visit(PREVIEW)

    cy.get('[data-choice="fridge"]').click()

    cy.get('[data-choice="fridge"]').should('be.disabled').and('contain', 'Preparing 14 items…')
    cy.get('[data-choice="pantry"]').should('be.disabled')
    cy.get('[data-choice="all"]').should('be.disabled')
    cy.get('[role="status"]').should('have.text', 'Preparing 14 items…')

    cy.then(release)
    cy.wait('@choice')
    cy.get('[data-chosen]').should('have.text', 'fridge')
  })

  it('gives the choices back when the submit fails, leaving a button disabled before as it was', () => {
    cy.intercept('GET', '**/bali/submit_button/launcher?*', { statusCode: 422, body: 'Refused' }).as('choice')
    cy.visit(PREVIEW)

    cy.get('[data-choice="fridge"]').click()
    cy.wait('@choice')

    cy.get('[data-choice="pantry"]').should('not.be.disabled')
    cy.get('[data-choice="all"]').should('not.be.disabled')
    cy.get('[data-choice="freezer"]').should('be.disabled').and('not.have.attr', 'data-submit-button-held')
    cy.get('[role="status"]').should('have.text', '')
  })

  it('gives the choices back when Back restores the page', () => {
    cy.visit(PREVIEW)
    cy.get('[data-choice="pantry"]').click()
    cy.get('[data-chosen]').should('have.text', 'pantry')

    cy.go('back')

    cy.location('search').should('eq', '')
    cy.get('[data-choice="fridge"]').should('not.be.disabled')
    cy.get('[data-choice="all"]').should('not.be.disabled')
    cy.get('[role="status"]').should('have.text', '')
  })

  it("puts a nested form's label back after a refused submit", () => {
    cy.intercept('GET', '**/bali/submit_button/launcher?*', { statusCode: 422, body: 'Refused' }).as('choice')
    cy.visit(PREVIEW)

    cy.get('[data-choice="nested"]').click()
    cy.wait('@choice')

    cy.get('[data-choice="nested"]').should('have.text', 'Count with a form').and('not.be.disabled')
  })
})
