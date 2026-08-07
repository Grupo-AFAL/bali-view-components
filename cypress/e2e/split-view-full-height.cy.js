// `height: :full` against its documented pairing: an AppLayout with
// `viewport_locked: true`. There is no measurement in the implementation — it is
// `height: 100%` and a flex chain — so the only way to know it works is to
// measure the result, which is what this does.
describe('SplitView height: :full', () => {
  const app = path =>
    `${Cypress.config('baseUrl').replace(/\/lookbook\/preview\/?$/, '')}${path}`

  const rectOf = selector =>
    cy.get(selector).then($el => $el[0].getBoundingClientRect())

  beforeEach(() => {
    cy.viewport(1280, 800)
    cy.visit(app('/split-view/full'))
  })

  it('fills the locked viewport instead of stopping at its content', () => {
    cy.get('.split-view-component').should('have.class', 'split-view-component--full')

    rectOf('main').then((main) => {
      rectOf('.split-view-component').then((split) => {
        // The gap is the body container's padding, nothing more.
        expect(main.bottom - split.bottom, 'the split reaches the bottom of main')
          .to.be.lessThan(60)
        expect(split.height, 'the split is most of the screen')
          .to.be.greaterThan(main.height * 0.85)
      })
    })
  })

  // The point of the shape: the page does not scroll, the panes do.
  it('leaves the page unscrollable and gives each pane its own scroll', () => {
    cy.document().then((doc) => {
      expect(doc.documentElement.scrollHeight, 'the page itself does not scroll')
        .to.be.at.most(doc.documentElement.clientHeight + 1)
    })

    cy.get('[data-split-view-list-target="scroller"]')
      .should('have.css', 'overflow-y', 'auto')
      .and('have.css', 'max-height', 'none')
    cy.get('.split-view-detail').should('have.css', 'overflow-y', 'auto')
  })

  it('lines the two panes up at the same height', () => {
    rectOf('.split-view-master').then((master) => {
      rectOf('.split-view-detail').then((detail) => {
        expect(Math.abs(master.height - detail.height), 'both panes are the same height')
          .to.be.lessThan(2)
      })
    })
  })

  // The interaction the issue asks about: in `:full` the scroll container is
  // taller than it was, so one page of rows no longer fills it. The sentinel
  // stays in view and has to keep asking — the container changed size, not
  // identity, and the observer is rooted on it either way.
  it('keeps the infinite scroll loading until the taller pane is full', () => {
    // 5 rows a page, 20 in the table. A pane this tall does not stop at one
    // page: the sentinel stays in view after each append and keeps asking, so
    // the listing runs to the end without anybody scrolling.
    cy.get('.split-view-item').should('have.length.greaterThan', 5)
    cy.get('.split-view-item').should('have.length', 20)
    cy.get('[data-split-view-list-target="end"]').should('not.have.attr', 'hidden')
  })

  it('still swaps only the detail frame when a row is clicked', () => {
    cy.get('.split-view-item').eq(2).click()
    cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
    cy.get('.split-view-item').eq(2).should('have.attr', 'aria-current', 'true')
  })

  // Two stacked panes cannot both fill one screen, so below `lg` the modifier is
  // inert and the page scrolls as usual.
  it('does nothing below lg, where the panes are stacked', () => {
    cy.viewport(700, 800)

    // The two rules that make `:full` what it is are inside the `lg` media
    // query, so below it the panes go back to the ordinary arrangement: the
    // master capped by its own variable, the detail not a scroll box at all.
    cy.get('[data-split-view-list-target="scroller"]')
      .should('have.css', 'max-height')
      .and('not.eq', 'none')
    cy.get('.split-view-detail').should('have.css', 'overflow-y', 'visible')
  })
})
