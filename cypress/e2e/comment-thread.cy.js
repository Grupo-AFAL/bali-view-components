// The thread's promise to a host: comments come and go through plain `append`,
// `prepend` and `remove` streams against the list's id, and the empty state follows
// on its own. It is a CSS contract (`hidden only:block`), so only a browser sees it.
describe('CommentThread', () => {
  const emptyState = () => cy.get('#comments > li.comment-thread-empty')
  const stream = (action, target, html = '') => cy.window().then(win => {
    win.Turbo.renderStreamMessage(
      `<turbo-stream action="${action}" target="${target}"><template>${html}</template></turbo-stream>`
    )
  })
  const comment = id => `<li id="${id}" class="comment-thread-comment">Streamed</li>`

  context('with no comments', () => {
    beforeEach(() => cy.visit('/bali/comment_thread/empty'))

    it('shows the empty state', () => {
      emptyState().should('be.visible').and('contain.text', 'No comments yet.')
    })

    it('hides it when the first comment is appended, and shows it when that one is removed', () => {
      stream('append', 'comments', comment('comment_new'))
      cy.get('#comment_new').should('be.visible')
      emptyState().should('not.be.visible')

      stream('remove', 'comment_new')
      cy.get('#comment_new').should('not.exist')
      emptyState().should('be.visible')
    })

    it('hides it when the first comment is prepended, ahead of it', () => {
      stream('prepend', 'comments', comment('comment_new'))
      cy.get('#comments > li').first().should('have.id', 'comment_new')
      emptyState().should('not.be.visible')
    })
  })

  // Both used to be fixed by hand in a host (afal-apps, TDF-017): daisyUI's `.avatar`
  // centres itself in the row, and a long URL with no break pushed the comment out of
  // its card. #comment_2 carries such a URL, and at phone width it wraps over many lines.
  context('at phone width', () => {
    beforeEach(() => {
      cy.viewport(375, 800)
      cy.visit('/bali/comment_thread/default')
    })

    it('keeps the avatar at the top of a long comment', () => {
      cy.get('#comment_2').then(($li) => {
        const avatar = $li[0].querySelector('.avatar').getBoundingClientRect()
        expect(avatar.top).to.equal($li[0].getBoundingClientRect().top)
      })
    })

    it('wraps a long URL inside the comment', () => {
      cy.get('#comment_2').should(($li) => {
        expect($li[0].scrollWidth).to.be.at.most($li[0].clientWidth)
      })
    })
  })

  context('with comments', () => {
    beforeEach(() => cy.visit('/bali/comment_thread/default'))

    it('keeps the empty state hidden until the last comment is removed', () => {
      emptyState().should('exist').and('not.be.visible')

      stream('remove', 'comment_1')
      stream('remove', 'comment_2')
      cy.get('#comment_2').should('not.exist')
      emptyState().should('not.be.visible')

      stream('remove', 'comment_3')
      cy.get('#comment_3').should('not.exist')
      emptyState().should('be.visible')
    })
  })
})
