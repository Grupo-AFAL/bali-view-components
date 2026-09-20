// #706 — the only test that proves a comment SURVIVES.
//
// Lookbook previews use the InMemoryThreadStore: there is no server behind them, so they
// can pass green with the engine broken. This one runs against the dummy page that does
// consume the engine (`/documents/:id`, `comments: { url: :auto, commentable: @document }`)
// and makes the full round trip: write a comment through BlockNote's UI, see the engine's
// 201, reload the page and find it again — which can only come from the database.
//
// A single `it` on purpose: the state under test is exactly what survives between the two
// halves, and Cypress clears aliases between tests.
//
// The origin comes from the configured baseUrl and not from a literal, because each
// worktree runs its dummy on a different port.
const origin = new URL(Cypress.config('baseUrl')).origin

const TEXT = `comentario persistente ${Date.now()}`

const overlay = () => cy.get('#document-editor-overlay')

const openEditor = () => {
  cy.contains('button', 'Edit').click()
  overlay().find('.bn-editor', { timeout: 30000 }).should('be.visible')
}

describe('BlockEditor: comments survive a reload', () => {
  it('writes a comment, the engine stores it and it is still there after reloading', () => {
    cy.viewport(1400, 900)
    cy.intercept('POST', '**/bali/block_editor_comments?*').as('createThread')
    cy.intercept('GET', '**/bali/block_editor_comments?*').as('listThreads')

    // The id is not written by hand: the seeds use find_or_initialize_by and do not pin them.
    // The numeric filter drops /documents/new, which is the first link in the listing.
    cy.visit(`${origin}/documents`)
    cy.get('a[href^="/documents/"]')
      .filter((_i, el) => /^\/documents\/\d+$/.test(el.getAttribute('href')))
      .first().invoke('attr', 'href').then(documentPath => {
        cy.visit(`${origin}${documentPath}`)
        openEditor()

        // A comment needs text to anchor to: without a selection the formatting toolbar
        // does not appear and the comment button does not exist.
        overlay().find('.bn-editor').first().click().type('{selectall}')
        cy.get('[aria-label="Add comment"]', { timeout: 10000 }).should('be.visible').click()

        // The composer mounts its own BlockNote editor and takes the focus.
        cy.get('.bn-comment-editor [contenteditable="true"]', { timeout: 10000 })
          .should('be.visible')
          .type(TEXT)

        // Scoped to `.bn-thread` on purpose: the DocumentEditor has its own "Save" button
        // in the top bar and that is the one that wins without the scope — it saves the
        // document and discards the pending comment, with no assertion noticing.
        cy.get('.bn-comment-editor').closest('.bn-thread').contains('button', 'Save').click()

        cy.wait('@createThread').its('response.statusCode').should('eq', 201)

        // The reload is the point: after it the text cannot come from anywhere other than
        // the engine's GET, because the document's mark does not carry it.
        cy.visit(`${origin}${documentPath}`)
        openEditor()
        overlay().find('.bn-threads-sidebar', { timeout: 30000 }).should('contain.text', TEXT)

        // And that the engine served it, not a browser cache. ALL the calls are checked
        // and not the next one: the page mounts two editors and both poll, so `cy.wait`
        // would return any GET — including the empty one from before the comment was
        // written.
        cy.get('@listThreads.all').then(calls => {
          const served = calls.some(({ response }) => JSON.stringify(response.body).includes(TEXT))
          expect(served, 'some engine GET returned the thread').to.equal(true)
        })
      })
  })
})
