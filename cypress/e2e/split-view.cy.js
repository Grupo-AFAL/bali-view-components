// The point of SplitView is what does NOT happen on a row click: the master
// pane must survive untouched, keeping its scroll position and its DOM, while
// only the detail frame is replaced. Every assertion here is about that, so the
// tests mark a live node and measure geometry rather than reading text.
describe('SplitView', () => {
  const masterList = () => cy.get('[data-testid="master-list"]')

  context('default (no selection, advance on)', () => {
    beforeEach(() => {
      cy.visit('/bali/split_view/default')
      // Stamped on the live node: a re-render of the master would replace it and
      // the attribute would be gone.
      masterList().invoke('attr', 'data-sentinel', 'kept')
    })

    it('starts on the empty detail with no row selected', () => {
      cy.get('.split-view-detail .empty-state-component').should('be.visible')
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
        cy.location('pathname').should('include', '/lookbook/preview/bali/split_view/default')
        cy.get('.split-view-detail .empty-state-component').should('be.visible')
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

  context('responsive layout', () => {
    it('puts the panes side by side from lg up and stacks them below it', () => {
      cy.visit('/bali/split_view/default')

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
      cy.visit('/bali/split_view/default?master_width=320px')
      cy.get('.split-view-component')
        .should('have.css', 'grid-template-columns')
        .and('match', /^320px /)
    })
  })
})
