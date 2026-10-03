// #1282 — "is any of" / "is not any of" chosen in the browser got a multi-select that
// condition_controller.js#buildMultiSelectInput assembled as a raw daisyUI .dropdown: its panel
// opened on focus and stayed open on Escape, and the trigger said nothing about having one. The
// one condition/component.html.erb draws opens only on multi-select#toggle (#1028), and
// test/bali/components/filters/condition/component_test.rb holds it to that.
describe('The multi-select a condition builds in the browser', () => {
  const container = '[data-condition-target="valueContainer"]'
  const trigger = `${container} [data-multi-select-target="trigger"]`
  // Written to find the panel of the old markup as well, so a regression fails on the state
  // asserted below and not on a missing selector.
  const panel = `${container} [data-controller~="multi-select"] > div:has(input[type="checkbox"])`

  // daisyUI fades a .dropdown-content in from `opacity: 0`, which Cypress counts as hidden: the
  // state is read from `display` (docs/reference/testing-traps.md).
  const display = (el) => el.ownerDocument.defaultView.getComputedStyle(el).display
  const expectClosed = () => cy.get(panel).should(($panel) => expect(display($panel[0]), 'panel display').to.equal('none'))
  const expectOpen = () => cy.get(panel).should(($panel) => expect(display($panel[0]), 'panel display').not.to.equal('none'))

  // multi_select_controller.js mutes the label while nothing is chosen, on connect: the sign
  // that a widget built from a string has its controller.
  const connected = (count = 1) =>
    cy.get('[data-multi-select-target="label"]')
      .should(($labels) => expect($labels.filter('.text-base-content\\/70')).to.have.length(count))

  // Every element of the widget with its attributes, in document order. `checked` is the
  // choice, not the markup, and the label's text is written by multi_select_controller.js.
  const markup = (root) =>
    [root, ...root.querySelectorAll('*')].map((el) =>
      [el.tagName, ...Array.from(el.attributes)
        .filter(({ name }) => name !== 'checked')
        .map(({ name, value }) => `${name}=${name === 'class' ? value.split(/\s+/).sort().join(' ') : value}`)
        .sort()].join(' ')
    )

  it('is the multi-select the server draws', () => {
    // A `genre_in` with nothing chosen: the server draws the multi-select empty, as the
    // controller builds it.
    cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/admin/movies?q[g][0][genre_in][]=`)
    cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
    cy.get('[data-action="filter-group#addCondition"]').first().click()
    cy.get('[data-condition-target="attribute"]').eq(1).select('genre')
    cy.get('[data-condition-target="operator"]').eq(1).select('in')

    connected(2)
    cy.get('[data-controller~="multi-select"]').should('have.length', 2).then(($widgets) => {
      expect(markup($widgets[1])).to.deep.equal(markup($widgets[0]))
    })
  })

  context('from the keyboard', () => {
    beforeEach(() => {
      cy.visit('/bali/filters/all_field_types?popover=false')
      cy.get('[data-condition-target="attribute"]').select('status')
      cy.get('[data-condition-target="operator"]').select('in')
      connected()
      expectClosed()
    })

    it('stays closed when the trigger takes focus', () => {
      cy.get(trigger).focus()

      expectClosed()
    })

    // Not `type('{enter}')`: on a trigger that does not prevent it, Cypress goes on to submit the
    // form around it, which no browser does for a <div>. A KeyboardEvent, because Stimulus
    // applies the `.enter` / `.space` filters to nothing else: a plain Event runs both toggles.
    // `force`, because a key does not care about the `pointer-events: none` daisyUI puts on a
    // focused .dropdown trigger, and a regression to one has to fail on the panel's state.
    const press = (key) =>
      cy.get(trigger).trigger('keydown', { key, eventConstructor: 'KeyboardEvent', force: true })

    it('opens on Enter and on Space, and closes on Escape back onto the trigger', () => {
      cy.get(trigger).focus()
      press('Enter')
      expectOpen()

      press('Escape')
      expectClosed()
      cy.focused().should('have.attr', 'data-multi-select-target', 'trigger')

      press(' ')
      expectOpen()
    })
  })
})
