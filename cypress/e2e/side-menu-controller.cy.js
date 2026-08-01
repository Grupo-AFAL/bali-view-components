describe('SideMenuComponent', () => {
  // Use a desktop-width viewport so the `lg:` breakpoint applies and the
  // collapse toggle button (hidden on mobile via `max-lg:hidden`) is visible.
  beforeEach(() => {
    cy.viewport(1280, 800)
  })

  // Only one of the two collapse toggles is displayed at a time — the expanded
  // header carries one, the collapsed rail the other.
  const clickCollapseToggle = () => {
    cy.get('button[data-action="side-menu#toggleCollapse"]')
      .filter(':visible')
      .first()
      .click()
  }

  context('menu_switcher (details/summary)', () => {
    beforeEach(() => {
      cy.visit('/bali/side_menu/with_menu_switcher')
      cy.get('.menu-switcher details').should('exist')
    })

    it('starts closed', () => {
      cy.get('.menu-switcher details').should('not.have.attr', 'open')
    })

    it('opens when the summary is clicked', () => {
      cy.get('.menu-switcher details summary').click()
      cy.get('.menu-switcher details').should('have.attr', 'open')
      cy.get('.menu-switcher .dropdown-content').should('be.visible')
    })

    it('closes when the summary is clicked a second time', () => {
      cy.get('.menu-switcher details summary').click()
      cy.get('.menu-switcher details summary').click()
      cy.get('.menu-switcher details').should('not.have.attr', 'open')
    })

    it('shows every authorized menu in the dropdown', () => {
      cy.get('.menu-switcher details summary').click()

      cy.get('.menu-switcher .dropdown-content li')
        .should('have.length.at.least', 3)
        .and('contain', 'Logistics')
        .and('contain', 'Accounting')
    })
  })

  context('collapsible state', () => {
    beforeEach(() => {
      cy.visit('/bali/side_menu/collapsible')
      cy.get('.side-menu-component', { timeout: 5000 }).should('exist')
      cy.clearLocalStorage()
    })

    it('starts expanded', () => {
      cy.get('.side-menu-component').should('not.have.class', 'is-collapsed')
    })

    it('collapses to the icon rail when the toggle is clicked', () => {
      clickCollapseToggle()
      cy.get('.side-menu-component').should('have.class', 'is-collapsed')
    })

    it('returns to expanded when toggled again', () => {
      clickCollapseToggle()
      cy.get('.side-menu-component').should('have.class', 'is-collapsed')

      clickCollapseToggle()
      cy.get('.side-menu-component').should('not.have.class', 'is-collapsed')
    })

    it('persists the collapsed state in localStorage', () => {
      clickCollapseToggle()
      cy.window().then(win => {
        expect(win.localStorage.getItem('bali_sideMenuCollapsed')).to.eq('true')
      })
    })

    it('has no hidden checkbox left driving the collapse', () => {
      cy.get('input.side-menu-collapse-trigger').should('not.exist')
      cy.get('input.side-menu-mobile-trigger').should('not.exist')
    })
  })

  context('menu_switcher when the sidebar is collapsed', () => {
    beforeEach(() => {
      cy.visit('/bali/side_menu/with_menu_switcher')
      cy.get('.menu-switcher').should('exist')
    })

    it('keeps the menu_switcher trigger visible after collapsing the sidebar', () => {
      // The with_menu_switcher preview does not include the collapse trigger,
      // so toggle the wrapper class directly to simulate the collapsed state.
      cy.get('.side-menu-component').then($el => $el.addClass('is-collapsed'))

      cy.get('.menu-switcher-trigger').should('be.visible')
    })

    it('opens the dropdown beside the collapsed sidebar when clicked', () => {
      cy.get('.side-menu-component').then($el => $el.addClass('is-collapsed'))

      cy.get('.menu-switcher details summary').click()
      cy.get('.menu-switcher details').should('have.attr', 'open')
      cy.get('.menu-switcher .dropdown-content').should('be.visible')
    })
  })

  context('mobile drawer', () => {
    const trigger = () =>
      cy.get('button[data-controller~="side-menu-trigger"]').filter(':visible').first()

    beforeEach(() => {
      cy.viewport('iphone-x') // 375 x 812
      cy.visit('/bali/side_menu/with_trigger')
      cy.get('.side-menu-component', { timeout: 5000 }).should('exist')
    })

    it('starts closed and out of the tab order', () => {
      cy.get('.side-menu-component').should('not.have.class', 'is-active')
      // `inert` is what takes the closed drawer's links out of the tab order —
      // `translateX(-100%)` alone left them focusable.
      cy.get('.side-menu-component').should('have.attr', 'inert')
      cy.get('.side-menu-component a[href]').each($el => {
        expect($el[0].closest('[inert]')).to.not.equal(null)
      })
    })

    it('drops inert once the drawer is open and restores it on close', () => {
      trigger().click()
      cy.get('.side-menu-component').should('not.have.attr', 'inert')

      cy.get('body').type('{esc}')
      cy.get('.side-menu-component').should('have.attr', 'inert')
    })

    it('the trigger is a real button, not a label for a hidden checkbox', () => {
      trigger().should('match', 'button[type="button"]')
      cy.get('input[type="checkbox"].side-menu-mobile-trigger').should('not.exist')
    })

    it('opens the drawer and reports it on aria-expanded', () => {
      trigger().should('have.attr', 'aria-expanded', 'false')
      trigger().click()

      cy.get('.side-menu-component').should('have.class', 'is-active')
      cy.get('.side-menu-component').should('have.css', 'visibility', 'visible')
      trigger().should('have.attr', 'aria-expanded', 'true')
    })

    it('points aria-controls at the sidebar it opens', () => {
      trigger()
        .invoke('attr', 'aria-controls')
        .then(id => cy.get(`nav#${id}`).should('have.class', 'side-menu-component'))
    })

    it('moves focus into the drawer when it opens', () => {
      trigger().click()
      cy.focused().should($el => {
        expect($el.closest('.side-menu-component')).to.have.length(1)
      })
    })

    it('closes on Escape and returns focus to the trigger', () => {
      trigger().click()
      cy.get('.side-menu-component').should('have.class', 'is-active')

      cy.get('body').type('{esc}')

      cy.get('.side-menu-component').should('not.have.class', 'is-active')
      trigger().should('have.attr', 'aria-expanded', 'false')
      cy.focused().should('have.attr', 'data-controller').and('contain', 'side-menu-trigger')
    })

    it('closes when the scrim is clicked', () => {
      trigger().click()
      cy.get('.side-menu-overlay').click({ force: true })
      cy.get('.side-menu-component').should('not.have.class', 'is-active')
    })

    it('closes from the in-drawer close button', () => {
      trigger().click()
      cy.get('button[data-action="side-menu#close"]').filter(':visible').first().click()
      cy.get('.side-menu-component').should('not.have.class', 'is-active')
      trigger().should('have.attr', 'aria-expanded', 'false')
    })

    it('keeps Tab inside the drawer while it is open', () => {
      trigger().click()

      // Focus the last focusable item, then Tab forward: the controller wraps
      // back to the first instead of letting focus escape behind the scrim.
      cy.get('.side-menu-component')
        .find('a[href], button:not([disabled])')
        .filter(':visible')
        .last()
        .focus()

      cy.document().trigger('keydown', { key: 'Tab', bubbles: true })

      cy.focused().should($el => {
        expect($el.closest('.side-menu-component')).to.have.length(1)
      })
    })

    it('does not trap Tab once the drawer is closed', () => {
      cy.get('.side-menu-component').should('not.have.class', 'is-active')
      trigger().focus()
      cy.document().trigger('keydown', { key: 'Tab', bubbles: true })
      cy.focused().should('have.attr', 'data-controller').and('contain', 'side-menu-trigger')
    })
  })

  context('expandable groups on mobile', () => {
    // The mobile override (max-width: 1023.98px) forces the sidebar to
    // expanded width and hides `.side-menu-collapsed` markup, so the new
    // collapsed-state flyout never appears on mobile. Users get the
    // accordion instead — tapping a parent expands children inline.
    beforeEach(() => {
      cy.viewport('iphone-x') // 375 x 812
      cy.visit('/bali/side_menu/collapsible')
      cy.get('.side-menu-component', { timeout: 5000 }).should('exist')
      // No trigger in this preview's chrome, so open the drawer through the
      // same window event every trigger dispatches.
      cy.window().then(win => {
        win.dispatchEvent(new win.CustomEvent('bali:side-menu:open'))
      })
      cy.get('.side-menu-component').should('have.class', 'is-active')
    })

    it('hides the collapsed-state flyout markup', () => {
      // Markup exists in the DOM but the mobile override sets display:none.
      cy.get('.side-menu-collapsed-flyout').should('not.be.visible')
    })

    it('shows the expanded accordion for groups with children', () => {
      cy.contains('.side-menu-expanded', 'Projects').should('be.visible')
    })

    it('keeps child links in the DOM inside the accordion content', () => {
      // The accordion is the only path to children on mobile. Confirm
      // children render inside `.collapse-content` (the accordion's
      // expandable region) so users can reach them by opening it.
      cy.contains('.collapse', 'Projects')
        .find('.collapse-content a[href="/projects/active"]')
        .should('exist')
    })
  })
})
