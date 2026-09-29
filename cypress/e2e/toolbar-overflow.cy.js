// Node movement is only observable in a browser: Minitest sees the served HTML, which is
// always the expanded layout.
//
// 1440 and not 1280 as the "wide" viewport: the collapse is no longer decided by the breakpoint
// but by how much width the row NEEDS (measured ~1180px in this preview), and at 1280 the margin
// was down to ~70px — less than the same text can shift when rendered with other fonts in CI.
// A roomy width tests what the test means to test: expanded is expanded.
describe('DataTable toolbar overflow', () => {
  const menu = '[data-toolbar-overflow-target="menu"]'
  const overflow = '[data-toolbar-overflow-target="overflow"]'
  const leftGroup = '[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="left"]'
  const memoryGroup = '[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="memory"]'
  const separator = '[data-toolbar-overflow-target="separator"]'
  const columnsItem = '[data-toolbar-overflow-priority="35"]'
  const filtersItem = '[data-toolbar-overflow-priority="70"]'
  const viewSwitchItem = '[data-toolbar-overflow-priority="50"]'
  const groupByItem = '[data-toolbar-overflow-priority="40"]'

  it('moves the secondary controls into the ⋯ menu and back, never duplicating them', () => {
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(columnsItem).should('have.length', 1)
    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(overflow).should('have.class', 'hidden')

    cy.viewport(375, 667)

    cy.get(`${menu} ${columnsItem}`).should('have.length', 1)
    cy.get(`${menu} ${groupByItem}`).should('have.length', 1)
    // MOVED, not duplicated: two column selectors would be two controllers over one table.
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('not.have.class', 'hidden')

    // Search/filters and the view switch stay in the row: the switch SHRINKS.
    cy.get(`${menu} ${filtersItem}`).should('not.exist')
    cy.get(`${menu} ${viewSwitchItem}`).should('not.exist')

    cy.viewport(1440, 800)

    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('have.class', 'hidden')
  })

  it('restores the toolbar ordered by priority after a round trip', () => {
    // `expand()` reorders instead of remembering the original position: that is what makes the
    // controller stateless across a Turbo reconnect. It is also the only real test of the row's
    // order: the served HTML looks right even when the browser reorders it wrong.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')
    cy.viewport(1440, 800)

    const sortedDescending = (selector) =>
      cy.get(`${selector} > [data-toolbar-overflow-target="item"]`).then(($items) => {
        const priorities = [...$items].map((el) => Number(el.dataset.toolbarOverflowPriority))
        expect(priorities).to.deep.equal([...priorities].sort((a, b) => b - a))
      })

    // Search/filters · group by · columns
    sortedDescending(leftGroup)
    // Saved views · persistence marker
    sortedDescending(memoryGroup)
  })

  it('hides the separator when the overflow empties one of its sides, and brings it back', () => {
    // The separator ASSERTS something about its neighbors: with the memory group inside the ⋯ it
    // is left marking a boundary against nothing.
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(separator).should('be.visible')

    cy.viewport(375, 667)

    cy.get(separator).should('not.be.visible')
    cy.get(memoryGroup).should('not.be.visible')

    cy.viewport(1440, 800)

    cy.get(separator).should('be.visible')
    cy.get(memoryGroup).should('be.visible')
  })

  it('never moves the separator into the ⋯', () => {
    // Not an `item`: `collapsibleItems` cannot see it, so it can neither travel into the menu
    // nor be duplicated.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    cy.get(`${menu} ${separator}`).should('not.exist')
    cy.get(separator).should('have.length', 1)
  })

  it('keeps the column selector working after being moved', () => {
    // The real test that `connect()` is idempotent: moving it fires disconnect+connect.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    // Direct child: inside the ⋯ there are more triggers with role="button" (the controls that
    // have just moved there).
    cy.get(`${overflow} > .dropdown > [role="button"]`).click()
    cy.get(`${menu} [data-controller~="column-selector"] input[data-column-index="2"]`)
      .uncheck({ force: true })

    cy.get('.data-table-component table thead th').eq(2).should('not.be.visible')
  })

  it('closes an open dropdown before folding it into the ⋯', () => {
    // `.dropdown-open` SURVIVES the move: without closing it first, the control lands open
    // inside the menu. It is only reachable by keyboard — the other toolbar dropdowns open
    // through daisyUI's :focus-within and never set the class.
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    // `force`: daisyUI sets pointer-events:none on the trigger of an open dropdown (:focus-within
    // already opened it), and a keydown does not need mouse actionability.
    cy.get(`${groupByItem} [data-dropdown-target="trigger"]`)
      .focus()
      .trigger('keydown', { key: 'ArrowDown', force: true })
    cy.get(`${groupByItem} .dropdown-open`).should('have.length', 1)

    cy.viewport(375, 667)

    cy.get(`${menu} ${groupByItem}`).should('have.length', 1)
    cy.get(`${menu} .dropdown-open`).should('not.exist')
  })

  it('keeps keyboard focus on the toolbar when the breakpoint is crossed', () => {
    // A 400% zoom leaves the viewport at 320px CSS: crossing the threshold cannot cost a keyboard
    // user their position. `closeOpenDropdowns` blurs and the collapse moves the node, so without
    // restoring focus it falls to <body>.
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(`${filtersItem} button[data-action*="toggleDropdown"]`).first().focus()
    cy.viewport(375, 667)

    cy.focused().should('exist')
    cy.document().its('activeElement.tagName').should('not.equal', 'BODY')
  })

  it('keeps keyboard focus when the breakpoint is crossed the OTHER way', () => {
    // The mirror of the case above, and the one that was missing: when narrow, the ⋯ is the only
    // way to reach what collapsed, so that is where the user is standing. On widening, the ⋯
    // hides — and it is not an `item`, so it was not covered by the focus restoration.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    // The ⋯ IS a dropdown AND CONTAINS dropdowns: when narrow, the overflow puts Columns and
    // Views inside it, and those bring their own trigger. The bare descendant matched all three
    // and `cy.focus()` does not accept more than one element. The ⋯'s own is the one that does
    // NOT live inside the menu.
    cy.get(`${overflow} [data-dropdown-target="trigger"]`)
      .not(`${menu} [data-dropdown-target="trigger"]`)
      .focus()
    cy.focused().should('have.attr', 'aria-label')

    cy.viewport(1440, 800)

    cy.get(overflow).should('have.class', 'hidden')
    cy.document().its('activeElement.tagName').should('not.equal', 'BODY')
    // It lands on a control of the row, not just anywhere in the document.
    cy.focused().closest('[data-toolbar-overflow-target="item"]').should('have.length', 1)
  })

  it('does not render the ⋯ when there is nothing to collapse', () => {
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/default')

    cy.get(filtersItem).should('exist')
    cy.get(overflow).should('not.exist')
  })
})

