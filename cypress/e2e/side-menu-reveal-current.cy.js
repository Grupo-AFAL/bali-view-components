// #1099 — Every navigation re-renders the sidebar and its scroll goes back to the top. In a
// menu taller than the screen that leaves the active item out of view: you land on a page and
// the menu does not show you where you are.
//
// The preview clips the menu to 380 px with 18 entries and the current page
// (`/reports/audit-log`) near the end, which is the only way to see the behaviour: in a menu
// that fits on screen there is nothing to reveal.
const PREVIEW = '/bali/side_menu/reveal_current'
const MENU = '.sidebar-menu'
const CURRENT = '.side-menu-expanded[aria-current="page"]'

describe('SideMenu reveal current item', () => {
  it('opens already scrolled to the item for the current page', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
    cy.get(CURRENT).should('be.visible')
  })

  // Really visible and not just "in the DOM": the item has to land INSIDE the menu's box,
  // which is what was failing. Cypress' `should('be.visible')` does not tell them apart.
  it('leaves the current item inside the menu box', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).then(($menu) => {
      const menuRect = $menu[0].getBoundingClientRect()

      cy.get(CURRENT).then(($item) => {
        const itemRect = $item[0].getBoundingClientRect()

        expect(itemRect.top).to.be.at.least(menuRect.top)
        expect(itemRect.bottom).to.be.at.most(menuRect.bottom)
      })
    })
  })

  it('does nothing when the option is off', () => {
    cy.visit(`${PREVIEW}?reveal_current=false`)

    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })

  // Only moves the menu's own scroll. `scrollIntoView` would also have moved whatever
  // ancestors it needed, up to the document.
  it('never scrolls the page', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
    cy.window().its('scrollY').should('equal', 0)
  })

  // The visibility guard: without it the menu would jump on every load of a page whose item
  // is already in view.
  it('stays put when the current item is already in view', () => {
    cy.visit('/bali/side_menu/default')

    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })
})

// The other case the issue left open: a closed mobile drawer is `inert` and translated off
// screen, so measuring it on `connect` would spend the scroll on a panel nobody is looking
// at. The reveal waits for `open()`.
describe('SideMenu reveal current item — mobile drawer', () => {
  const FIXED = `${PREVIEW}?fixed=true`

  beforeEach(() => cy.viewport(390, 700))

  it('does not spend the reveal while the drawer is closed', () => {
    cy.visit(FIXED)

    cy.get('.side-menu-component').should('have.attr', 'inert')
    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })

  it('reveals the current item when the drawer opens', () => {
    cy.visit(FIXED)

    cy.get('[data-controller~="side-menu-trigger"]').first().click()

    cy.get('.side-menu-component').should('have.class', 'is-active')
    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
  })
})
