// #1148. The Ruby tests can say that the default spacing is no longer written
// on the markup and that the sheet declares it inside @layer components; only a
// browser can say who wins the cascade, which is the whole point of the move.
// These numbers are the ones the CHANGELOG promises: unchanged by default, and
// beaten by a caller utility at any value without `!`.
describe('Reveal defaults the caller can beat', () => {
  beforeEach(() => {
    cy.visit('/bali/reveal/compact')
  })

  it('leaves the defaults exactly where they were', () => {
    cy.get('#reveal-default .reveal-trigger')
      .should('have.css', 'padding-bottom', '24px')
      .and('have.css', 'margin-bottom', '24px')
    cy.get('#reveal-default .reveal-content').should('have.css', 'margin-bottom', '32px')
    cy.get('#reveal-icon-default .trigger-icon').should('have.css', 'height', '14px')
  })

  it('lets a caller utility win at an intermediate value', () => {
    cy.get('#reveal-compact .reveal-trigger')
      .should('have.css', 'padding-bottom', '8px')
      .and('have.css', 'margin-bottom', '8px')
    cy.get('#reveal-compact .reveal-content').should('have.css', 'margin-bottom', '8px')
  })

  // The case that used to lose: `.pb-0` is emitted before `.pb-6`, so before the
  // move this read 24px with `pb-0 mb-0` on the button.
  it('lets a caller utility win at 0', () => {
    cy.get('#reveal-compact-second .reveal-trigger')
      .should('have.css', 'padding-bottom', '0px')
      .and('have.css', 'margin-bottom', '0px')
    cy.get('#reveal-compact-second .reveal-content').should('have.css', 'margin-bottom', '0px')
  })

  // Same defect on the chevron: `icon_class: 'h-2'` used to read 14px.
  it('lets icon_class shrink the chevron below the default', () => {
    cy.get('#reveal-icon-tight .trigger-icon').should('have.css', 'height', '8px')
  })

  // None of the above may come from an `!important` escape hatch: that would
  // mean the host still needs one.
  it('wins without the important flag', () => {
    cy.get('#reveal-compact-second .reveal-trigger')
      .invoke('attr', 'class')
      .should('not.match', /!/)
  })
})
