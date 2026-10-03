// A modal built from content — the shared `#main-modal` of AppLayout, every remote modal — draws
// its own ✕, and it covered whatever the content put at the right of its first row: 16x14 px of a
// "New" tag at 1280 px wide and 24x22 at 390 (#1286).
describe('Modal: the close button of a modal built from content', () => {
  const overlap = (a, b) => {
    const w = Math.min(a.right, b.right) - Math.max(a.left, b.left)
    const h = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top)
    return w > 0 && h > 0 ? `${Math.round(w)}x${Math.round(h)}` : 'none'
  }

  // The box scales in when it opens, and a rect read mid-transition is the wrong size.
  const measure = (fn) => {
    cy.get('dialog.modal-component').should(($dialog) => {
      const dialog = $dialog[0]
      expect(dialog.matches(':modal'), 'open').to.equal(true)
      const box = dialog.querySelector('.modal-box')
      expect(box.getAnimations({ subtree: true }), 'transitions settled').to.have.length(0)
      const closeButton = box.querySelector(':scope > [data-action="modal#close"]')
      fn({ box, boxRect: box.getBoundingClientRect(), closeButton, close: closeButton.getBoundingClientRect() })
    })
  }

  const VIEWPORTS = [[1280, 800], [390, 844]]

  VIEWPORTS.forEach(([width, height]) => {
    context(`${width}px wide`, () => {
      beforeEach(() => {
        cy.viewport(width, height)
        cy.visit('/bali/modal/content_header')
      })

      it('leaves the right end of the first row uncovered', () => {
        measure(({ box, close }) => {
          const tag = box.querySelector('.modal-inner .badge').getBoundingClientRect()
          expect(overlap(close, tag), 'the tag under the close button').to.equal('none')
        })
      })

      it('keeps the close button 8px from the corner of the panel', () => {
        measure(({ boxRect, close }) => {
          expect(Math.round(close.top - boxRect.top), 'from the top').to.equal(8)
          expect(Math.round(boxRect.right - close.right), 'from the right').to.equal(8)
        })
      })

      // A float shortens the lines beside it, never the box around them: the paragraph's box stays
      // full width with the float reaching into its lines, so those are measured too.
      it('gives the content below the first row its full width', () => {
        measure(({ box, boxRect, closeButton, close }) => {
          const paragraph = box.querySelector('.modal-inner p')
          const padding = parseFloat(getComputedStyle(box).paddingRight)
          expect(Math.round(boxRect.right - padding - paragraph.getBoundingClientRect().right), 'px short of the padding').to.equal(0)

          const floatBottom = close.bottom + parseFloat(getComputedStyle(closeButton).marginBottom)
          const range = paragraph.ownerDocument.createRange()
          range.selectNodeContents(paragraph)
          const firstLine = Math.min(...[...range.getClientRects()].map((line) => line.top))
          expect(Math.round(floatBottom - firstLine), 'px the float reaches into the paragraph').to.be.at.most(0)
        })
      })
    })
  })
})
