// daisyUI's `.card-body p { flex-grow: 1 }` stretched the empty `<p>` of a block, and with it
// pushed the placeholder (that block's `::after`) to the right edge of the Card (#1455).

const openPreview = () => {
  cy.visit('/bali/block_editor/in_card')
  cy.get('#content-editor [data-content-type="paragraph"]').should('exist')
}

describe('BlockEditor inside a Card', () => {
  it('starts the placeholder of an empty block at the left edge', () => {
    openPreview()
    cy.get('#empty-editor .bn-editor').click()

    cy.get('#empty-editor .bn-block-content').should(([block]) => {
      const paragraph = block.querySelector('.bn-inline-content')
      const after = getComputedStyle(block, '::after')

      expect(after.content, 'placeholder showing').to.eq('"Start typing..."')
      // The `::after` begins where the `<p>` ends, less BlockNote's -2px margin on it.
      const start = paragraph.getBoundingClientRect().right + parseFloat(after.marginLeft)
      expect(start - block.getBoundingClientRect().left, 'placeholder offset from the left edge').to.be.closeTo(0, 0.5)
    })
  })

  // `flex: none` also puts the placeholder at the left edge, so only this test catches it.
  it('still wraps a long paragraph at the editor width', () => {
    openPreview()

    cy.get('#content-editor [data-content-type="paragraph"]').first().should(([block]) => {
      const paragraph = block.querySelector('.bn-inline-content')
      const lineHeight = parseFloat(getComputedStyle(paragraph).lineHeight)

      expect(paragraph.getBoundingClientRect().right, 'right edge').to.be.at.most(block.getBoundingClientRect().right + 0.5)
      expect(paragraph.getBoundingClientRect().height, 'height').to.be.above(2 * lineHeight)
    })
  })
})
