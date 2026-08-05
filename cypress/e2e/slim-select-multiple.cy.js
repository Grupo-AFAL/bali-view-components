// #841 — a `multiple` SlimSelect has to grow to its second row of pills.
//
// The trigger is `w-full`, so the only way to make four pills wrap is to narrow the
// window. That is why this lives in Cypress: `cy.viewport` is the one resize we can
// drive reliably; the browser harness reports the old `innerWidth` after a resize.
//
// Everything is read with offsetTop / offsetHeight / clientHeight and never with
// getBoundingClientRect: `.ss-value` carries the `ss-valueIn` animation, whose 0% frame
// is `scale(0.8)`, so a rect is the transformed box (20.8px) and not the layout box
// (26px). offsetTop is relative to the offsetParent's padding edge and clientHeight is
// the padding box, so `offsetTop + offsetHeight <= clientHeight` is exactly "inside".
const OPTIONS = ['Option 1', 'Option 2', 'Option 3', 'Option 4']

const selectFour = () => {
  OPTIONS.forEach((label, i) => {
    // The list closes on every pick, so it is reopened for the next one. Cypress
    // refuses to click an option in a closed list — it is "hidden by transform" —
    // which is the honest reading of the widget's state, so it is not forced.
    cy.get('.ss-main').click()
    cy.get('.ss-content .ss-list .ss-option').contains(label).click()
    cy.get('.ss-main .ss-values .ss-value').should('have.length', i + 1)
  })
  // Close the list from its own search input; clicking the page risks hitting a pill's
  // delete button and undoing a selection.
  cy.get('.ss-main').click()
  cy.get('.ss-content .ss-search input').type('{esc}')
}

describe('SlimSelect multiple', () => {
  it('grows to fit a second row of pills instead of clipping it', () => {
    // 360px viewport minus the page padding leaves a trigger that holds three pills on
    // the first row and pushes the fourth onto a second one.
    cy.viewport(360, 720)
    cy.visit('/bali/form/slim_select/multiple')
    selectFour()

    cy.get('.ss-main').then(([main]) => {
      const values = main.querySelector('.ss-values')
      const pills = [...main.querySelectorAll('.ss-value')]
      const rows = new Set(pills.map(pill => pill.offsetTop))

      // Guard: if a font or spacing change stops the wrap, fail here rather than let
      // the assertions below pass on a single row that was never at risk.
      expect(rows.size, 'rows of pills').to.be.greaterThan(1)

      expect(values.scrollHeight, 'values scrollHeight vs trigger padding box')
        .to.be.at.most(main.clientHeight)

      pills.forEach(pill => {
        const name = pill.textContent.trim()
        expect(pill.offsetTop, `${name} top inside the trigger`).to.be.at.least(0)
        expect(pill.offsetTop + pill.offsetHeight, `${name} bottom inside the trigger`)
          .to.be.at.most(main.clientHeight)
      })
    })
  })

  // The other direction: `height: auto` must not leak into the ordinary case.
  it('leaves a single select at its 40px', () => {
    cy.viewport(360, 720)
    cy.visit('/bali/form/slim_select/default')

    cy.get('.ss-main').should('have.css', 'height', '40px')
  })
})
