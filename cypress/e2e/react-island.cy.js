// react-island infrastructure (#703): mounts the dummy's toy counter through the
// COMPLETE circuit of a real host — startIslandLoader in the main bundle reads the
// metas from react_island_meta_tags, injects the island-demo.js entry, registerIsland
// registers on window.Stimulus with a guard, and the ReactIslandController subclass
// mounts React with values→props.
//
// Visibility and the controller instance count are what is measured, not loose
// textContent (repo memory): a double registration leaves ONE island visible because
// the second mount overwrites the first — only the instance count gives it away.

const instances = (win) =>
  win.Stimulus.controllers.filter((c) => c.identifier === 'react-island-demo')

describe('ReactIsland', () => {
  it('mounts the island through the lazy loader and maps values to props', () => {
    cy.visit('/bali/react_island/default')

    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.get('[data-testid="count"]').should('have.text', '3')

    cy.get('[data-testid="increment"]').click()
    cy.get('[data-testid="count"]').should('have.text', '4')
  })

  it('mounts two independent islands, each with its own props', () => {
    cy.visit('/bali/react_island/two_islands')

    cy.get('[data-testid="counter-island"]').should('have.length', 2).and('be.visible')
    cy.get('[data-testid="count"]').eq(0).should('have.text', '10')
    cy.get('[data-testid="count"]').eq(1).should('have.text', '20')

    // Incrementing one does not touch the other: separate React roots.
    cy.get('[data-testid="increment"]').eq(0).click()
    cy.get('[data-testid="count"]').eq(0).should('have.text', '11')
    cy.get('[data-testid="count"]').eq(1).should('have.text', '20')
  })

  it('keeps ONE controller instance per island after navigating with Turbo', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.window().should((win) => expect(instances(win)).to.have.length(1))

    cy.get('[data-testid="goto-two-islands"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 2).and('be.visible')
    // The previous page's controllers disconnected; if the entry registered itself
    // twice there would be 4 instances here.
    cy.window().should((win) => expect(instances(win)).to.have.length(2))

    cy.get('[data-testid="goto-default"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 1).and('be.visible')
    cy.window().should((win) => expect(instances(win)).to.have.length(1))
  })

  it('unmounts on navigation and remounts fresh on return (no Turbo cache)', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="increment"]').click()
    cy.get('[data-testid="count"]').should('have.text', '4')

    cy.get('[data-testid="goto-two-islands"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 2)

    cy.get('[data-testid="goto-default"]').click()
    // Fresh mount from the server values: if React survived the Turbo cache (or the
    // root were not unmounted) there would be a 4 or a broken editor here, not the
    // initial value.
    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.get('[data-testid="count"]').should('have.text', '3')
  })

  it('renders the fallback and reports through onError when loadComponent fails', () => {
    cy.visit('/bali/react_island/load_error')

    cy.get('.text-error').should('be.visible')
    cy.get('[data-testid="counter-island"]').should('not.exist')

    cy.window().should((win) => {
      const errors = win.__baliIslandErrors || []
      expect(errors.some((e) => e.phase === 'load' && e.identifier === 'react-island-demo')).to.equal(true)
    })
  })

  // The case this used to miss: with the metas present and import() failing (digest
  // rotated after a deploy, network down, CSP), `replaceChildren` wiped the mount's
  // server-rendered content. For Bali::Gantt `mode: :interactive` that means losing
  // the navigable board and being left with a <p>.
  it('a load failure does NOT destroy the server-rendered content of the mount', () => {
    cy.visit('/bali/react_island/load_error')

    cy.get('#isla-con-fallback [data-testid="fallback-server"]')
      .should('be.visible')
      .and('contain.text', 'esto es el fallback de la isla')
    // Still usable, not a screenshot: the link is reachable.
    cy.get('#isla-con-fallback [data-testid="fallback-server"] a')
      .should('have.attr', 'href')
      .and('include', '/lookbook')

    // And the notice goes ON TOP, so it is read before the content.
    cy.get('#isla-con-fallback').children().first().should('have.class', 'text-error')

    // The empty mount behaves as before: the notice is all there is.
    cy.get('[data-controller="react-island-demo"]').first().children()
      .should('have.length', 1)
      .and('have.class', 'text-error')
  })

  it('the ErrorBoundary catches render errors and reports through onError', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="counter-island"]').should('be.visible')

    cy.get('[data-testid="explode"]').click()

    cy.get('[data-testid="counter-island"]').should('not.exist')
    cy.get('.text-error').should('be.visible')

    cy.window().should((win) => {
      const errors = win.__baliIslandErrors || []
      expect(errors.some((e) => e.phase === 'render' && e.identifier === 'react-island-demo')).to.equal(true)
    })
  })
})
