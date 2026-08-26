// The gauge's track, which only exists in compiled CSS and so cannot be seen by
// a component test.
//
// daisyUI paints ONLY the filled arc — its `::before` is
// `conic-gradient(currentColor var(--radialprogress), transparent 0)` — so
// without an override the unfilled remainder is nothing at all. A ring at 0%
// renders as a bare dot, indistinguishable from a component that failed to
// load, and at any value you cannot judge the proportion because there is
// nothing to judge it against.
//
// The override is unlayered on purpose: daisyUI 5 emits its components inside
// `@layer utilities`, and layers beat specificity, so the same rule in
// `@layer components` would lose however specific it was. That is exactly what
// this spec is guarding — a well-meaning move into a layer would pass every
// Ruby test and silently delete the track.
describe('gauge', () => {
  const ring = '.radial-progress'

  it('paints a track behind the unfilled arc', () => {
    cy.visit('/bali/gauge/default?value=7&max=10&label=shifts&size=lg')

    cy.get(ring).then(($el) => {
      const background = window.getComputedStyle($el[0], '::before').background
      // The second conic stop is the track. Transparent here means the override
      // lost to daisyUI and the ring has gone back to being invisible.
      expect(background).to.include('conic-gradient')
      expect(background).not.to.match(/conic-gradient\([^)]*?,\s*rgba\(0,\s*0,\s*0,\s*0\)\s*0/)
    })
  })

  it('still draws a full ring when the goal is at zero', () => {
    cy.visit('/bali/gauge/default?value=0&max=10&label=shifts&size=lg')

    cy.get(ring)
      .should('have.attr', 'aria-valuenow', '0')
      .and(($el) => {
        // The ring occupies its declared size rather than collapsing to the dot.
        expect($el[0].getBoundingClientRect().width).to.be.greaterThan(50)
      })
  })
})
