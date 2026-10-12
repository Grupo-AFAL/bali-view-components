import { stubGoogleMaps } from '../support/google_maps'

// #1387 — The loader kept its first answer for the life of the page, a timeout included, so once
// the Maps script failed or came late no map came back until a reload. Driven through
// LocationsMap: taking the controller out and putting it back asks the loader again in the same
// page, as a Turbo visit to another page with a map does.
describe('Google Maps loader', () => {
  const SCRIPT = 'script[src^="https://maps.googleapis.com/maps/api/js"]'

  // The map goes in after the page has loaded: a script inserted while the page loads holds its
  // load event back, and cy.visit with it, until the script has arrived.
  const visitAndMountMap = () => {
    cy.visit('/bali/empty_state/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
      }
    })

    cy.request('/bali/locations_map/default').then(({ body }) => {
      const component = new DOMParser().parseFromString(body, 'text/html')
        .querySelector('[data-controller="locations-map"]')

      cy.get('body').then(([page]) => page.insertAdjacentHTML('beforeend', component.outerHTML))
    })
  }

  // The controller logs what the loader rejected with.
  const gaveUp = (message) =>
    cy.get('@consoleError').should('have.been.calledWithMatch', Cypress.sinon.match.has('message', message))

  const reconnect = () =>
    cy.get('[data-controller="locations-map"]').then(([element]) => {
      const parent = element.parentNode
      element.remove()
      cy.wrap(parent).then(() => parent.appendChild(element))
    })

  const mapBuilt = () =>
    cy.window().should((win) => {
      expect(win.__fakeMaps, 'stub loaded').to.not.eq(undefined)
      expect(win.__fakeMaps.registry.maps, 'map built').to.have.length(1)
    })

  it('loads the script again once it failed to load', () => {
    stubGoogleMaps('error')
    visitAndMountMap()
    gaveUp('Could not load the Google Maps API')

    reconnect()

    mapBuilt()
    cy.get('@mapsApi.all').should('have.length', 2)
    cy.get(SCRIPT).should('have.length', 1)
  })

  // A timeout is the caller giving up, not the script: it still runs once it arrives, and a new
  // one would load a second copy of the API over it.
  describe('when the script outlives the timeout', () => {
    beforeEach(() => {
      cy.clock(Date.now(), ['setTimeout', 'clearTimeout'])
      stubGoogleMaps({ delay: 2000 })
      visitAndMountMap()
      cy.get(SCRIPT)
      cy.tick(10000)
      gaveUp('Timed out loading the Google Maps API')
    })

    it('waits for it on the next call', () => {
      cy.window().should((win) => expect(win.__fakeMaps, 'still loading').to.eq(undefined))

      reconnect()

      mapBuilt()
      cy.get('@mapsApi.all').should('have.length', 1)
      cy.get(SCRIPT).should('have.length', 1)
    })

    it('hands it to the next call once it has arrived', () => {
      cy.window().its('__fakeMaps').should('exist')

      reconnect()

      mapBuilt()
      cy.get('@mapsApi.all').should('have.length', 1)
      cy.get(SCRIPT).should('have.length', 1)
    })
  })
})
