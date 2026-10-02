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

  const cdp = (command, params = {}) =>
    Cypress.automation('remote:debugger:protocol', { command, params })

  const frameAt = (tree, url) =>
    tree.frame.url === url
      ? tree.frame
      : (tree.childFrames || []).map((child) => frameAt(child, url)).find(Boolean)

  // The page under test is an iframe of the runner, so the condition is reached through the
  // frame's document, and only its own subtree is asked for: the page around it has
  // comboboxes and text boxes of its own.
  const conditionControls = () =>
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
            ['combobox', 'textbox', 'spinbutton'].map((role) =>
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

  context('in the page language', () => {
    beforeEach(() => {
      // The dummy app lives above the Lookbook preview path `baseUrl` points at, and is
      // the only place that serves Spanish.
      cy.visit(
        `${new URL(Cypress.config('baseUrl')).origin}/admin/movies?locale=es&q[g][0][genre_eq]=Drama`
      )
      cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
      slimSelectMounted()
    })

    it('names the controls the server painted', () => {
      conditionControls().should('deep.equal', [
        'combobox «Campo»',
        'combobox «Operador»',
        'combobox «Valor»'
      ])
    })

    it('names the value widget it rebuilds when the field changes', () => {
      attribute().select('status')
      slimSelectMounted()

      conditionControls().should('deep.equal', [
        'combobox «Campo»',
        'combobox «Operador»',
        'combobox «Valor»'
      ])
    })
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
  })
})
