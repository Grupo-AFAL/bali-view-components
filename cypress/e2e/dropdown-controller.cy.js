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
  const release = (key) => cy.focused().trigger('keyup', { key, bubbles: true, force: true })

  // `display` and not `not.be.visible`: Cypress counts a menu fading in from daisyUI's
  // `@starting-style` `opacity: 0` as hidden, and measured, that assertion passed on an open one.
  const expectClosed = ($menu) => {
    expect($menu[0].ownerDocument.defaultView.getComputedStyle($menu[0]).display).to.equal('none')
  }

  context('CSS mode', () => {
    beforeEach(() => {
      cy.visit('/bali/dropdown/basic')
    })

    // #1231: daisyUI opens the CSS dropdown from `:focus-within`, so Tab alone unfolded it and
    // the Enter meant to open it closed it.
    it('does not open on focus', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()

      cy.get(cssDropdown).first().find(menu).should(expectClosed)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    it('opens on Enter and moves the focus to the first item', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()

      press('Enter')

      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Item 1')
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')
    })

    // A `<button>` item answers a Space keyup with a click, and opened on the keydown the
    // menu had already moved the focus onto its first item when the keyup landed.
    it('opens on the Space keyup, not on the keydown', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()

      press(' ')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')

      release(' ')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Item 1')
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')
    })

    // The second click lands on the wrapper: daisyUI gives an open trigger
    // `pointer-events: none`. Clicked through Cypress's hit test, not forced onto the trigger.
    it('opens on a click and closes on a second one, keeping the focus on the trigger', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').find(trigger).as('t')

      cy.get('@t').click()
      cy.get('@dropdown').find(menu).should('be.visible')
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      cy.get('@dropdown').click('topLeft')
      cy.get('@dropdown').find(menu).should(expectClosed)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
    })

    // A Turbo morph that rewrites `class` takes `dropdown-close` away with everything else, and
    // read as "open" by `:focus-within`, the first click closed a menu nobody could see.
    it('opens on the first click after its classes are rewritten', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').then(($d) => $d[0].classList.remove('dropdown-close'))

      cy.get('@dropdown').find(trigger).click()

      cy.get('@dropdown').find(trigger).should('have.attr', 'aria-expanded', 'true')
      cy.get('@dropdown').should('have.class', 'dropdown-open')
    })

    // With `:focus-within` the menu was open from the `mousedown`, and the rich text editor's
    // link panel focuses its input from a click action on the trigger.
    it('is open by the time a click action on the trigger runs', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').find(trigger).then(($t) => {
        const panel = $t[0].parentElement.querySelector(menu)
        $t[0].addEventListener('click', () => {
          $t[0].dataset.menuDisplay = $t[0].ownerDocument.defaultView.getComputedStyle(panel).display
        })
      })

      cy.get('@dropdown').find(trigger).click()

      cy.get('@dropdown').find(trigger).should(($t) => {
        expect($t[0].dataset.menuDisplay, 'menu display seen by the click action')
          .to.exist.and.not.equal('none')
      })
    })

    it('closes when the focus leaves it', () => {
      cy.get(cssDropdown).first().find(trigger).focus()
      press('Enter')
      cy.focused().should('contain', 'Item 1')

      cy.get('.dropdown-hover').find(trigger).focus()

      cy.get(cssDropdown).first().find(menu).should(expectClosed)
      cy.get(cssDropdown).first().find(trigger).should('have.attr', 'aria-expanded', 'false')
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

    // Enter sets `dropdown-open` on a hover dropdown too, and leaving it only dropped
    // `dropdown-close`, so the menu stayed open behind the reader.
    it('closes a hoverable dropdown opened with Enter once the focus leaves it', () => {
      cy.get('.dropdown-hover').find(trigger).focus()
      press('Enter')
      cy.focused().should('have.attr', 'role', 'menuitem')

      cy.get(cssDropdown).first().find(trigger).focus()

      cy.get('.dropdown-hover').find(menu).should(expectClosed)
      cy.get('.dropdown-hover').find(trigger).should('have.attr', 'aria-expanded', 'false')
    })
  })

  // /z-stack renders a dropdown with `class: 'dropdown-open'`, to show every overlay at once.
  context('rendered open by the server', () => {
    it('stays open', () => {
      cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/z-stack`)

      cy.get(`#probe-dropdown-wrap ${trigger}`).should('have.attr', 'aria-expanded', 'true')
      cy.get(`#probe-dropdown-wrap ${menu}`).should(($menu) => {
        expect($menu[0].ownerDocument.defaultView.getComputedStyle($menu[0]).display)
          .to.not.equal('none')
      })
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

    it('opens on Enter and on the Space keyup with the focus on the first item', () => {
      cy.get(popoverDropdown).find(trigger).focus()
      press('Enter')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')

      press('Escape')
      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')

      press(' ')
      release(' ')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')
    })

    // Focus-out was not listened to in popover mode, so Tab away left the popper up.
    it('closes when the focus leaves it', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').focus()
      press('Enter')
      cy.focused().should('contain', 'Edit')

      cy.get(cssDropdown).first().find(trigger).focus()

      cy.get('[data-tippy-root]').should('not.exist')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    // Same wrapper press as in the CSS mode: with focus-out now closing the popper, a blur on
    // that press closed it and the click reopened it.
    it('closes on a second click on its trigger', () => {
      cy.get(popoverDropdown).as('dropdown')
      cy.get('@dropdown').find(trigger).click()
      cy.get('[data-tippy-root]').should('exist')

      cy.get('@dropdown').click('topLeft')

      cy.get('[data-tippy-root]').should('not.exist')
      cy.get('@dropdown').find(trigger).should('have.attr', 'aria-expanded', 'false')
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

  // #1231: daisyUI anchors the panel to one edge of the trigger and never looks at the screen.
  // The page ⋯ is `align: :end`; below `sm` its row wraps and the trigger lands at the left of
  // it (IndexPage) or mid-row (ShowPage, after three actions), where its w-80 menu opened at
  // x = −216 and x = −120.
  context('inside the viewport', () => {
    const pageMenu = '[data-controller~="export-links"]'

    // 5px from each edge, less half a pixel for subpixel layout.
    const expectOnScreen = ($menu) => {
      expect($menu[0].getAnimations({ subtree: true })).to.have.length(0)
      const { left, right } = $menu[0].getBoundingClientRect()
      const width = $menu[0].ownerDocument.documentElement.clientWidth
      expect(left, 'left edge').to.be.at.least(4.5)
      expect(right, 'right edge').to.be.at.most(width - 4.5)
    }

    ;[390, 1280].forEach((width) => {
      context(`at ${width}px`, () => {
        beforeEach(() => cy.viewport(width, 800))

        ;[
          ['/bali/index_page/with_secondary_actions', 'IndexPage'],
          ['/bali/show_page/with_secondary_actions', 'ShowPage']
        ].forEach(([path, page]) => {
          it(`opens the ${page} ⋯ menu on screen`, () => {
            cy.visit(path)
            cy.get(`${pageMenu} ${trigger}`).click()

            cy.get(`${pageMenu} ${menu}`).should('be.visible').and(expectOnScreen)
          })
        })

        ;['#viewport-edge-end', '#viewport-edge-start'].forEach((dropdown) => {
          it(`opens ${dropdown} on screen`, () => {
            cy.visit('/bali/dropdown/alignments')
            cy.get(`${dropdown} ${trigger}`).click()

            cy.get(`${dropdown} ${menu}`).should('be.visible').and(expectOnScreen)
          })
        })
      })
    })
  })
})
