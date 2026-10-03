import { cdp, frameAt } from '../support/accessibility_tree'

// #1282 — the quick search sits inside a <label class="input">, and Chromium names a box from the
// label wrapped around it before it reaches the placeholder: the empty string with the box empty,
// and the clear button's "Clear search" once there is text to clear. So the name is read from
// Chromium's accessibility tree, which is what a screen reader is handed. The attribute is
// asserted in test/bali/components/filters/component_test.rb. The dummy's listing passes a
// placeholder and no `aria_label:`, as the hosts do.
describe('Filters quick search accessible name', () => {
  const search = '[data-filters-target="searchInput"]'

  const searchName = () =>
    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) => cdp('DOM.getFrameOwner', { frameId: frameAt(frameTree, url).id }))
        .then(({ backendNodeId }) => cdp('DOM.describeNode', { backendNodeId, depth: 1, pierce: true }))
        .then(({ node }) => cdp('DOM.resolveNode', { backendNodeId: node.contentDocument.backendNodeId }))
        .then(({ object }) =>
          cdp('Runtime.callFunctionOn', {
            objectId: object.objectId,
            functionDeclaration: `function () { return this.querySelector('${search}') }`
          })
        )
        .then(({ result }) => cdp('Accessibility.getPartialAXTree', { objectId: result.objectId, fetchRelatives: false }))
        .then(({ nodes }) => `${nodes[0].role.value} «${nodes[0].name?.value ?? ''}»`)
    )

  const movies = (query = '') => `${new URL(Cypress.config('baseUrl')).origin}/admin/movies${query}`

  it('names the box with its placeholder', () => {
    cy.visit(movies())
    cy.get(search).should('have.value', '')

    searchName().should('equal', 'textbox «Search by name, genre, or studio...»')
  })

  it('keeps that name once there is text, and the clear button with it', () => {
    cy.visit(movies())
    cy.get(search).type('drama')
    cy.get('[data-filters-target="searchClearButton"]').should('be.visible')

    searchName().should('equal', 'textbox «Search by name, genre, or studio...»')
  })

  it('names the box a search arrived with, in the page language', () => {
    cy.visit(movies('?locale=es&q[name_or_genre_or_studio_name_cont]=drama'))
    cy.get(search).should('have.value', 'drama')

    searchName().should('equal', 'textbox «Buscar por nombre, genero o estudio...»')
  })
})
