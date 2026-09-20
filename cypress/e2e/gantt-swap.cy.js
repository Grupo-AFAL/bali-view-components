// Gantt (#970): the island is the ONLY renderer and the built-in skeleton is the
// only loading state. What this spec measures is the SWAP — the skeleton has to
// be inside the mount BEFORE, the island AFTER, and at no point an empty box.
//
// This file used to (#719) also compare the geometry of the server-rendered
// board against the island's. That board no longer exists: there are no two
// renderers that can disagree, so the only geometry that is still a boundary is
// the ZOOM the island opens at, which the server resolves.
//
// Presence/visibility of nodes is what is measured, not loose textContent (repo
// memory).
//
// The bundle is NOT delayed to "see the before": a <script> injected before load
// delays the load event itself, so `cy.visit` waits out the whole delay and hands
// control back with the island ALREADY mounted — the window we wanted to observe
// does not exist from the outside. The ORDER is measured from inside the page
// (observeSwap) and the island-less state is checked by blocking the bundle.

// Leaves the island without its bundle: whatever is left on screen is what a
// visitor the JS never reaches sees.
//
// The METAS are stripped from the HTML response, the .js is not blocked. Blocking
// the bundle request does not work: the asset is digested and immutable, so as
// soon as an earlier test loads it the browser serves it from its cache and there
// is no request to intercept (measured: the island mounted all the same and the
// test failed). Without metas, startIslandLoader does not know what to inject —
// it is the failure mode docs/api/gantt.md documents.
const withoutIsland = () =>
  cy.intercept({ method: 'GET', url: /\/lookbook\/preview\/bali\/gantt\// }, (req) => {
    req.on('response', (res) => {
      res.body = String(res.body).replace(/<meta name="bali-gantt-(?:js|css)"[^>]*>/g, '')
    })
  })

// Records, FROM the page, whether the skeleton was inside the mount at the start
// and whether it was still there when React inserted its canvas.
const observeSwap = (win) => {
  const swap = { skeletonAtStart: null, skeletonWhenIslandMounts: null, mountEmpty: false }
  win.__swap = swap

  const hasSkeleton = () => !!win.document.querySelector('[data-controller="gantt"] .bali-gantt-skeleton')

  win.document.addEventListener('DOMContentLoaded', () => {
    swap.skeletonAtStart = hasSkeleton()
  })

  const observer = new win.MutationObserver(() => {
    const mount = win.document.querySelector('[data-controller="gantt"]')
    // The promise of the atomic swap: not a single intermediate state in which the
    // mount has been left without a skeleton AND without a canvas.
    if (mount && !hasSkeleton() && !win.document.querySelector('.react-flow')) {
      swap.mountEmpty = true
    }
    if (!win.document.querySelector('.react-flow')) return
    if (swap.skeletonWhenIslandMounts === null) {
      swap.skeletonWhenIslandMounts = hasSkeleton()
    }
  })
  observer.observe(win.document.documentElement, { childList: true, subtree: true })
}

describe('Gantt: the skeleton and the swap to the island', () => {
  it('paints the skeleton inside the mount and the island replaces it with no empty box', () => {
    cy.visit('/bali/gantt/default', { onBeforeLoad: observeSwap })

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')

    cy.window().should((win) => {
      // The server sent the skeleton inside the mount element itself...
      expect(win.__swap.skeletonAtStart, 'skeleton present at start').to.equal(true)
      // ...and it was no longer there when React inserted its canvas: it replaced
      // it, it did not stack underneath.
      expect(win.__swap.skeletonWhenIslandMounts, 'skeleton at mount time').to.equal(false)
      expect(win.__swap.mountEmpty, 'mount empty at some point during the swap').to.equal(false)
    })

    // The island lives where the skeleton lived.
    cy.get('[data-controller="gantt"] .react-flow').should('exist')
    cy.get('.bali-gantt-skeleton').should('not.exist')
  })

  // Without the metas, startIslandLoader injects nothing and the controller NEVER
  // gets registered, so there is no notice inside the mount: all that is left is
  // the skeleton and a console error naming the missing meta.
  // (The notice PREPENDED to the mount's content is the other failure mode — the
  // registered controller whose import() blows up — and the load_error preview in
  // react-island.cy.js covers it.)
  //
  // It is exactly the case that makes the <noscript> necessary: the skeleton says
  // `aria-busy` and that means "loading", and here that would be a lie forever.
  it('if the bundle never arrives, the skeleton stays and the failure is named', () => {
    withoutIsland()
    cy.visit('/bali/gantt/default', {
      onBeforeLoad: (win) => cy.stub(win.console, 'error').as('consoleError')
    })

    cy.get('[data-controller="gantt"] .bali-gantt-skeleton')
      .should('be.visible')
      .and('have.attr', 'aria-busy', 'true')
      .and('have.attr', 'role', 'status')
    cy.get('.react-flow').should('not.exist')

    // The message for whoever has no JavaScript travels in the HTML even though
    // this browser does have it (a <noscript> is not rendered, but it is there).
    cy.get('[data-controller="gantt"] noscript').should('exist')

    cy.get('@consoleError').should('have.been.calledWithMatch', /bali-gantt-js/)
  })

  // Without this handoff the island would open at its default ("week") while the
  // server resolved `:auto` against the window (here, "day"): mounting would
  // rescale the whole board in front of the visitor. It is the only geometry that
  // still crosses the Ruby↔JS boundary.
  it('the island opens at the zoom the server resolved', () => {
    cy.visit('/bali/gantt/default')

    cy.get('[data-controller="gantt"]')
      .should('have.attr', 'data-gantt-initial-zoom-value', 'day')

    cy.get('[role="group"][aria-label="Zoom"] .btn-active').should('have.text', 'Day')
  })

  it('mounts with 300 items over the skeleton', () => {
    cy.visit('/bali/gantt/stress', { onBeforeLoad: observeSwap })

    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-initial-zoom-value', 'week')
    cy.get('.react-flow', { timeout: 30000 }).should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.get('.bali-gantt-skeleton').should('not.exist')
    cy.window().should((win) => {
      expect(win.__swap.skeletonAtStart, '300-item skeleton present at start').to.equal(true)
      expect(win.__swap.mountEmpty, 'mount empty at some point during the swap').to.equal(false)
    })
  })

  // An empty document is the island's business, not the component's: it mounts
  // all the same, with its toolbar, instead of the server painting something else
  // in its place.
  it('an empty document mounts the island all the same', () => {
    cy.visit('/bali/gantt/empty')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('not.exist')
    cy.get('[role="group"][aria-label="Zoom"]').should('be.visible')
    cy.get('.bali-gantt-skeleton').should('not.exist')
  })
})
