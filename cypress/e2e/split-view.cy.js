// Against `custom_master`, the free-slot escape hatch: these are the base
// component's guarantees — frame swap, highlight, history — and they have to
// hold for a listing a host wired by hand, not only for `with_list`. The
// structured API has its own spec.
//
// The point of SplitView is what does NOT happen on a row click: the master
// pane must survive untouched, keeping its scroll position and its DOM, while
// only the detail frame is replaced. Every assertion here is about that, so the
// tests mark a live node and measure geometry rather than reading text.
describe('SplitView', () => {
  const masterList = () => cy.get('[data-testid="master-list"]')

  context('default (no selection, advance on)', () => {
    beforeEach(() => {
      cy.visit('/bali/split_view/custom_master')
      // Stamped on the live node: a re-render of the master would replace it and
      // the attribute would be gone.
      masterList().invoke('attr', 'data-sentinel', 'kept')
    })

    it('starts on the empty detail with no row selected', () => {
      // 10s and not the 4s default: first query after a cold visit — in CI the
      // preview's first render (dev mode, uncompiled templates, a loaded
      // runner) has taken longer than the timeout and this assert was the
      // suite's most frequent flake. If it fails again at 10s it is no longer
      // timing: the workflow now uploads screenshots to see it.
      cy.get('.split-view-detail .empty-state-component', { timeout: 10000 }).should('be.visible')
      cy.get('.split-view-row[aria-current]').should('not.exist')
    })

    it('replaces only the detail frame when a row is clicked', () => {
      cy.get('.split-view-row').eq(2).click()

      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.get('.split-view-detail .empty-state-component').should('not.exist')
      // Same master node as before the click.
      masterList().should('have.attr', 'data-sentinel', 'kept')
      cy.get('.split-view-row').should('have.length', 8)
    })

    it('keeps the master scroll position across the swap', () => {
      masterList().scrollTo(0, 120)
      masterList().its('0.scrollTop').should('be.greaterThan', 0).then((before) => {
        // `scrollBehavior: false` or Cypress scrolls the row into view before
        // clicking and moves the very scrollTop this test is about. Row 3 is
        // already on screen at this offset.
        cy.get('.split-view-row').eq(3).click({ scrollBehavior: false })
        cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
        masterList().its('0.scrollTop').should('eq', before)
      })
    })

    it('moves aria-current to the clicked row and nowhere else', () => {
      cy.get('.split-view-row').eq(1).click()
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
      cy.get('.split-view-row').eq(1).should('have.attr', 'aria-current', 'true')

      cy.get('.split-view-row').eq(4).click()
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
      cy.get('.split-view-row').eq(4).should('have.attr', 'aria-current', 'true')
      cy.get('.split-view-row').eq(1).should('not.have.attr', 'aria-current')
    })

    // The selection bar has to be an inset box-shadow rather than a left
    // border: the rows here carry `border-b border-base-200/70`, the idiom for
    // a separator, and that colour utility claims all four sides from
    // Tailwind's utilities layer — which beats @layer components. A
    // `border-l-primary` in the component sheet renders base-200 under it and
    // the highlight disappears. This test fails if anyone moves it back.
    it('paints the selected row from CSS the row separator cannot override', () => {
      cy.get('.split-view-row').eq(1).as('row')
      cy.get('@row').should('have.css', 'box-shadow', 'none')

      cy.get('@row').click()
      // Not just /inset/: a shadow mid-transition, or one whose colour failed to
      // resolve, still reads `... 0px 0px 0px 0px inset` and would pass that.
      // The 3px offset and a non-transparent colour are the bar itself.
      cy.get('@row')
        .should('have.css', 'box-shadow')
        .and('include', '3px')
        .and('include', 'inset')
        .and('not.match', /^(rgba\(0, 0, 0, 0\)|oklab\(0 0 0 \/ 0\))/)
    })

    it('does not reserve layout space for the selection bar', () => {
      cy.get('.split-view-row').eq(1).then(($row) => {
        const before = $row[0].getBoundingClientRect()
        cy.get('.split-view-row').eq(1).click()
        cy.get('.split-view-row').eq(1).should('have.attr', 'aria-current', 'true')
        cy.get('.split-view-row').eq(1).then(($after) => {
          const after = $after[0].getBoundingClientRect()
          expect(after.width).to.eq(before.width)
          expect(after.left).to.eq(before.left)
        })
      })
    })

    it('advances the URL and restores the preview on back', () => {
      cy.get('.split-view-row').eq(3).invoke('attr', 'href').then((href) => {
        cy.get('.split-view-row').eq(3).click()
        cy.location('pathname').should('eq', '/split-view')
        cy.location('search').should('eq', href.split('?')[1] ? `?${href.split('?')[1]}` : '')

        cy.go('back')
        cy.location('pathname').should('include', '/lookbook/preview/bali/split_view/custom_master')
        // Same margin as the cold-load assert: the back restoration can
        // re-render the whole preview in CI.
        cy.get('.split-view-detail .empty-state-component', { timeout: 10000 }).should('be.visible')
        // The highlight has to rewind with the frame. Turbo caches the snapshot
        // of the page it leaves, and it takes it AFTER the controller has moved
        // aria-current — so without the `turbo:before-cache` rewind this page
        // came back showing a selected row next to an empty detail.
        cy.get('.split-view-row[aria-current]').should('not.exist')
      })
    })
  })

  context('with_selection (server-painted selection)', () => {
    it('renders the detail and the highlight without any JS having run', () => {
      cy.visit('/bali/split_view/with_selection')
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
    })
  })

  context('without_advance', () => {
    it('swaps the frame but leaves the history alone', () => {
      cy.visit('/bali/split_view/without_advance')
      cy.get('.split-view-detail').should('not.have.attr', 'data-turbo-action')

      cy.get('.split-view-row').eq(2).click()
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.location('pathname').should('include', '/lookbook/preview/bali/split_view/without_advance')
    })
  })

  // Which row a location selects, driven straight at the controller with a
  // history entry and a popstate. Deliberately not through `cy.go('back')`:
  // that also exercises Turbo's snapshot cache, and the rule under test is the
  // controller's alone — given this URL, which row is current.
  context('deciding which row a location selects', () => {
    const traverseTo = search =>
      cy.window().then((win) => {
        win.history.pushState({}, '', `/split-view${search}`)
        win.dispatchEvent(new win.PopStateEvent('popstate', { state: {} }))
      })

    beforeEach(() => {
      cy.visit('/bali/split_view/custom_master')
      cy.get('.split-view-row').eq(2).invoke('attr', 'href').then((href) => {
        cy.wrap(new URL(href, 'http://example.test').searchParams.get('selected')).as('id')
      })
    })

    it('selects the row whose href the location satisfies', function () {
      traverseTo(`?selected=${this.id}`)
      cy.get(`#split-view-row-${this.id}`).should('have.attr', 'aria-current', 'true')
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
    })

    // The regression this replaced an exact string comparison for: the row href
    // and the location are built by different code paths, so the location can
    // carry params the href never had and list them in another order.
    it('still selects it when the location carries extra params, in any order', function () {
      traverseTo(`?sort=name&selected=${this.id}&page=2`)
      cy.get(`#split-view-row-${this.id}`).should('have.attr', 'aria-current', 'true')
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
    })

    it('selects nothing when no row href is satisfied', function () {
      traverseTo(`?selected=${this.id}`)
      cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)

      traverseTo('?sort=name')
      cy.get('.split-view-row[aria-current]').should('not.exist')
    })
  })

  context('responsive layout', () => {
    it('puts the panes side by side from lg up and stacks them below it', () => {
      cy.visit('/bali/split_view/custom_master')

      cy.viewport(1280, 800)
      cy.get('.split-view-component')
        .should('have.css', 'grid-template-columns')
        .and('match', /^420px /)

      cy.viewport(700, 800)
      cy.get('.split-view-component')
        .invoke('css', 'grid-template-columns')
        .should((columns) => {
          expect(columns.split(' ')).to.have.length(1)
        })
    })

    it('honours a custom master_width through the CSS custom property', () => {
      cy.viewport(1280, 800)
      cy.visit('/bali/split_view/custom_master?master_width=320px')
      cy.get('.split-view-component')
        .should('have.css', 'grid-template-columns')
        .and('match', /^320px /)
    })
  })
})

