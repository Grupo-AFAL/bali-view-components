describe('DocumentEditor version preview', () => {
  beforeEach(() => {
    // Stub version payloads so previewed content is distinguishable from the
    // current document regardless of DB state
    cy.intercept('GET', /\/documents\/\d+\/versions\/\d+$/, req => {
      const id = req.url.split('/').pop()
      req.reply({
        id: Number(id),
        version_number: Number(id),
        content: [
          {
            id: `stub-${id}`,
            type: 'paragraph',
            props: {},
            content: [{ type: 'text', text: `STUB VERSION ${id}`, styles: {} }],
            children: []
          }
        ]
      })
    }).as('showVersion')

    cy.visit('http://localhost:3001/documents/1')
    cy.contains('button', 'Edit').click()
    cy.get('[data-action*="document-editor#toggleHistory"]:visible').first().click()
    cy.get('[data-action*="previewVersion"]:visible').should('have.length.at.least', 2)

    editor()
      .invoke('text')
      .then(text => cy.wrap(text.slice(0, 40)).as('currentText'))
  })

  const editor = () => cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')

  const previewNth = n =>
    cy.get('[data-action*="previewVersion"]:visible').eq(n).then($btn => {
      const stubText = `STUB VERSION ${$btn.data('versionId')}`
      cy.wrap($btn).click()
      cy.wait('@showVersion')
      editor().should('contain.text', stubText)
    })

  const backToCurrent = () => cy.get('[data-action*="exitPreview"]:visible').click()

  const assertBackOnCurrent = () => {
    editor().should('not.contain.text', 'STUB VERSION')
    cy.get('@currentText').then(currentText => {
      editor().invoke('text').should(text => {
        expect(text.slice(0, 40)).to.eq(currentText)
      })
    })
    editor().should('have.attr', 'contenteditable', 'true')
  }

  it('returns to the current version after a single preview', () => {
    previewNth(0)
    backToCurrent()
    assertBackOnCurrent()
  })

  it('returns to the current version after previewing several versions in a row', () => {
    previewNth(0)
    previewNth(1)
    backToCurrent()
    assertBackOnCurrent()
  })
})
