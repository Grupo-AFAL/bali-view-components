// #1253 — SlimSelect hides the real <select> and draws a div[role="combobox"] named from the
// select's aria-label / aria-labelledby and nothing else. The markup looked labelled all
// along — a <label for> reached the select — so these read the name from Chromium's
// accessibility tree, which is what a screen reader is handed. The attribute the FormBuilder
// writes for it is asserted in test/bali/form_builder/slim_select_fields_test.rb.
describe('SlimSelect accessible name', () => {
  const cdp = (command, params = {}) =>
    Cypress.automation('remote:debugger:protocol', { command, params })

  const frameAt = (tree, url) =>
    tree.frame.url === url
      ? tree.frame
      : (tree.childFrames || []).map((child) => frameAt(child, url)).find(Boolean)

  // The page under test is an iframe of the runner, so its tree is asked for by frame.
  const comboboxNames = () =>
    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) =>
          cdp('Accessibility.getFullAXTree', { frameId: frameAt(frameTree, url).id })
        )
        .then(({ nodes }) =>
          nodes
            .filter((node) => !node.ignored && node.role?.value === 'combobox')
            .map((node) => node.name?.value)
        )
    )

  it('names the combobox of a slim_select_group after its caption', () => {
    cy.visit('/bali/form/slim_select/many_selected?locale=es')
    cy.get('.ss-main').should('exist')

    comboboxNames().should('deep.equal', ['Rooms'])
  })

  it('names it on a form where native selects sit beside it', () => {
    // The dummy app lives above the Lookbook preview path `baseUrl` points at.
    cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/movies/new`)
    cy.get('.ss-main').should('exist')

    comboboxNames().should('include', 'Timezone').and('not.include', 'Combobox')
  })
})
