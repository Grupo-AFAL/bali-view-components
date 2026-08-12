// #1028 — SortableList no tenía spec E2E (16 componentes con JS sin cobertura;
// este es de los de mayor riesgo: reordenar persiste con un PATCH). Cubre el
// camino de ratón (SortableJS) y la alternativa de teclado nueva (WCAG 2.1.1):
// foco en el ítem + ArrowUp/ArrowDown mueven un puesto y persisten igual que
// un drop.
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
      // El foco viaja con el ítem: el lector puede seguir moviéndolo.
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
      // Sin tabindex no hay foco, y sin foco no hay teclado: la lista
      // deshabilitada queda fuera del orden de tabulación.
      items().each(($item) => {
        cy.wrap($item).should('not.have.attr', 'tabindex')
      })
    })
  })

  // El camino de RATÓN no tiene test aquí a propósito: en desktop SortableJS
  // usa el drag nativo de HTML5, y ni la secuencia mousedown/mousemove ni
  // dragstart/dragover/drop sintéticos (con DataTransfer y DragEvent reales)
  // lo arrancan bajo Cypress — limitación conocida del drag nativo en tests.
  // El contrato que persiste el drop (PATCH + evento) queda cubierto E2E por
  // los tests de teclado, que comparten el mismo onEnd; el arranque del drag
  // es de SortableJS y lo cubre su propia suite.
})
