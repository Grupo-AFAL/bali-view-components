// The point of the merge: the SAME controller drives the menu in both modes. In popover
// mode the menu is moved into a tippy popper on `<body>`, so every "is this mine?" question
// the controller asks — `this.element.contains`, the nested-dropdown guard, the item list —
// has to look in two places. Before, popover mode rendered a HoverCard around a string copy
// of the list and had no keyboard at all.
describe('DropdownController', () => {
  const cssDropdown = '[data-dropdown-popover-value="false"]'
  const popoverDropdown = '[data-dropdown-popover-value="true"]'
  const trigger = '[data-dropdown-target="trigger"]'
  const menu = '[data-dropdown-target="menu"]'

  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })

  context('CSS mode', () => {
    beforeEach(() => {
      cy.visit('/bali/dropdown/basic')
    })

    it('reports aria-expanded from what is on screen, not from the keyboard path', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')

      // Focusing the trigger is how daisyUI opens it — no controller method runs.
      cy.get('@t').focus()
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')
      cy.get(cssDropdown).first().find(menu).should('be.visible')
    })

    it('walks the items with the arrow keys', () => {
      cy.get(cssDropdown).first().find(trigger).focus()

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Item 1')

      press('ArrowDown')
      cy.focused().should('contain', 'Item 2')

      press('ArrowUp')
      cy.focused().should('contain', 'Item 1')
    })

    // Escape used to close the menu and then hand focus back to the trigger, which
    // re-opened it on the same frame through daisyUI's `:focus-within`. daisyUI's own
    // `.dropdown-close` is what makes the close stick without blurring the reader out.
    it('closes on Escape, keeps the focus on the trigger, and stays closed', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()
      press('ArrowDown')
      cy.focused().should('contain', 'Item 1')

      press('Escape')

      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
      cy.get(cssDropdown).first().find(menu).should('not.be.visible')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    it('reopens with ArrowDown after an Escape', () => {
      cy.get(cssDropdown).first().find(trigger).focus()
      press('Escape')
      press('ArrowDown')

      cy.focused().should('contain', 'Item 1')
      cy.get(cssDropdown).first().find(trigger).should('have.attr', 'aria-expanded', 'true')
    })

    // A hover dropdown was the one shape with no controller at all, so its trigger reported
    // "collapsed" with the menu on screen and no key did anything.
    it('gives a hoverable dropdown the same keyboard', () => {
      cy.get('.dropdown-hover').find(trigger).as('t')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')

      cy.get('@t').focus()
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem')
    })
  })

  context('popover mode', () => {
    beforeEach(() => {
      cy.visit('/bali/dropdown/basic')
      // tippy is a dynamic import; the menu leaves the wrapper once it resolves.
      cy.get(popoverDropdown).find(menu).should('not.exist')
    })

    it('moves the rendered menu rather than copying it', () => {
      cy.get(`[data-tippy-root] ${menu}`).should('have.length', 0)
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]').find(menu).should('exist')
      // One menu on the page, not an original plus a copy.
      cy.get(menu).filter(':visible').should('have.length', 1)
      cy.get(popoverDropdown).find(menu).should('not.exist')
    })

    it('keeps the menu semantics it was rendered with', () => {
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]')
        .find('[role="menu"]')
        .should('have.attr', 'aria-label', 'Dropdown menu')
      cy.get('[data-tippy-root]').find('[role="menuitem"]').should('have.length.at.least', 2)
    })

    it('syncs aria-expanded with the popper', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')

      cy.get('@t').click()
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      // Not a second click on the trigger: the open panel covers it, which is exactly what
      // Cypress's actionability check is for. A click anywhere else is the way out.
      cy.get('body').click(5, 5)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.get('[data-tippy-root]').should('not.exist')
    })

    it('opens with ArrowDown and walks the items inside the popper', () => {
      cy.get(popoverDropdown).find(trigger).focus()

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')

      press('ArrowDown')
      cy.focused().should('contain', 'Export')

      press('ArrowUp')
      cy.focused().should('contain', 'Edit')
    })

    it('closes on Escape from inside the popper and returns the focus to the trigger', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').focus()
      press('ArrowDown')
      cy.focused().should('contain', 'Edit')

      press('Escape')

      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.get('[data-tippy-root]').should('not.exist')
    })

    // The whole reason `popover:` exists. `overflow-x-auto` clips on both axes — CSS turns
    // the other one into `auto` as soon as one of them is not `visible` — so a menu taller
    // than its row is cut off in the flow.
    it('escapes the clipping ancestor', () => {
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]').should(($popper) => {
        expect($popper[0].parentElement.tagName).to.eq('BODY')
      })

      cy.get(popoverDropdown).closest('.overflow-x-auto').then(($box) => {
        cy.get('[data-tippy-root]').should(($popper) => {
          const popper = $popper[0].getBoundingClientRect()
          const box = $box[0].getBoundingClientRect()
          const contained = popper.top >= box.top && popper.bottom <= box.bottom &&
                            popper.left >= box.left && popper.right <= box.right
          expect(contained, 'menu rect fits inside the scroll box').to.eq(false)
        })
      })
    })
  })
})
