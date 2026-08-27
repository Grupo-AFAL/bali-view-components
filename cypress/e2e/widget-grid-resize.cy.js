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

  // `recent_movies` is a ListBase: growing it gains rows, which is the list
  // ladder's whole content step. A TrendBase has no rows at all — the pattern
  // is the type, and a trend widget's ladder is figure → sparkline → axed chart.
  it('grows a list card from medium to large and gains rows', () => {
    startAt('recent_movies', 'medium')
    cy.get(`${card('recent_movies')} ul.list li`).should('have.length', 3)

    sizeTo('recent_movies', 'large')

    cy.get(card('recent_movies')).should('have.attr', 'data-size', 'large')
    cy.get(`${card('recent_movies')} ul.list li`).should('have.length', 7)
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
  // A ListBase at `small` is a hero — the whole tile is one link and there is no
  // header. Growing it is a different DOM, which only a re-render can produce.
  it('grows a hero card into the full layout', () => {
    startAt('recent_movies', 'small')
    cy.get(`${card('recent_movies')} .stat`).should('exist')
    cy.get(`${card('recent_movies')} h5`).should('not.exist')

    sizeTo('recent_movies', 'large')

    cy.get(`${card('recent_movies')} h5`).should('exist')
    cy.get(`${card('recent_movies')} .stat`).should('not.exist')
  })

  // `ValueBase` supports `:small` alone — a bare figure has nothing to fill a
  // bigger canvas, which is the class's point rather than a limitation of it.
  // One size is not a choice, so neither gets a radiogroup to tab into.
  //
  // The partial case (two of three offered) is covered in
  // `test/bali/components/widget_size_picker_test.rb`, which can build a widget
  // for it rather than needing one to exist in the showcase.
  it('gives a single-size widget no picker at all', () => {
    cy.get(`${card('production_budget')} [role="radiogroup"]`).should('not.exist')
    cy.get(`${card('production_budget')} [data-widget-size]`).should('not.exist')
    cy.get(`${card('unavailable_feed')} [role="radiogroup"]`).should('not.exist')
  })

  // A keyboard resize leaves focus on a size button inside the card the stream
  // is about to replace, and a replaced element takes its focus with it.
  it('keeps focus on the size picker after a keyboard resize', () => {
    startAt('recent_movies', 'medium')
    cy.get(`${card('recent_movies')} [aria-checked="true"]`).focus().type('{rightarrow}')

    cy.get(card('recent_movies')).should('have.attr', 'data-size', 'large')
    cy.focused().should('have.attr', 'data-widget-size', 'large')
  })

  // The replacement lands inside a grid that is still in edit mode, and
  // `editingValueChanged` does not fire again for it. Without
  // `inertTargetConnected` the new card is tabbable inside a dimmed page.
  it('marks the replacement inert, like every other card in edit mode', () => {
    startAt('recent_movies', 'medium')

    sizeTo('recent_movies', 'large')

    cy.get(`${card('recent_movies')} [data-bali-widget-grid-edit-mode-target="inert"]`)
      .should(($el) => expect($el[0].inert, 'replacement is inert').to.equal(true))
  })
})
