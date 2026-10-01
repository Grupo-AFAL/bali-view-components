// The UserMenu's dark-mode switch end to end: the click flips <html data-theme> in place and
// writes the cookie, and the server reads that cookie back through `bali_theme` to paint the
// next page already dark. The dummy declares `Bali.themes = { light: "light", dark: "dark" }`
// and its preview layout fills `<html data-theme>` with `bali_theme`.
describe('Topbar::UserMenu dark-mode switch', () => {
  const userMenu = '.bali-topbar-user-menu'
  const trigger = '[data-dropdown-target="trigger"]'
  const menu = '[data-dropdown-target="menu"]'
  const toggle = '[role="menuitemcheckbox"][data-controller="theme-toggle"]'

  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })
  const theme = () => cy.document().its('documentElement').invoke('getAttribute', 'data-theme')
  const openMenu = () => cy.get(userMenu).first().find(trigger).click()

  beforeEach(() => {
    cy.clearCookies()
    cy.visit('/bali/topbar/user_menu')
  })

  it('switches to dark in place and keeps the menu open', () => {
    theme().should('equal', 'light')
    openMenu()
    cy.get(userMenu).first().find(toggle).should('have.attr', 'aria-checked', 'false').click()

    theme().should('equal', 'dark')
    cy.get(userMenu).first().find(toggle).should('have.attr', 'aria-checked', 'true')
    cy.get(userMenu).first().find(menu).should(($menu) => {
      expect(getComputedStyle($menu[0]).display).to.not.equal('none')
    })
  })

  it('remembers the choice in the cookie the server reads on the next page', () => {
    openMenu()
    cy.get(userMenu).first().find(toggle).click()
    cy.getCookie('bali_theme').should('have.property', 'value', 'dark')

    cy.reload()
    theme().should('equal', 'dark')
    cy.get(userMenu).first().find(toggle).should('have.attr', 'aria-checked', 'true')

    openMenu()
    cy.get(userMenu).first().find(toggle).click()
    cy.getCookie('bali_theme').should('have.property', 'value', 'light')
    cy.reload()
    theme().should('equal', 'light')
  })

  it('is reached with the arrow keys like any other item of the menu', () => {
    cy.get(userMenu).first().find(trigger).focus()
    press('ArrowDown')
    cy.focused().should('contain', 'Profile')
    press('ArrowDown')
    press('ArrowDown')
    cy.focused().should('have.attr', 'role', 'menuitemcheckbox').and('contain', 'Dark mode')
  })
})
