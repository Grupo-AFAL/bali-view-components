// #707 -- the history panel against the REAL engine endpoints, not stubs.
// document-editor.cy.js already covers the JavaScript with cy.intercept; this one exists to
// catch what a stub cannot: routing, the JSON the engine actually serves, and the restore
// round-trip through Bali::ContentVersionsController.
//
// The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin is
// derived from it rather than written out: a literal `http://localhost:3001` ignores
// CYPRESS_BASE_URL and quietly tests another server.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const documentPath = `${appOrigin}/documents/1`

// Seeded documents keep their versions, and every restore in this file adds one more, so
// nothing here asserts an absolute count -- only what changed.
const versionsUrl = `${appOrigin}/bali/content_versions?record_type=Document&record_id=1`

const fetchVersions = () => cy.request({ url: versionsUrl, headers: { Accept: 'application/json' } }).its('body')

// The editor overlay pulls in the BlockNote bundle, which on a cold server takes longer than
// the default command timeout -- so this waits for the panel to actually paint instead of
// letting the next command race it.
const openHistory = () => {
  cy.visit(documentPath)
  cy.contains('button', 'Edit').click()
  cy.get('[data-action*="document-editor#toggleHistory"]:visible', { timeout: 20000 }).first().click()
  cy.get('[data-document-editor-target="historyPanel"]:visible .version-item', { timeout: 20000 })
    .should('exist')
}

const items = () => cy.get('[data-document-editor-target="historyPanel"]:visible .version-item')

describe('DocumentEditor history against the engine', () => {
  it('lists the seeded versions newest first, with author and summary', () => {
    fetchVersions().then(versions => {
      expect(versions.length, 'seeded versions').to.be.greaterThan(0)
      const newest = versions[0]

      openHistory()

      items().should('have.length', versions.length)
      items().first().within(() => {
        cy.get('[data-version-field="number"]').should('have.text', `v${newest.version_number}`)
        cy.get('[data-version-field="author"]').should('have.text', newest.author_name)
        if (newest.summary) {
          cy.get('[data-version-field="summary"]').should('be.visible').and('have.text', newest.summary)
        }
      })

      // Every version carries its own url, and the JS uses it verbatim -- a host that
      // mounts the engine somewhere other than /bali must keep working.
      items().first().find('[data-action*="previewVersion"]')
        .should('have.attr', 'data-version-url', newest.url)
    })
  })

  it('loads a version into the editor read-only and comes back', () => {
    openHistory()

    items().last().find('[data-action*="previewVersion"]').click()

    cy.get('[data-document-editor-target="previewBanner"]:visible').should('exist')
    cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
      .should('have.attr', 'contenteditable', 'false')

    cy.get('[data-action*="exitPreview"]:visible').click()
    cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
      .should('have.attr', 'contenteditable', 'true')
  })

  it('restores a version and records a new one naming where it came from', () => {
    fetchVersions().then(before => {
      const oldest = before[before.length - 1]

      openHistory()
      items().last().find('[data-action*="restoreVersion"]').click()
      cy.get('dialog[open]').contains('button', 'Restore').click()

      // The controller reloads the page on success.
      cy.location('pathname').should('eq', '/documents/1')

      fetchVersions().then(after => {
        expect(after.length).to.eq(before.length + 1)
        expect(after[0].summary).to.eq(`Restored from v${oldest.version_number}`)
        expect(after[0].version_number).to.eq(before[0].version_number + 1)
      })
    })
  })
})