// The ⋯ valve was evaluated ONLY on mount and when the container width changed, and neither of
// the two covers the real case: the controls grow AFTER the first layout. SlimSelect replaces
// its `<select>` with a wider widget, flatpickr mounts its own, a font finishes loading — and
// the row overflows without anything measuring again.
//
// It cannot be provoked with `cy.viewport()`: that changes the available width, which is exactly
// the signal the controller already listened to. What widens here is a CONTROL, with the viewport
// still — the same shape the real case has.
describe('DataTable toolbar overflow when a control grows after mount', () => {
  const menu = '[data-toolbar-overflow-target="menu"]'
  const overflow = '[data-toolbar-overflow-target="overflow"]'
  const filtersItem = '[data-toolbar-overflow-priority="70"]'

  it('collapses into the ⋯ when a control widens with the viewport unchanged', () => {
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(overflow).should('have.class', 'hidden')
    cy.get(menu).children().should('have.length', 0)

    // A control widens on its own, the way SlimSelect would when it mounts.
    cy.get(filtersItem).then(($item) => {
      $item[0].style.minWidth = `${$item[0].getBoundingClientRect().width + 600}px`
    })

    cy.get(overflow).should('not.have.class', 'hidden')
    cy.get(menu).children().should('have.length.greaterThan', 0)

    // And it reverts on its own once the control recovers its size.
    cy.get(filtersItem).then(($item) => { $item[0].style.minWidth = '' })

    cy.get(overflow).should('have.class', 'hidden')
    cy.get(menu).children().should('have.length', 0)
  })
})
