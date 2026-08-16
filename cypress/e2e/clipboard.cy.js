// #1041 — Clipboard had no E2E spec. Two things can go wrong and neither is
// visible in the markup: WHAT gets copied (the source is read with `innerText`,
// and the source box truncates with CSS — the user must get the whole string,
// not what fits) and the trigger swap, which replaces the button's innerHTML
// and has to put the original back afterwards.
describe('Clipboard', () => {
  const trigger = () => cy.get('[data-clipboard-target="button"]')

  const visitWithStubbedClipboard = (path) => {
    cy.visit(path, {
      onBeforeLoad (win) {
        // Writing to the real clipboard needs a permission prompt no test can
        // answer, and the question here is what the component hands over.
        cy.stub(win.navigator.clipboard, 'writeText').resolves().as('writeText')
      }
    })
  }

  it('copies the source text', () => {
    visitWithStubbedClipboard('/bali/clipboard/default')

    trigger().click()

    cy.get('@writeText').should(
      'have.been.calledOnceWith',
      'https://example.com/api/v1/token/abc123xyz'
    )
  })

  it('copies the whole string even where the box truncates it', () => {
    visitWithStubbedClipboard('/bali/clipboard/long_text')

    trigger().click()

    cy.get('@writeText').should(
      'have.been.calledOnceWith',
      'https://example.com/very/long/url/path/that/should/be/truncated/when/displayed'
    )
  })

  it('shows the success content and restores the trigger afterwards', () => {
    visitWithStubbedClipboard('/bali/clipboard/default')

    trigger().find('svg').invoke('attr', 'class').should('exist')
    trigger().then(($button) => {
      const original = $button.html()

      // The success mark is in the DOM from the start, hidden; the controller
      // copies its HTML into the button rather than building anything.
      cy.get('[data-clipboard-target="successContent"]').should('not.be.visible')

      cy.clock()
      trigger().click()

      cy.get('[data-clipboard-target="successContent"]').then(($success) => {
        trigger().should('have.html', $success.html())
      })

      // successDurationValue defaults to 2000ms.
      cy.tick(1999)
      cy.get('[data-clipboard-target="successContent"]').then(($success) => {
        trigger().should('have.html', $success.html())
      })

      cy.tick(1)
      trigger().should('have.html', original)
    })
  })

  it('does not restore a stale trigger when clicked twice', () => {
    visitWithStubbedClipboard('/bali/clipboard/default')

    trigger().then(($button) => {
      const original = $button.html()

      cy.clock()
      trigger().click()
      cy.tick(1500)
      // The second copy has to reset the countdown: otherwise the mark from the
      // click the user just made disappears 500ms later.
      trigger().click()
      cy.tick(1500)

      cy.get('[data-clipboard-target="successContent"]').then(($success) => {
        trigger().should('have.html', $success.html())
      })

      cy.tick(500)
      trigger().should('have.html', original)
    })
  })
})
