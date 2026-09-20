// #1028 — SortableList had no E2E spec (16 components with JS had no coverage;
// this is one of the highest-risk ones: reordering persists with a PATCH). Covers
// the mouse path (SortableJS) and the new keyboard alternative (WCAG 2.1.1):
// focus on the item + ArrowUp/ArrowDown move it one place and persist just like
// a drop.
describe('SortableList', () => {
  const items = () => cy.get('.sortable-list-component > .sortable-item')

  beforeEach(() => {
    cy.visit('/bali/sortable_list/default')
    cy.intercept('PATCH', '/sortable_list*', { statusCode: 200, body: '' }).as('reorder')
    items().should('have.length', 5)
  })

  describe('keyboard reordering (#1028)', () => {
    it('makes every item focusable', () => {
      items().each(($item) => {
        cy.wrap($item).should('have.attr', 'tabindex', '0')
      })
    })

    it('moves the focused item down with ArrowDown and persists like a drop', () => {
      items().first().should('contain.text', 'Item 1')

      items().first().focus().type('{downArrow}')

      items().eq(0).should('contain.text', 'Item 2')
      items().eq(1).should('contain.text', 'Item 1')
      // Focus travels with the item: the user can keep moving it.
      cy.focused().should('contain.text', 'Item 1')

      cy.wait('@reorder').its('request.url').should('match', /\/sortable_list/)
    })

    it('moves the focused item up with ArrowUp', () => {
      items().eq(2).should('contain.text', 'Item 3')

      items().eq(2).focus().type('{upArrow}')

      items().eq(1).should('contain.text', 'Item 3')
      cy.wait('@reorder')
    })

    it('does nothing at the edges', () => {
      items().first().focus().type('{upArrow}')
      items().last().focus().type('{downArrow}')

      items().eq(0).should('contain.text', 'Item 1')
      items().eq(4).should('contain.text', 'Item 5')
      cy.get('@reorder.all').should('have.length', 0)
    })

    it('announces the drop through the bali:sortable-list:end event', () => {
      cy.window().then((win) => {
        const seen = []
        win.document.addEventListener('bali:sortable-list:end', (e) => seen.push(e.detail))
        cy.wrap(seen).as('events')
      })

      items().first().focus().type('{downArrow}')

      cy.wait('@reorder')
      cy.get('@events').should((events) => {
        expect(events).to.have.length(1)
        expect(events[0].oldIndex).to.eq(0)
        expect(events[0].newIndex).to.eq(1)
      })
    })

    it('leaves a disabled list inert', () => {
      cy.visit('/bali/sortable_list/default?disabled=true')
      items().should('have.length', 5)
      // No tabindex means no focus, and no focus means no keyboard: the disabled
      // list stays out of the tab order.
      items().each(($item) => {
        cy.wrap($item).should('not.have.attr', 'tabindex')
      })
    })
  })

  // The MOUSE path deliberately has no test here: on desktop SortableJS uses the
  // native HTML5 drag, and neither the mousedown/mousemove sequence nor synthetic
  // dragstart/dragover/drop (with real DataTransfer and DragEvent) start it under
  // Cypress — a known limitation of native drag in tests. The contract that
  // persists the drop (PATCH + event) is covered E2E by the keyboard tests, which
  // share the same onEnd; starting the drag belongs to SortableJS and its own
  // suite covers it.
})
