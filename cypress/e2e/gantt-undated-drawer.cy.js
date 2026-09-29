// Gantt (#1015): items with no dates do not disappear. They cannot have a bar or a
// row, so they live in a server-rendered drawer (Data#undated_items) that the
// island's footer gives away and opens: "10 items · 2 with no dates". The `default`
// preview carries two undated ones (Docs, Announcement).
//
// It is measured with `:modal` (the DrawerController opens with showModal()), not
// with classes or loose textContent (repo memory). And it is closed at the end: a
// <dialog> in the top layer that nobody closes leaves the whole page inert (#854).

describe('Gantt undated drawer', () => {
  beforeEach(() => {
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow', { timeout: 10000 }).should('exist')
  })

  it('the server-rendered drawer survives the swap and lives next to the mount', () => {
    // Next to the mount, not inside it: React removes the mount's children on its
    // first commit and a drawer inside would vanish along with the skeleton.
    cy.get('.bali-gantt > dialog.drawer-component').should('exist')
    cy.get('.bali-gantt-mount dialog').should('not.exist')
    cy.get('dialog.drawer-component:modal').should('not.exist')

    // Named for the island, and NOT shared: a broadcast trigger on the page must
    // not open it.
    cy.get('.bali-gantt').then(($gantt) => {
      const drawerId = $gantt.attr('data-gantt-undated-drawer-id-value')
      expect(drawerId, 'undated drawer id value').to.match(/.+/)
      cy.get(`dialog#${drawerId}`).should('have.attr', 'data-drawer-shared-value', 'false')
    })
  })

  it('the footer gives away the undated items and the link opens the drawer with the list', () => {
    cy.contains('button', 'with no dates').should('be.visible').click()

    cy.get('dialog.drawer-component:modal').should('exist')
    cy.get('dialog.drawer-component').within(() => {
      cy.contains('li', 'Docs').should('be.visible')
      cy.contains('li', 'Announcement').should('be.visible')
      // The exact shape of the report: no dates AND no group — it has no row or bar
      // anywhere; the drawer is the only place where it exists.
      cy.contains('li', 'Postmortem review').should('be.visible')
      // Only the undated ones: no row from the board sneaks in.
      cy.contains('li', 'Component API').should('not.exist')
    })

    // A lookup, not a decision: it closes and the page stays alive.
    cy.get('dialog.drawer-component button[aria-label="Close drawer"]').click()
    cy.get('dialog.drawer-component:modal').should('not.exist')
    cy.contains('button', 'with no dates').click()
    cy.get('dialog.drawer-component:modal').should('exist')
    cy.get('dialog.drawer-component button[aria-label="Close drawer"]').click()
    cy.get('dialog.drawer-component:modal').should('not.exist')
  })
})
