// #1212: Turbo's head merge removed BlockNote's identical placeholder <style>s before their
// editors' teardown, which then threw NotFoundError. An uncaught error fails the test by itself.
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
    // What Turbo's head merge keys on: identical markup is a duplicate it removes.
    cy.document().should((doc) => {
      const styles = placeholderStyles(doc)
      expect(styles).to.have.length.at.least(3)
      expect(new Set(styles.map(style => style.outerHTML)).size).to.equal(styles.length)
    })

    cy.window().then((win) => {
      win.Turbo.visit(win.location.pathname.replace(/block_editor\/.*$/, 'button/default'))
    })

    cy.location('pathname').should('match', /button\/default$/)
    // None left behind: Turbo no longer removes them, so only their own editors can.
    cy.document().should(doc => expect(placeholderStyles(doc)).to.have.length(0))
  })
})
