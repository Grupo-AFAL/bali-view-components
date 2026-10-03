import { cdp, frameAt } from '../support/accessibility_tree'

// #1271 — a filter condition paints no caption for its field, its operator or its value, and
// the value is whichever widget the field's type asks for: condition/component.html.erb paints
// the first one and condition_controller.js rebuilds it on every change of field. SlimSelect
// and flatpickr both hide the element they were given and draw their own, so the names are
// read from Chromium's accessibility tree, which is what a screen reader is handed. The
// attributes the ERB writes are asserted in
// test/bali/components/filters/condition/component_test.rb.
describe('Filter condition accessible names', () => {
  const container = '[data-condition-target="valueContainer"]'
  const attribute = () => cy.get('[data-condition-target="attribute"]')
  const operator = () => cy.get('[data-condition-target="operator"]')

  // Only the condition's subtree is asked for: the page around it has comboboxes and text
  // boxes of its own.
  const conditionControls = (roles = ['combobox', 'textbox', 'spinbutton']) =>
    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) => cdp('DOM.getFrameOwner', { frameId: frameAt(frameTree, url).id }))
        .then(({ backendNodeId }) => cdp('DOM.describeNode', { backendNodeId, depth: 1, pierce: true }))
        .then(({ node }) => cdp('DOM.resolveNode', { backendNodeId: node.contentDocument.backendNodeId }))
        .then(({ object }) =>
          cdp('Runtime.callFunctionOn', {
            objectId: object.objectId,
            functionDeclaration: 'function () { return this.querySelector(\'[data-controller~="condition"]\') }'
          })
        )
        .then(({ result }) =>
          Promise.all(
            roles.map((role) =>
              cdp('Accessibility.queryAXTree', { objectId: result.objectId, role })
            )
          )
        )
        .then((answers) =>
          answers
            .flatMap(({ nodes }) => nodes.filter((node) => !node.ignored))
            .map((node) => `${node.role.value} «${node.name?.value ?? ''}»`)
            .sort()
        )
    )

  // SlimSelect and flatpickr mount from a Stimulus controller, after the markup lands.
  const slimSelectMounted = () => cy.get(`${container} .ss-main`).should('exist')
  const flatpickrMounted = () =>
    cy.get(`${container} [data-controller="datepicker"][type="hidden"]`).should('exist')

  // multi_select_controller.js writes what is chosen into the trigger on connect and on
  // every change.
  const multiSelectShows = (text) =>
    cy.get(`${container} [data-multi-select-target="label"]`).should('have.text', text)

  // flatpickr reads the user agent when it mounts, and on a phone it hides its altInput too
  // and shows a native `input.flatpickr-mobile` (date, datetime-local) in its place.
  const onAPhone = {
    onBeforeLoad (win) {
      Object.defineProperty(win.navigator, 'userAgent', {
        value: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
        configurable: true
      })
    }
  }
  const nativeDateMounted = () => cy.get(`${container} input.flatpickr-mobile`).should('exist')

  context('in the page language', () => {
    // The dummy app lives above the Lookbook preview path `baseUrl` points at, and is the
    // only place that serves Spanish.
    const openMovieFilters = (query, visitOptions = {}) => {
      cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/admin/movies?locale=es&${query}`, visitOptions)
      cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
    }

    it('names the controls the server painted', () => {
      openMovieFilters('q[g][0][genre_eq]=Drama')
      slimSelectMounted()

      conditionControls().should('deep.equal', [
        'combobox «Campo»',
        'combobox «Operador»',
        'combobox «Valor»'
      ])
    })

    it('leaves the multi-select trigger it painted named by the choices it shows', () => {
      openMovieFilters('q[g][0][genre_in][]=Action&q[g][0][genre_in][]=Adventure')
      multiSelectShows('Action, Adventure')

      conditionControls(['button']).should('deep.equal', [
        'button «Action, Adventure»', 'button «Eliminar condición»'
      ])
    })

    it('names the value widget it rebuilds when the field changes', () => {
      openMovieFilters('q[g][0][genre_eq]=Drama')
      slimSelectMounted()

      attribute().select('status')
      slimSelectMounted()

      conditionControls().should('deep.equal', [
        'combobox «Campo»',
        'combobox «Operador»',
        'combobox «Valor»'
      ])
    })

    it('names the native date field a phone gets for the date the server painted', () => {
      openMovieFilters('q[g][0][created_at_eq]=2026-01-15', onAPhone)
      nativeDateMounted()

      conditionControls(['combobox', 'Date']).should('deep.equal', [
        'Date «Valor»', 'combobox «Campo»', 'combobox «Operador»'
      ])
    })
  })

  it('names the native date field a phone gets for the dates it rebuilds', () => {
    cy.visit('/bali/filters/all_field_types?popover=false', onAPhone)

    attribute().select('birth_date')
    nativeDateMounted()
    conditionControls(['Date']).should('deep.equal', ['Date «Value»'])

    attribute().select('last_login')
    operator().select('eq')
    nativeDateMounted()
    conditionControls(['DateTime']).should('deep.equal', ['DateTime «Value»'])
  })

  it('names the value widget it rebuilds for every type of field', () => {
    cy.visit('/bali/filters/all_field_types?popover=false')

    attribute().select('name')
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'textbox «Value»'
    ])

    attribute().select('age')
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'spinbutton «Value»'
    ])

    attribute().select('birth_date')
    flatpickrMounted()
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'textbox «Value»'
    ])

    operator().select('between')
    flatpickrMounted()
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'textbox «Value»'
    ])

    attribute().select('last_login')
    operator().select('eq')
    flatpickrMounted()
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'textbox «Value»'
    ])

    operator().select('between')
    flatpickrMounted()
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'textbox «Value»'
    ])

    attribute().select('is_active')
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'combobox «Value»'
    ])

    attribute().select('status')
    slimSelectMounted()
    conditionControls().should('deep.equal', [
      'combobox «Field»', 'combobox «Operator»', 'combobox «Value»'
    ])

    // The multi-select trigger keeps the name its text gives it, which lists what is chosen.
    operator().select('in')
    conditionControls(['button']).should('deep.equal', [
      'button «Remove condition»', 'button «Select values...»'
    ])

    cy.get(`${container} [data-multi-select-target="trigger"]`).click()
    cy.get(`${container} input[type="checkbox"][value="pending"]`).check()
    multiSelectShows('Pending')
    conditionControls(['button']).should('deep.equal', [
      'button «Pending»', 'button «Remove condition»'
    ])
  })
})
