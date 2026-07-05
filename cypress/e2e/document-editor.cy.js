// Uses the Lookbook preview (no DB dependency): the default preview renders
// the editor overlay with versions_url "/lookbook", so both the versions
// index and each version payload are stubbed with cy.intercept.
const stubVersions = [1, 2].map(id => ({
  id,
  version_number: id,
  summary: `Change ${id}`,
  author_name: 'Demo User',
  created_at: '2026-07-01T12:00:00Z'
}))

describe('DocumentEditor version preview', () => {
  beforeEach(() => {
    cy.intercept('GET', /\/lookbook$/, {
      headers: { 'Content-Type': 'application/json' },
      body: stubVersions
    }).as('versionsIndex')

    cy.intercept('GET', /\/lookbook\/\d+$/, req => {
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

    cy.visit('/bali/document_editor/default')
    editor().should('contain.text', 'Project Overview')
    cy.get('[data-action*="document-editor#toggleHistory"]:visible').first().click()
    cy.wait('@versionsIndex')
    cy.get('[data-action*="previewVersion"]:visible').should('have.length', 2)
  })

  const editor = () => cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')

  const previewVersion = id => {
    cy.get(`[data-action*="previewVersion"][data-version-id="${id}"]:visible`).click()
    cy.wait('@showVersion')
    editor().should('contain.text', `STUB VERSION ${id}`)
  }

  const backToCurrent = () => cy.get('[data-action*="exitPreview"]:visible').click()

  const assertBackOnCurrent = () => {
    editor().should('not.contain.text', 'STUB VERSION')
    editor().should('contain.text', 'Project Overview')
    editor().should('have.attr', 'contenteditable', 'true')
  }

  it('returns to the current version after a single preview', () => {
    previewVersion(1)
    backToCurrent()
    assertBackOnCurrent()
  })

  it('returns to the current version after previewing several versions in a row', () => {
    previewVersion(1)
    previewVersion(2)
    backToCurrent()
    assertBackOnCurrent()
  })
})
