// #1370: in a narrow column the CTA spilled its text ON TOP of the file name. The whole bug is
// geometry — every class assertion in file_fields_test.rb passed the entire time it was
// happening — so these measure the boxes. The first four fail on the code before the fix; the
// last one passed before it too, and is here to hold the promise that a column with room
// renders exactly as it always did.
describe('FileField layout', () => {
  const wrapper = () => cy.get('[data-controller~="file-input"]')
  const label = () => cy.get('[data-controller~="file-input"] label')
  const cta = () => cy.get('[data-controller~="file-input"] label span.btn')
  const fileName = () => cy.get('[data-file-input-target="value"]')

  const pickFile = name =>
    cy.get('input[type="file"]').selectFile(
      { contents: Cypress.Buffer.from('x'), fileName: name, mimeType: 'application/pdf' },
      { force: true } // the native input is `display: none` by design
    )

  const assertBoxesDoNotIntersect = () => {
    cta().then($cta => {
      fileName().then($name => {
        const a = $cta[0].getBoundingClientRect()
        const b = $name[0].getBoundingClientRect()
        const intersects =
          a.right > b.left && b.right > a.left && a.bottom > b.top && b.bottom > a.top

        expect(
          intersects,
          `CTA ${JSON.stringify(a)} over the file name ${JSON.stringify(b)}`
        ).to.equal(false)
      })
    })
  }

  context('in a 240px column', () => {
    beforeEach(() => {
      cy.visit('/bali/form/file/narrow')
    })

    it('keeps the CTA clear of the placeholder', () => {
      assertBoxesDoNotIntersect()
    })

    it('keeps the CTA clear of a long file name', () => {
      pickFile('acta-de-la-reunion-de-compras-y-finanzas-2026-10-07.pdf')

      fileName().should('contain.text', 'acta-de-la-reunion')
      assertBoxesDoNotIntersect()
    })

    // `shrink-0`, stated as what it buys. The label is the flex item that was shrinking; the
    // `.btn` inside it kept its own width and overflowed, which is where the overlap came from,
    // so the measurement belongs on the label and not on the button.
    it('does not squeeze the label below the button it holds', () => {
      label().then($label => {
        expect($label[0].scrollWidth).to.be.at.most($label[0].clientWidth)
      })
    })

    // `min-w-32` + `flex-wrap`. With only `shrink-0` the overlap is gone but the name is left
    // with 36px — `N…`, which says nothing about whether a file was picked.
    it('drops the file name to its own row instead of a sliver', () => {
      fileName().then($name => {
        label().then($label => {
          const name = $name[0].getBoundingClientRect()
          expect(name.top).to.be.at.least($label[0].getBoundingClientRect().bottom)
          expect(name.width).to.be.at.least(128)
        })
      })
      fileName().should($name => {
        expect($name[0].scrollWidth).to.be.at.most($name[0].clientWidth)
      })
    })
  })

  // The guard, not a cover: this passed before the fix as well. Nothing may move for a host
  // whose column was wide enough all along.
  context('in a column with room', () => {
    beforeEach(() => {
      cy.visit('/bali/form/file/default')
    })

    it('keeps the CTA and the file name on one row', () => {
      fileName().then($name => {
        label().then($label => {
          const name = $name[0].getBoundingClientRect()
          const cta = $label[0].getBoundingClientRect()
          expect(name.top).to.be.lessThan(cta.bottom)
          expect(name.left).to.be.at.least(cta.right)
        })
      })
      wrapper().then($w => {
        expect($w[0].scrollWidth).to.be.at.most($w[0].clientWidth)
      })
    })
  })
})
