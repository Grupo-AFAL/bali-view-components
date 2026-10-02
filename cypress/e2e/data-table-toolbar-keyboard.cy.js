// #1250: the toolbar held two keyboard models side by side. Columns and Views were raw
// `.dropdown`s that daisyUI opened from `:focus-within`, so Tab unfolded them and no key closed
// them, while Group by was a Bali::Dropdown, which only a click, Enter, Space or an arrow opens
// (#1231). All three are Bali::Dropdowns now, and this walks the row as a keyboard user would.
describe('DataTable toolbar keyboard', () => {
  const toolbar = '[data-controller~="toolbar-overflow"]'
  const trigger = (label) => `${toolbar} .dropdown > [aria-label="${label}"]`
  const panel = (label) => `${trigger(label)} ~ .dropdown-content`
  const overflowTrigger = '[data-toolbar-overflow-target="overflow"] > .dropdown > [role="button"]'
  const overflowPanel = '[data-toolbar-overflow-target="overflow"] > .dropdown > .dropdown-content'
  const columnBox = `${panel('Columns')} input[data-column-index]`

  // `force`: daisyUI gives an open trigger `pointer-events: none`, which says nothing about keys.
  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })

  // `display` and not `not.be.visible`: see docs/reference/testing-traps.md.
  const display = ($el) => $el[0].ownerDocument.defaultView.getComputedStyle($el[0]).display
  const expectClosed = ($panel) => expect(display($panel), 'panel display').to.equal('none')
  const expectOpen = ($panel) => expect(display($panel), 'panel display').not.to.equal('none')

  context('in the row', () => {
    beforeEach(() => {
      cy.viewport(1440, 900)
      cy.visit('/bali/data_table/complete')
    })

    ;['Group by', 'Columns', 'Views'].forEach((label) => {
      it(`does not open ${label} when the focus reaches it`, () => {
        cy.get(trigger(label)).focus()

        cy.get(panel(label)).should(expectClosed)
        cy.get(trigger(label)).should('have.attr', 'aria-expanded', 'false')
      })

      it(`opens ${label} on Enter, Space and ArrowDown, and Escape hands the focus back`, () => {
        cy.get(trigger(label)).focus()

        ;['Enter', ' ', 'ArrowDown'].forEach((key) => {
          press(key)
          cy.get(panel(label)).should(expectOpen)
          cy.get(trigger(label)).should('have.attr', 'aria-expanded', 'true')

          press('Escape')
          cy.get(panel(label)).should(expectClosed)
          cy.get(trigger(label)).should('have.attr', 'aria-expanded', 'false')
          cy.focused().should('have.attr', 'aria-label', label)
        })
      })
    })

    it('walks the column checkboxes with the arrows', () => {
      cy.get(trigger('Columns')).focus()

      press('ArrowDown')
      cy.get(columnBox).eq(0).should('have.focus')

      press('ArrowDown')
      cy.get(columnBox).eq(1).should('have.focus')

      press('ArrowUp')
      cy.get(columnBox).eq(0).should('have.focus')
    })

    // Clicked without `force`: with the menu open the box is actionable, which is the point.
    it('hides, shows and remembers a column chosen from the menu', () => {
      cy.get(columnBox).eq(1).invoke('attr', 'data-column-index').then((index) => {
        const header = () => cy.get('#lookbook_movies thead th').eq(Number(index))
        const box = () => cy.get(`${panel('Columns')} input[data-column-index="${index}"]`)

        cy.get(trigger('Columns')).click()
        box().click()
        header().should('not.be.visible')

        cy.reload()
        header().should('not.be.visible')
        box().should('not.be.checked')

        cy.get(trigger('Columns')).click()
        box().click()
        header().should('be.visible')
      })
    })

    // Focus moving INTO the panel is not focus leaving the dropdown: the input the button
    // reveals is inside it.
    it('keeps Views open while its save form takes the focus', () => {
      cy.get(trigger('Views')).focus()
      press('Enter')

      cy.get(panel('Views')).contains('button', 'Save current view').click()

      cy.get('[data-saved-views-target="saveForm"] input[name="name"]').should('have.focus')
      cy.get(panel('Views')).should(expectOpen)
    })
  })

  // Folded into the ⋯, the control is a dropdown inside a dropdown: its keys are its own, and
  // closing it leaves the ⋯ open around it.
  context('folded into the ⋯', () => {
    beforeEach(() => {
      cy.viewport(375, 800)
      cy.visit('/bali/data_table/complete')
      cy.get(overflowTrigger).click()
      cy.get(overflowPanel).should(expectOpen)
    })

    it('opens Columns with the keyboard and not with the focus', () => {
      cy.get(trigger('Columns')).focus()
      cy.get(panel('Columns')).should(expectClosed)

      press('Enter')
      cy.get(panel('Columns')).should(expectOpen)
      cy.get(columnBox).eq(0).should('have.focus')

      press('Escape')
      cy.get(panel('Columns')).should(expectClosed)
      cy.focused().should('have.attr', 'aria-label', 'Columns')
      cy.get(overflowPanel).should(expectOpen)
    })
  })
})
