// The UserMenu's dark-mode switch end to end: the click flips <html data-theme> in place and
// writes the cookie, and the server reads that cookie back through `bali_theme` to paint the
// next page already dark. The dummy declares `Bali.themes = { light: "light", dark: "dark" }`
// and its layouts fill `<html data-theme>` with `bali_theme`.
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
  })

  context('in a preview', () => {
    beforeEach(() => cy.visit('/bali/topbar/user_menu'))

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

    // The dummy's pair is named like the cookie's values; a host's is not. The theme painted is
    // the name the server handed over, the cookie keeps the word Bali::ThemeHelper reads.
    it('paints the theme it was handed and stores "dark" in the cookie', () => {
      cy.get(userMenu).first().find(toggle).invoke('attr', 'data-theme-toggle-dark-value', 'afal-dark')
      openMenu()
      cy.get(userMenu).first().find(toggle).click()

      theme().should('equal', 'afal-dark')
      cy.getCookie('bali_theme').should('have.property', 'value', 'dark')
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

  // A restoration visit paints the snapshot Turbo took before the theme changed, and Turbo
  // does not touch <html data-theme>: the switch has to read the page, not its old markup.
  context('Turbo restoration', () => {
    const appOrigin = new URL(Cypress.config('baseUrl')).origin

    // The mark only survives in Turbo's snapshot: a page fetched again would come back
    // without it, and already checked from the cookie.
    it('reports the theme the page has after going back', () => {
      cy.visit(`${appOrigin}/admin`)
      cy.window().then((win) => { win.notReloaded = true })
      cy.get(`${userMenu} ${toggle}`).invoke('attr', 'data-from-snapshot', '')

      cy.window().then((win) => win.Turbo.visit('/admin/settings'))
      cy.location('pathname').should('eq', '/admin/settings')
      cy.get(`${userMenu} ${trigger}`).click()
      cy.get(`${userMenu} ${toggle}`).click()
      theme().should('equal', 'dark')

      cy.go('back')
      cy.location('pathname').should('eq', '/admin')
      cy.window().its('notReloaded').should('eq', true)
      theme().should('equal', 'dark')
      cy.get(`${userMenu} ${toggle}[data-from-snapshot]`).should('have.attr', 'aria-checked', 'true')
    })
  })
})
