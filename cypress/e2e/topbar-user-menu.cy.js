// Bali::Topbar::UserMenu is a preset of Bali::Dropdown, so the point of this file is not
// to re-test the menu mechanics (dropdown-controller.cy.js owns those) but to prove the
// preset actually inherits them — the hand-rolled `<details class="dropdown">` it replaces
// had no keyboard, no Escape and no aria-expanded at all — plus the two pieces the preset
// adds: the presentational identity header and the sign-out `button_to` form.
describe('Topbar::UserMenu', () => {
  const userMenu = '.bali-topbar-user-menu'
  const trigger = '[data-dropdown-target="trigger"]'
  const menu = '[data-dropdown-target="menu"]'

  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })

  beforeEach(() => {
    cy.visit('/bali/topbar/user_menu')
  })

  it('inherits the dropdown keyboard: open, arrows over menuitems only, Escape', () => {
    cy.get(userMenu).first().find(trigger).as('t')
    cy.get('@t').should('have.attr', 'aria-expanded', 'false')

    cy.get('@t').focus()
    cy.get('@t').should('have.attr', 'aria-expanded', 'true')
    cy.get(userMenu).first().find(menu).should('be.visible')

    // The name/email header is role="presentation": the first ArrowDown must land on
    // the first actionable item, not on the identity block.
    press('ArrowDown')
    cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Profile')

    press('Escape')
    cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
    cy.get(userMenu).first().find(menu).should('not.be.visible')
    cy.get('@t').should('have.attr', 'aria-expanded', 'false')
  })

  it('shows the identity header outside the menuitem list', () => {
    cy.get(userMenu).first().within(() => {
      cy.get('.bali-topbar-user-menu-header')
        .should('have.attr', 'role', 'presentation')
        .and('contain', 'Ana García López')
        .and('contain', 'ana@example.com')
    })
  })

  it('renders sign out as a real delete form, reachable with the arrows', () => {
    cy.get(userMenu).first().within(() => {
      cy.get('form input[name="_method"]').should('have.value', 'delete')
      cy.get('form button.bali-topbar-sign-out[role="menuitem"]').should('contain', 'Sign out')
    })

    cy.get(userMenu).first().find(trigger).focus()
    press('ArrowUp') // wraps to the last item, which must be sign out
    cy.focused().should('have.class', 'bali-topbar-sign-out')
  })

  it('renders no sign-out item when `sign_out:` was not given', () => {
    cy.get(userMenu).eq(2).within(() => {
      cy.get('.bali-topbar-sign-out').should('not.exist')
      cy.get('form').should('not.exist')
    })
  })
})
