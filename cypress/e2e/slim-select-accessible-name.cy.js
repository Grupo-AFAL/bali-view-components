import { cdp, frameAt } from '../support/accessibility_tree'

// #1253 — SlimSelect hides the real <select> and draws a div[role="combobox"] named from the
// select's aria-label / aria-labelledby and, before SlimSelect 3.5, nothing else. The markup
// looked labelled all along — a <label for> reached the select — so these read the name — and,
// for #1270, the description and invalid state — from Chromium's accessibility tree, which is
// what a screen reader is handed. The attributes the FormBuilder writes for them are asserted
// in test/bali/form_builder/slim_select_fields_test.rb.
describe('SlimSelect accessible name', () => {
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

    // A select with neither attribute leaves SlimSelect's `ariaLabel` default on the combobox.
    // Picking a name from the <select>'s own attributes, the list would keep "Combobox listbox".
    it('takes the default name of the combobox when the select has none', () => {
      cy.visit('/bali/form/slim_select/default')
      cy.get('.ss-main').should('exist')

      names('combobox').should('deep.equal', ['Combobox'])
      names('listbox').should('deep.equal', ['Combobox'])
    })

    // Every SlimSelect from 2.x to 4.x names the combobox from aria-label when the select
    // carries both; the name calculation prefers aria-labelledby. Copying both attributes off
    // the <select>, the list would be "Rooms".
    it('follows the combobox when the select carries both aria-label and aria-labelledby', () => {
      cy.intercept('GET', '**/slim_select/many_selected*', (req) =>
        req.continue((res) => {
          res.body = res.body.replace(
            'aria-labelledby=',
            'aria-label="Meeting rooms" aria-labelledby='
          )
        })
      )
      cy.visit('/bali/form/slim_select/many_selected?locale=es')
      cy.get('select[aria-label="Meeting rooms"][aria-labelledby]').should('exist')
      cy.get('.ss-main').should('exist')

      names('combobox').should('deep.equal', ['Meeting rooms'])
      names('listbox').should('deep.equal', ['Meeting rooms'])
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

  it('leaves the combobox of a field without errors neither invalid nor described', () => {
    cy.visit('/bali/form/slim_select/many_selected?locale=es')
    cy.get('.ss-main').should('exist')

    axNodes('combobox').should('deep.equal', [
      { name: 'Rooms', description: undefined, invalid: undefined }
    ])
  })
})
