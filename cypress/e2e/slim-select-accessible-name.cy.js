// #1253 — SlimSelect hides the real <select> and draws a div[role="combobox"] named from the
// select's aria-label / aria-labelledby and, up to the 3.4 the dummy runs, nothing else. The
// markup looked labelled all along — a <label for> reached the select — so these read the name from Chromium's
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
  const axNodes = (role) =>
    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) =>
          cdp('Accessibility.getFullAXTree', { frameId: frameAt(frameTree, url).id })
        )
        .then(({ nodes }) =>
          nodes
            .filter((node) => !node.ignored && node.role?.value === role)
            .map((node) => ({
              name: node.name?.value,
              description: node.description?.value,
              invalid: node.properties?.find(({ name }) => name === 'invalid')?.value?.value
            }))
        )
    )

  const names = (role) => axNodes(role).then((nodes) => nodes.map(({ name }) => name))

  it('names the combobox of a slim_select_group after its caption', () => {
    cy.visit('/bali/form/slim_select/many_selected?locale=es')
    cy.get('.ss-main').should('exist')

    names('combobox').should('deep.equal', ['Rooms'])
  })

  it('names it on a form where native selects sit beside it', () => {
    // The dummy app lives above the Lookbook preview path `baseUrl` points at.
    cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/movies/new`)
    cy.get('.ss-main').should('exist')

    names('combobox').should('include', 'Timezone').and('not.include', 'Combobox')
  })

  // #1270 — SlimSelect labels its list `ariaLabel + " listbox"`: "Combobox listbox" on every
  // field and in every locale.
  describe('the listbox', () => {
    it('is named after the caption that names the combobox', () => {
      cy.visit('/bali/form/slim_select/many_selected?locale=es')
      cy.get('.ss-main').should('exist')

      names('listbox').should('deep.equal', ['Rooms'])
    })

    it('is named after the aria-label of a select with no caption', () => {
      cy.visit('/bali/data_table/simple_filters/uncaptioned')
      cy.get('.ss-main').should('exist')

      names('listbox').should('deep.equal', ['Owner'])
    })

    // SlimSelect 2.x (centinela-web) puts the listbox role on `.ss-content` itself and leaves
    // it unnamed. The dummy runs 3.x, so this moves the role to where 2.x draws it.
    it('is named where SlimSelect 2.x puts the role, on the content box', () => {
      cy.visit('/bali/form/slim_select/many_selected?locale=es')
      cy.get('.ss-main').should('exist')

      cy.window().then((win) => {
        const controller = win.Stimulus.getControllerForElementAndIdentifier(
          win.document.querySelector('[data-controller~="slim-select"]'),
          'slim-select'
        )
        const { main: content, list } = controller.select.render.content

        for (const attribute of ['role', 'aria-label', 'aria-labelledby']) {
          list.removeAttribute(attribute)
        }
        content.setAttribute('role', 'listbox')
        controller.forwardAccessibility()
      })

      names('listbox').should('deep.equal', ['Rooms'])
    })
  })

  // #1270 — the FormBuilder writes `aria-invalid` and `aria-describedby` on the <select>
  // (html_utils.rb#aria_attributes), the element SlimSelect hides with aria-hidden.
  it('announces the error and the help of its field on the combobox', () => {
    cy.visit('/bali/form/slim_select/with_errors')
    cy.get('.ss-main').should('exist')

    axNodes('combobox').should('deep.equal', [
      {
        name: 'Name',
        description: 'Name must be selected Pick the option that applies to this record.',
        invalid: 'true'
      }
    ])
  })
})
