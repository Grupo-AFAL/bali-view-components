// `app_layout/with_topbar` is the app shell's reference configuration: a fixed sidebar as THE
// navigation + Bali::Topbar as the account bar over the content column. What is guarded here is
// that it stays ONE strip of chrome, that it does not repeat destinations, and that on mobile the
// sidebar still opens from the Topbar's own hamburger.
describe('AppLayout with_topbar: the chrome strip', () => {
  const atDesktopWidth = () => {
    cy.viewport(1440, 900)
    cy.visit('/bali/app_layout/with_topbar')
    cy.get('.bali-topbar').should('be.visible')
  }

  it('does not repeat in the topbar the destinations the sidebar already carries', () => {
    atDesktopWidth()

    const inSidebar = ['Dashboard', 'Movies', 'Studios']
    cy.get('.side-menu-component a').then($sidebar => {
      const names = [...$sidebar].map(a => a.textContent.trim())
      inSidebar.forEach(n => expect(names, `${n} lives in the sidebar`).to.include(n))
    })

    cy.get('.bali-topbar a').then($top => {
      const names = [...$top].map(a => a.textContent.trim())
      inSidebar.forEach(n =>
        expect(names, `${n} is not repeated in the topbar`).to.not.include(n)
      )
    })
  })

  it('is a header/banner with a single nav on the page: the sidebar one', () => {
    atDesktopWidth()

    // Topbar and not Navbar on purpose: with the sidebar carrying the destinations, the top
    // strip is chrome (banner), not a second empty navigation landmark.
    cy.get('header.bali-topbar').should('exist')
    cy.get('.bali-topbar nav').should('not.exist')
    cy.get('nav.side-menu-component').should('exist')
  })

  it('places the command palette on the left, filled, not bordered', () => {
    atDesktopWidth()

    cy.get('[data-controller="command"] .bali-command-trigger').should($t => {
      const box = $t[0].getBoundingClientRect()
      const account = $t[0].ownerDocument
        .querySelector('.bali-topbar [aria-label="Notifications"]')
        .getBoundingClientRect()

      expect(box.left, 'to the left of the account controls').to.be.lessThan(account.left)
      // The default trigger is a well, not a .btn: painted fill and ZERO border of its
      // own — with a border, the focus-visible outline left behind when the palette is
      // closed with Escape read as a double border.
      expect($t[0].className, 'a well, not a button').to.not.match(/\bbtn\b/)
      const style = window.getComputedStyle($t[0])
      expect(style.borderTopWidth, 'no border of its own').to.eq('0px')
      expect(style.backgroundColor, 'and the fill is painted').to.not.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })
  })

  it('returns focus to the trigger with a single ring when the palette is closed with Escape', () => {
    atDesktopWidth()

    cy.get('.bali-command-trigger').click()
    cy.get('[data-command-target="input"]').should('be.focused').type('{esc}')

    // The scenario that motivated the well: Escape returns focus to the trigger, and there
    // the focus-visible ring has to be the ONLY ring (own border 0px).
    cy.get('.bali-command-trigger').should($t => {
      expect($t[0].ownerDocument.activeElement, 'focus returned to the trigger').to.eq($t[0])
      const style = window.getComputedStyle($t[0])
      expect(style.borderTopWidth, 'no border of its own').to.eq('0px')
      expect(parseFloat(style.outlineWidth), 'with the design system ring').to.be.greaterThan(0)
      expect(style.outlineStyle).to.not.eq('none')
    })
  })

  it('leaves the breadcrumbs on the page background, outside the Topbar', () => {
    atDesktopWidth()

    cy.get('.bali-topbar .breadcrumbs').should('not.exist')
    cy.get('.breadcrumbs').should($bc => {
      const background = window.getComputedStyle($bc[0].parentElement).backgroundColor
      expect(background, 'no background of its own').to.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })

    // Above the title and inside the body, not in the chrome strip.
    cy.get('main .breadcrumbs').should('exist')
    cy.get('.breadcrumbs').then($bc => {
      cy.get('.page-header-component .title').then($t => {
        expect($bc[0].getBoundingClientRect().bottom).to.be.at.most(
          $t[0].getBoundingClientRect().top
        )
      })
    })
  })

  // With a real Topbar in the slot, AppLayout's default mobile row
  // (`fixed_sidebar? && !topbar?`) is NOT rendered: the hamburger that opens the
  // sidebar on a phone is the Topbar's own (lg:hidden).
  it('keeps the sidebar trigger on mobile, inside the Topbar', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/app_layout/with_topbar')

    cy.get('.app-layout-topbar--default-mobile').should('not.exist')
    cy.get('.bali-topbar [data-controller~="side-menu-trigger"]').should('be.visible')
  })
})
