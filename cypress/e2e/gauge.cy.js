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

  // daisyUI's conic ends `…, #0000 0)`, which computes to this. Bali's override
  // replaces that final stop with the track colour, so this exact substring is
  // the discriminator between the two rules winning.
  //
  // Read as a plain substring rather than parsed out of the background: a regex
  // for the conic's contents stops at the first `)`, which belongs to the
  // `oklch(…)` inside it, and silently captures a truncated string that can
  // never match. That is how an earlier version of this spec passed against a
  // build with no track at all.
  const TRANSPARENT = 'rgba(0, 0, 0, 0) 0deg'

  const trackStop = (el) => {
    const background = window.getComputedStyle(el, '::before').background
    expect(background, 'the ring must draw a conic arc').to.include('conic-gradient')

    return background.includes(TRANSPARENT) ? TRANSPARENT : 'painted'
  }

  it('paints a track behind the unfilled arc', () => {
    cy.visit('/bali/gauge/default?value=7&max=10&label=shifts&size=lg')

    cy.get(ring).then(($el) => {
      expect(trackStop($el[0]), 'the unfilled arc must be painted').to.not.equal(TRANSPARENT)
    })
  })

  // At 0% the conic is ENTIRELY track, which is a different assertion from the
  // one above and the state the bug actually showed up in: without the override
  // there is nothing to paint and the ring disappears.
  //
  // Deliberately not asserting the element's width — `--size` is 7rem whether
  // the track paints or not, so a box measurement passes with the override
  // deleted. "Collapsing to a dot" is a paint effect, and only a paint
  // assertion can see it.
  it('is all track when the goal is at zero, rather than nothing at all', () => {
    cy.visit('/bali/gauge/default?value=0&max=10&label=shifts&size=lg')

    cy.get(ring).should('have.attr', 'aria-valuenow', '0')

    cy.get(ring).then(($el) => {
      expect(trackStop($el[0]), 'at 0% the whole ring is track').to.not.equal(TRANSPARENT)
    })
  })
})
