describe('SideMenuComponent', () => {
  // Use a desktop-width viewport so the `lg:` breakpoint applies and the
  // collapse toggle button (hidden on mobile via `max-lg:!hidden`) is visible.
  beforeEach(() => {
    cy.viewport(1280, 800)
  })

  // Click the label tied to the (randomly-IDed) collapse-trigger checkbox.
  // There are two labels — one inside `.side-menu-expanded`, one inside
  // `.side-menu-collapsed` — only one is visible at a time, so pick that one.
  const clickCollapseToggle = () => {
    cy.get('input.side-menu-collapse-trigger')
      .invoke('attr', 'id')
      .then(id => cy.get(`label[for="${id}"]`).filter(':visible').first().click())
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
    })

    it('starts expanded — the collapse-trigger checkbox is unchecked', () => {
      cy.get('input.side-menu-collapse-trigger').should('not.be.checked')
      cy.get('.side-menu-component').should('not.have.class', 'is-collapsed')
    })

    it('flips the checkbox when the collapse toggle is clicked', () => {
      clickCollapseToggle()
      cy.get('input.side-menu-collapse-trigger').should('be.checked')
    })

    it('returns to expanded when toggled again', () => {
      clickCollapseToggle()
      cy.get('input.side-menu-collapse-trigger').should('be.checked')

      clickCollapseToggle()
      cy.get('input.side-menu-collapse-trigger').should('not.be.checked')
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

  context('expandable groups on mobile', () => {
    // The mobile override (max-width: 1023.98px) forces the sidebar to
    // expanded width and hides `.side-menu-collapsed` markup, so the new
    // collapsed-state flyout never appears on mobile. Users get the
    // accordion instead — tapping a parent expands children inline.
    beforeEach(() => {
      cy.viewport('iphone-x') // 375 x 812
      cy.visit('/bali/side_menu/collapsible')
      cy.get('.side-menu-component', { timeout: 5000 }).should('exist')
      // Open the sidebar by checking the mobile-trigger (no hamburger in
      // the preview chrome, so we trip the checkbox directly).
      cy.get('input.side-menu-mobile-trigger').check({ force: true })
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
