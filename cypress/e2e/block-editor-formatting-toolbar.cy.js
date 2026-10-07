// `with_comments` carries the widest bar Bali renders by default (519px); the DocumentEditor
// leaves the narrowest editor on a phone (224px at 320px), which is what tells a bar sized to
// the screen from one sized to the editor. So does a narrow editor on a desktop.
const BLOCK_EDITOR = 'bali/block_editor/with_comments'
const DOCUMENT_EDITOR = 'bali/document_editor/default'
const PLAIN_EDITOR = 'bali/block_editor/with_initial_content'

// A real selection, not `{selectall}`: the bar has to float next to a word to show that the
// second row does not land on the text being edited.
const selectFirstWord = () => {
  cy.get('.bn-editor [data-content-type="paragraph"] .bn-inline-content').first().click().then(($paragraph) => {
    const doc = $paragraph[0].ownerDocument
    const text = doc.createTreeWalker($paragraph[0], doc.defaultView.NodeFilter.SHOW_TEXT).nextNode()
    const range = doc.createRange()
    range.setStart(text, 0)
    range.setEnd(text, text.data.indexOf(' '))
    doc.getSelection().removeAllRanges()
    doc.getSelection().addRange(range)
  })
}

const rowsOf = bar => new Set([...bar.children].map(item => Math.round(item.getBoundingClientRect().top))).size

describe('BlockEditor: the formatting toolbar', () => {
  [[BLOCK_EDITOR, 'BlockEditor'], [DOCUMENT_EDITOR, 'DocumentEditor']].forEach(([preview, editor]) => {
    [320, 360, 390].forEach((width) => {
      it(`wraps onto two rows instead of scrolling in a ${editor} at ${width}px`, () => {
        cy.viewport(width, 844)
        cy.visit(preview)
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
          expect(box.left, 'the bar is inside the screen').to.be.at.least(0)
          expect(box.right, 'on both sides').to.be.at.most(width)
          expect(rowsOf(bar), 'rows').to.equal(2)
          expect(box.bottom <= word.top || box.top >= word.bottom, 'the bar clears the selected word').to.equal(true)
        })
      })
    })
  })

  it('stays on one row on a desktop', () => {
    cy.viewport(1280, 900)
    cy.visit(BLOCK_EDITOR)
    selectFirstWord()

    cy.get('.bn-formatting-toolbar').should(($bar) => {
      expect(rowsOf($bar[0]), 'rows').to.equal(1)
      expect($bar[0].scrollWidth, 'the bar does not scroll sideways').to.be.at.most($bar[0].clientWidth)
    })
  })

  it('stays on one row in a desktop editor narrower than the bar', () => {
    cy.viewport(1280, 900)
    cy.visit(PLAIN_EDITOR)
    cy.get('.bn-editor [data-content-type="paragraph"]').should('exist')
    cy.get('.block-editor-component').invoke('css', 'width', '320px')
    selectFirstWord()

    cy.get('.bn-formatting-toolbar').should(($bar) => {
      expect($bar[0].getBoundingClientRect().width, 'the bar is wider than the editor').to.be.greaterThan(320)
      expect(rowsOf($bar[0]), 'rows').to.equal(1)
    })
  })
})
