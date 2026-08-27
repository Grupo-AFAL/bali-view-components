// Resizing a card changes its SHAPE, and the card's interior is server-rendered.
//
// `applySize` writes one attribute; the regions inside do not move. So growing a
// charted `medium` to `large` used to keep an axis-less sparkline and no
// breakdown, and growing a hero card left one number alone in a 2x2 cell — the
// gesture the whole size ladder exists to serve, failing in the one direction
// that matters. The grid now sends `resized_key` and a host answers with a
// turbo-stream replacing that card.
//
// Against the REAL dashboard rather than the Lookbook preview: the preview's stub
// endpoint answers `head :no_content`, which is still a valid host response and
// therefore cannot exercise this.
const appOrigin = new URL(Cypress.config('baseUrl')).origin

describe('resizing re-renders the card', () => {
  const card = (key) => `[data-widget-key="${key}"]`
  const sizeTo = (key, size) => cy.get(`${card(key)} [data-widget-size="${size}"]`).click()

  // Each test sets its own starting size rather than resetting the dashboard.
  // Resizing PERSISTS, so a spec that assumed a widget's declared size would pass
  // once and then read whatever the previous test left behind.
  const startAt = (key, size) => {
    sizeTo(key, size)
    cy.get(card(key)).should('have.attr', 'data-size', size)
  }

  beforeEach(() => {
    // The edit shelf is `max-lg:hidden lg:flex`, and Cypress's default viewport
    // (1000px) is under the 1024px `lg` breakpoint — so the size picker is not
    // clickable at all below it.
    cy.viewport(1400, 1500)
    cy.visit(`${appOrigin}/dashboard_widgets?editing=1`)
  })

  // `studio_foundings` is a metric widget: a count, a trend and a series. At
  // `medium` a charted card trades its rows for the sparkline, so it has none.
  it('grows a charted card from medium to large and gains the breakdown', () => {
    startAt('studio_foundings', 'medium')
    cy.get(`${card('studio_foundings')} ul.list li`).should('not.exist')

    sizeTo('studio_foundings', 'large')

    cy.get(card('studio_foundings')).should('have.attr', 'data-size', 'large')
    cy.get(`${card('studio_foundings')} .bali-widget-detail`).should('exist')
    cy.get(`${card('studio_foundings')} ul.list li`).should('have.length', 3)
  })

  // Below roughly 2x2 a chart gives up its axes. Growing has to give them back,
  // which only a re-render can do — the axes live in the chart's options, not in
  // a class the client could swap.
  it('gives the chart its axes back when it grows', () => {
    startAt('studio_foundings', 'medium')

    sizeTo('studio_foundings', 'large')

    cy.get(`${card('studio_foundings')} canvas.chart`).should(($canvas) => {
      const options = JSON.parse($canvas[0].dataset.chartOptionsValue)
      expect(options.scales?.x?.display, 'axes hidden at large').to.not.equal(false)
    })
  })

  // A hero card is a different DOM, not a smaller one: no header, the whole tile
  // is one link. No CSS can turn that into a stacked layout.
  // `overdue_tasks`, not `production_budget`: the latter declares
  // `sizes :small, :medium`, so `large` is not offerable — which is exactly what
  // that declaration is for. This needs a hero widget that offers all three.
  it('grows a hero card into the full layout', () => {
    startAt('overdue_tasks', 'small')
    cy.get(`${card('overdue_tasks')} .stat`).should('exist')
    cy.get(`${card('overdue_tasks')} h5`).should('not.exist')

    sizeTo('overdue_tasks', 'large')

    cy.get(`${card('overdue_tasks')} h5`).should('exist')
    cy.get(`${card('overdue_tasks')} .stat`).should('not.exist')
  })

  // The declaration is load-bearing, not decorative: a size a widget does not
  // offer has no button to press.
  it('offers only the sizes a widget declares', () => {
    cy.get(`${card('production_budget')} [data-widget-size]`).should('have.length', 2)
    cy.get(`${card('production_budget')} [data-widget-size="large"]`).should('not.exist')
  })

  // One size is not a choice, so there is no radiogroup to tab into.
  it('gives a single-size widget no picker at all', () => {
    cy.get(`${card('unavailable_feed')} [role="radiogroup"]`).should('not.exist')
  })

  // A keyboard resize leaves focus on a size button inside the card the stream
  // is about to replace, and a replaced element takes its focus with it.
  it('keeps focus on the size picker after a keyboard resize', () => {
    startAt('studio_foundings', 'medium')
    cy.get(`${card('studio_foundings')} [aria-checked="true"]`).focus().type('{rightarrow}')

    cy.get(card('studio_foundings')).should('have.attr', 'data-size', 'large')
    cy.focused().should('have.attr', 'data-widget-size', 'large')
  })

  // The replacement lands inside a grid that is still in edit mode, and
  // `editingValueChanged` does not fire again for it. Without
  // `inertTargetConnected` the new card is tabbable inside a dimmed page.
  it('marks the replacement inert, like every other card in edit mode', () => {
    startAt('studio_foundings', 'medium')

    sizeTo('studio_foundings', 'large')

    cy.get(`${card('studio_foundings')} [data-edit-mode-target="inert"]`)
      .should(($el) => expect($el[0].inert, 'replacement is inert').to.equal(true))
  })
})
