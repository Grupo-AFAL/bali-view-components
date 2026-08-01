// The preview tree is a docs sidebar; `Guides` is expanded because the current
// path is one of its children.
const PREVIEW = '/lookbook/preview/bali/tree_view/default'
const PARENT = '/docs/guides'
const CHILD = '/docs/guides/basic-usage'

const item = (path) => `li.tree-view-item-component[data-tree-view-item-url-value="${path}"]`

// Turbo.visit is a getter-only property on window.Turbo, so it cannot be stubbed
// in a way the controller sees. Serve the destinations instead and assert where
// the browser actually ended up — which is the thing the bug was about anyway.
const serveDestinations = () => {
  cy.intercept('GET', '/docs/**', {
    statusCode: 200,
    headers: { 'content-type': 'text/html' },
    body: '<html><head><title>landed</title></head><body><h1>landed</h1></body></html>'
  }).as('navigation')
}

// Every Turbo.visit fires one turbo:visit. Counting them is how the double
// dispatch becomes visible: two controllers acting on one click ask for two
// pages, even when the browser happens to settle on one of the two URLs. The
// array lives in the spec, not on the page, because the navigation replaces the
// page's window and would take the record with it.
let visits

const recordVisits = () => {
  visits = []
  cy.window().then((win) => {
    win.addEventListener('turbo:visit', (e) => visits.push(new URL(e.detail.url).pathname))
  })
}

const visitedPaths = () => cy.then(() => visits)

describe('TreeViewItemController', () => {
  beforeEach(() => {
    serveDestinations()
    cy.visit('/bali/tree_view/default')
    recordVisits()
  })

  context('navigation', () => {
    // A child <li> is nested inside its parent's <li>, so its clicks bubble through
    // every ancestor's controller. Only one of them may ask for a page: two would
    // race and the outermost would win, landing you on the parent.
    it('navigates to the clicked child, and only to it', () => {
      cy.get(`${item(CHILD)} > .item`).click(2, 2)

      cy.location('pathname').should('equal', CHILD)
      visitedPaths().should('deep.equal', [CHILD])
    })

    it('navigates to a parent when the parent row itself is clicked', () => {
      cy.get(`${item(PARENT)} > .item`).click(2, 2)

      cy.location('pathname').should('equal', PARENT)
      visitedPaths().should('deep.equal', [PARENT])
    })

    it('follows the link when the link itself is clicked', () => {
      cy.get(`${item(CHILD)} a`).click()

      cy.location('pathname').should('equal', CHILD)
    })

    it('does not navigate when the caret is clicked', () => {
      cy.get(`${item(PARENT)} > .item > button.caret`).click()

      cy.location('pathname').should('equal', PREVIEW)
    })
  })

  context('disclosure', () => {
    it('expands and collapses the branch from the caret', () => {
      cy.get(`${item(PARENT)} > ul.children`).should('be.visible')

      cy.get(`${item(PARENT)} > .item > button.caret`).click()
      cy.get(`${item(PARENT)} > ul.children`).should('not.be.visible')

      cy.get(`${item(PARENT)} > .item > button.caret`).click()
      cy.get(`${item(PARENT)} > ul.children`).should('be.visible')
    })

    it('reports the branch state on the caret, and points it at the branch', () => {
      cy.get(`${item(PARENT)} > .item > button.caret`)
        .should('have.attr', 'aria-expanded', 'true')
        .invoke('attr', 'aria-controls')
        .then((controlled) => {
          cy.get(`#${controlled}`).should('have.class', 'children')
        })

      cy.get(`${item(PARENT)} > .item > button.caret`)
        .click()
        .should('have.attr', 'aria-expanded', 'false')
    })

    it('is operable from the keyboard, because the caret is a button', () => {
      cy.get(`${item(PARENT)} > .item > button.caret`)
        .should('have.attr', 'type', 'button')
        .focus()
        .type('{enter}')

      cy.get(`${item(PARENT)} > ul.children`).should('not.be.visible')
      cy.location('pathname').should('equal', PREVIEW)
    })

    it('renders no caret button for a childless item', () => {
      cy.get(`${item(CHILD)} > .item > button.caret`).should('not.exist')
      cy.get(`${item(CHILD)} > .item > span.caret`).should('have.attr', 'aria-hidden', 'true')
    })
  })
})
