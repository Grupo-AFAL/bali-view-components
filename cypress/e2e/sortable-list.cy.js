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

  // A pointerdown is enough to make SortableJS hold an item (`.sortable-chosen`): the native
  // drag that follows is what Cypress cannot start (see below).
  describe('disconnect (#1409)', () => {
    const sortableOf = (list) => list.ownerDocument.defaultView.Stimulus
      .getControllerForElementAndIdentifier(list, 'sortable-list')?.sortable
    const press = { button: 0, pointerType: 'mouse', eventConstructor: 'PointerEvent' }

    beforeEach(() => {
      cy.get('.sortable-list-component').should(($lists) => {
        $lists.each((_, list) => expect(sortableOf(list)).to.exist)
      })
    })

    it('destroys its Sortable when the list leaves the page', () => {
      cy.get('.sortable-list-component').then(($list) => {
        const Sortable = sortableOf($list[0]).constructor
        $list[0].remove()
        cy.wrap($list[0]).should((list) => expect(Sortable.get(list)).to.equal(null))
      })
    })

    it('builds a new one when the list comes back', () => {
      cy.get('.sortable-list-component').then(($list) => {
        const list = $list[0]
        const parent = list.parentNode
        const Sortable = sortableOf(list).constructor
        list.remove()
        cy.wrap(list).should((l) => expect(Sortable.get(l)).to.equal(null)).then(() => parent.append(list))
        cy.wrap(list).should((l) => {
          expect(Sortable.get(l)).to.be.an('object')
          expect(sortableOf(l)).to.equal(Sortable.get(l))
        })
      })
    })

    // SortableJS moves the item it drags, and a list nested in that item disconnects and
    // connects again on every move: destroying it then would let go of the item.
    it('keeps holding an item whose nested list moves with it', () => {
      const root = '[data-sortable-list-list-id-value="root"]'
      const holder = `${root} > .sortable-item:has([data-sortable-list-list-id-value="item-5"])`
      cy.visit('/bali/sortable_list/nested')
      cy.get('.sortable-list-component').should('have.length', 2).and(($lists) => {
        $lists.each((_, list) => expect(sortableOf(list)).to.exist)
      })

      cy.get(`${holder} > p`).trigger('pointerdown', press)
      cy.get(holder).should('have.class', 'sortable-chosen').then(($item) => {
        $item[0].parentNode.insertBefore($item[0], $item[0].previousElementSibling)
      })
      // Stimulus hears of the move from a MutationObserver, which fires after a task of the page's own.
      cy.window().then((win) => new Cypress.Promise((resolve) => win.setTimeout(resolve)))
      cy.document().trigger('pointerup', press)

      cy.get(holder).should('not.have.class', 'sortable-chosen')
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
