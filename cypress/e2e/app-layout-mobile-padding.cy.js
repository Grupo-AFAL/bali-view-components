// `mobile_bottom_padding` is pure CSS, but the half of it that matters lives behind a
// media query: it has to be MEASURED with a real phone viewport, not deduced from the
// sheet. What is measured is the COMPUTED padding of <main>, which is where the space
// lands (the container's is set by a Tailwind utility and would beat any rule in the layer).
describe('AppLayout: bottom space on a phone', () => {
  const main = '.app-layout-content > main'
  const withOption = '/bali/app_layout/default?mobile_bottom_padding=true'

  it('leaves 1rem on desktop, which is what was already there', () => {
    cy.viewport(1440, 900)
    cy.visit(withOption)
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('16px')
    })
  })

  // 4rem and not `env(safe-area-inset-bottom)`: Safari's floating bar paints ON TOP of the
  // page and is not reflected in safe-area, so the environment does not replace the constant.
  it('leaves 4rem below 640px for the browser floating bar', () => {
    cy.viewport(390, 844)
    cy.visit(withOption)
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('64px')
    })
  })

  it('adds nothing without the option, not even on a phone', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/app_layout/default')
    cy.get('body').should('not.have.class', 'app-layout--mobile-bottom-padding')
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('0px')
    })
  })
})