// #1012 — a frame the reader navigated in-page must not reach Turbo's snapshot
// cache still carrying its `src`: on restore Turbo reloads every frame with a
// `src`, that reload fires the frame's own `advance` again, and whoever pressed
// back is thrown forward to the detail they had just left. In CI it happened in
// ~1 run out of 3; locally, never — the snapshot is taken before the frame's
// response arrives and comes out clean by accident.
//
// Hence the explicit event dispatch: the bug does not depend on the user doing
// anything different, but on WHEN Turbo reads the DOM, and that cannot be asked
// for from a test. What IS deterministic — and is the contract — is what is
// left in the DOM when `turbo:before-cache` runs.
//
// The rewind strips ONLY the `src`, not the content: a click's `advance`
// (`data-turbo-action="advance"`, willRender: false) fires `turbo:before-cache`
// against the page that STAYS on screen, so wiping the detail here emptied the
// pane the reader had just opened, on every click. Dropping the `src` is what
// #1012 needs; the list coming back empty on restore is done by
// `syncFrameFromLocation` from the URL (see "restores the preview on back").
describe('SplitView: what gets cached after the frame is navigated (#1012)', () => {
  beforeEach(() => {
    cy.visit('/bali/split_view/custom_master')
    cy.get('.split-view-detail .empty-state-component', { timeout: 10000 }).should('be.visible')
    cy.get('.split-view-row').eq(2).click()
    cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
  })

  it('rewinds the navigated frame so the snapshot cannot re-advance', () => {
    cy.get('.split-view-detail').should('have.attr', 'src')

    cy.document().then(doc => doc.dispatchEvent(new Event('turbo:before-cache')))

    // With no `src` there is no reload on restore, and with no reload no advance.
    cy.get('.split-view-detail').should('not.have.attr', 'src')
    // And the detail the reader is looking at is NOT destroyed: an advance's
    // before-cache runs against the page that stays.
    cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
  })

  // The other half: traversing TO a URL that selects a row OTHER than the one
  // the pane shows has to refetch, because the frame was left rewound when it
  // was cached and its content belongs to another row. (Traversing to the SAME
  // row no longer refetches: the #1029 stash recognises the pane as already
  // right — see the describe below.)
  it('points the frame at the row a traversal selects when the pane shows another', () => {
    cy.get('.split-view-row').eq(1).invoke('attr', 'href').then((otherHref) => {
      cy.document().then(doc => doc.dispatchEvent(new Event('turbo:before-cache')))
      cy.get('.split-view-detail').should('not.have.attr', 'src')

      cy.window().then((win) => {
        win.history.pushState({}, '', otherHref)
        win.dispatchEvent(new win.PopStateEvent('popstate', { state: {} }))
      })

      cy.get('.split-view-detail').should('have.attr', 'src', otherHref)
      // And wait for the detail: if the test ends with the frame's fetch in
      // flight, the next test's `cy.visit` tears the page down, the fetch is
      // aborted and Cypress attributes the AbortError to the wrong test.
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
    })
  })

  // The symmetric case of the one above, and the heart of #1029: the rewind
  // left the pane without a `src` but SHOWING the right detail; going back to
  // that same URL must refetch nothing.
  it('leaves the frame alone when the traversal lands on what it already shows', () => {
    cy.get('.split-view-row').eq(2).invoke('attr', 'href').then((href) => {
      cy.document().then(doc => doc.dispatchEvent(new Event('turbo:before-cache')))
      cy.get('.split-view-detail').should('not.have.attr', 'src')

      cy.intercept('GET', '/split-view*').as('detail')

      cy.window().then((win) => {
        win.history.pushState({}, '', href)
        win.dispatchEvent(new win.PopStateEvent('popstate', { state: {} }))
      })

      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.wait(400)
      cy.get('@detail.all').should('have.length', 0)
      cy.get('.split-view-detail').should('not.have.attr', 'src')
    })
  })
})

