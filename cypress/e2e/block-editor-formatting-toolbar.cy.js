// BlockNote lays its formatting toolbar out in one row that scrolls sideways (`nowrap` with
// `overflow-x: auto`). At 390px the row scrolled, the block type select shrank from 129px to
// 19px and the comment button sat past the right edge of the screen; Bali wraps it instead.
// Measured with comments on, the widest bar Bali renders by default (519px).
const PREVIEW = 'bali/block_editor/with_comments'

// A real selection, not `{selectall}`: the bar has to float next to a word to show that the
// second row does not land on the text being edited.
const selectFirstWord = () => {
  cy.get('.bn-editor [data-content-type="paragraph"] .bn-inline-content').first().click().then(($paragraph) => {
    const doc = $paragraph[0].ownerDocument
    const range = doc.createRange()
    range.setStart($paragraph[0].firstChild, 0)
    range.setEnd($paragraph[0].firstChild, 'Select'.length)
    doc.getSelection().removeAllRanges()
    doc.getSelection().addRange(range)
  })
}

const rowsOf = bar => new Set([...bar.children].map(item => Math.round(item.getBoundingClientRect().top))).size

describe('BlockEditor: the formatting toolbar', () => {
  beforeEach(() => {
    cy.visit(PREVIEW)
    cy.get('.bn-editor [data-content-type="paragraph"]').should('exist')
  })

  it('wraps onto a second row on a phone instead of scrolling', () => {
    cy.viewport(390, 844)
    selectFirstWord()

    cy.get('.bn-formatting-toolbar').should(($bar) => {
      const bar = $bar[0]
      const box = bar.getBoundingClientRect()
      const select = bar.querySelector('[aria-haspopup="menu"]')
      const comment = bar.querySelector('[data-test="addcomment"]').getBoundingClientRect()
      const word = bar.ownerDocument.getSelection().getRangeAt(0).getBoundingClientRect()

      expect(bar.scrollWidth, 'the bar does not scroll sideways').to.be.at.most(bar.clientWidth)
      expect(select.scrollWidth, 'the block type select keeps its width').to.be.at.most(select.clientWidth)
      expect(comment.right, 'the comment button is inside the bar').to.be.at.most(box.right)
      expect(comment.left, 'and inside the screen').to.be.at.least(0)
      expect(comment.right, 'on both sides').to.be.at.most(bar.ownerDocument.defaultView.innerWidth)
      expect(rowsOf(bar), 'rows').to.equal(2)
      expect(box.bottom <= word.top || box.top >= word.bottom, 'the bar clears the selected word').to.equal(true)
    })
  })

  it('stays on one row on a desktop', () => {
    cy.viewport(1280, 900)
    selectFirstWord()

    cy.get('.bn-formatting-toolbar').should(($bar) => {
      expect(rowsOf($bar[0]), 'rows').to.equal(1)
      expect($bar[0].scrollWidth, 'the bar does not scroll sideways').to.be.at.most($bar[0].clientWidth)
    })
  })
})
