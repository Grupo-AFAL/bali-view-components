// BlockNote's placeholder plugin puts an empty `<style>` in the head for each editor and
// removes it when the editor is destroyed. Turbo's head merge used to delete all but one of
// them as duplicates first, and every comment editor's teardown then threw NotFoundError
// from inside React's unmount (#1212). An uncaught error fails the test by itself.
describe('BlockEditor: leaving the page through Turbo', () => {
  // Found by their rule, not by markup: the style element itself is empty.
  const placeholderStyles = doc => [...doc.head.querySelectorAll('style')].filter((style) => {
    try {
      return /^\.placeholder-selector-/.test(style.sheet?.cssRules[0]?.selectorText)
    } catch {
      return false
    }
  })

  it('tears down every editor, the comment editors included, without an error', () => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    cy.get('.bn-threads-sidebar .ProseMirror').should('have.length.at.least', 2)
    cy.document().should(doc => expect(placeholderStyles(doc)).to.have.length.at.least(3))

    cy.window().then((win) => {
      win.Turbo.visit(win.location.pathname.replace(/block_editor\/.*$/, 'button/default'))
    })

    cy.location('pathname').should('match', /button\/default$/)
    // Removed by each editor's own teardown, which is the part that used to throw.
    cy.document().should(doc => expect(placeholderStyles(doc)).to.have.length(0))
  })
})
