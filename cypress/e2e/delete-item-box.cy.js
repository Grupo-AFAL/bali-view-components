// `button_to` wraps its button in a `<form>`, and daisyUI paints the menu item on
// `li > *` unless it is a `.btn`. The form is not, so it took the item's padding, radius
// and hover while the button sat inside with a second box of its own: Delete measured
// 192x49 with a 168x37 hover inside it, against Edit's 192x37 (#829).
//
// The fix is `display: contents` on the form, and what this test guards is the CASCADE,
// which is where it can break without any Ruby assert failing. The default lives in
// @layer components (`.bali-delete-link-form`) precisely so that the call site's utility
// beats it: as a utility on the element the two tied on layer and specificity, and the
// compiled sheet broke the tie — measured, `.contents` is emitted BEFORE
// `.inline-block`, so `class="inline-block contents"` renders inline-block and
// `form_class` did nothing.
describe('A menu Delete item is the same box as its neighbors', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/actions_dropdown/default')
    cy.get('[data-dropdown-target="trigger"]').first().click()
  })

  // The rect is returned and not the node: whatever comes out of a `.then` gets re-wrapped
  // by Cypress, and an `<li>` returned there comes back as a subject, not an element.
  const itemBoxOf = text =>
    cy.contains('li > *', text).then($el => {
      const r = $el[0].closest('li').getBoundingClientRect()
      return { w: Math.round(r.width), h: Math.round(r.height) }
    })

  it('the form generates no box, so the button IS the item', () => {
    cy.get('li > form').first().should($form => {
      expect(window.getComputedStyle($form[0]).display, 'the form draws no box')
        .to.equal('contents')
    })
  })

  it('Delete measures the same as a link item', () => {
    itemBoxOf('Edit').then(linkItem => {
      itemBoxOf('Delete').then(deleteItem => {
        expect(deleteItem.h, 'same height').to.equal(linkItem.h)
        expect(deleteItem.w, 'same width').to.equal(linkItem.w)
      })
    })
  })

  // The second half of the defect: two nested hover boxes, one with a 4px radius inside
  // another of 8px. With the form out of the tree only one remains.
  it('the button fills its item, with no second box inside', () => {
    cy.contains('li > form button', 'Delete').should($btn => {
      const button = $btn[0].getBoundingClientRect()
      const item = $btn[0].closest('li').getBoundingClientRect()

      expect(Math.round(button.width), 'the button is not squeezed in').to.equal(Math.round(item.width))
      expect(Math.round(button.left)).to.equal(Math.round(item.left))
    })
  })
})
