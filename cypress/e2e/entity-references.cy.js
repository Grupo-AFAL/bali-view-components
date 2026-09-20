// #708 — the BlockEditor's `#` against the engine endpoints
// (Bali::EntityReferencesController). The `with_entity_references` preview points at
// /bali/entity_references, so this exercises the whole chain: dummy registry → search →
// payload → chip. The data comes from the seeds (the "Bali Component Library" project),
// the same ones the Cypress workflow loads before running.
//
// No intercept: the value of this test is precisely that the response is built by the
// engine, not by a stub.

describe('BlockEditor: entity references', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_entity_references')
    cy.get('.bn-editor').should('be.visible')
  })

  const editor = () => cy.get('.bn-editor [contenteditable="true"], .bn-editor[contenteditable="true"]').first()

  // The menu is painted when the fetch comes back, and the hook fires one request per
  // keystroke without guaranteeing which one is the last: rather than guessing it, the
  // assertion is left to retry. The timeout is wide on purpose — on a loaded machine the
  // default 4s are not enough, and that is the only thing that fails here, never the result.
  const MENU_TIMEOUT = 20000

  const search = query => {
    editor().click().type(`#${query}`)
    return cy.get('.bn-suggestion-menu', { timeout: MENU_TIMEOUT }).should('be.visible')
  }

  it('searches in the engine and groups by the label the registry declares', () => {
    // The group is the registry's `display: { label: }`: without it the menu would say the
    // raw entityType, and the point of #708-2 is that the type's declaration feeds it.
    search('Bali')
      .should('contain.text', 'Bali Component Library')
      .and('contain.text', 'Project')
  })

  it('inserts the chip with the type and the id the server resolved', () => {
    search('Bali')
    // `search`'s timeout covers its own chain; the result inside the menu needs its own,
    // which is what waiting on the fetch eats up.
    cy.get('.bn-suggestion-menu')
      .contains('Bali Component Library', { timeout: MENU_TIMEOUT })
      .click()

    cy.get('.bn-entity-reference', { timeout: MENU_TIMEOUT })
      .should('have.attr', 'data-entity-type', 'Project')
      .and('contain.text', 'Bali Component Library')
    cy.get('.bn-entity-reference').should('have.attr', 'data-entity-id').and('not.be.empty')
  })

  // A pure negative case ("search for something that does not exist") would pass just the
  // same with a broken endpoint. This one discriminates: the term only matches a task, and
  // the project stays out.
  it('only offers the types whose scope matches the term', () => {
    search('Kanban')
      .should('contain.text', 'Task')
      .and('contain.text', 'Build Kanban component')
      .and('not.contain.text', 'Bali Component Library')
  })
})