// #1029 — the refetch guard compared the frame's `src` (which Turbo leaves
// ABSOLUTE after navigating) against the row's `href` (relative, as written),
// so they never matched: every popstate rewrote the `src` and refetched a
// detail that was already on screen. The guard now compares the two URLs
// resolved against the document.
describe('SplitView: a traversal to the URL the frame already shows (#1029)', () => {
  it('re-derives the highlight without refetching the detail', () => {
    cy.visit('/bali/split_view/custom_master')
    cy.get('.split-view-detail .empty-state-component', { timeout: 10000 }).should('be.visible')

    cy.get('.split-view-row').eq(2).click()
    cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')

    cy.intercept('GET', '/split-view*').as('detail')

    // The URL does not change: the popstate arrives while already on the entry
    // the frame shows (a back that lands exactly here).
    cy.window().then((win) => {
      win.dispatchEvent(new win.PopStateEvent('popstate', { state: {} }))
    })

    // The highlight is re-derived all the same (the URL still selects the row)...
    cy.get('.split-view-row[aria-current="true"]').should('have.length', 1)
    cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')

    // ...but the frame is not requested again: it already shows this detail.
    // The fixed wait is deliberate — "there was no request" needs to let the
    // time in which it would have happened go by.
    cy.wait(400)
    cy.get('@detail.all').should('have.length', 0)
  })
})
