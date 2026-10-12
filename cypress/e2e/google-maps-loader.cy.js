import { stubGoogleMaps } from '../support/google_maps'

// #1387 — The loader kept its first answer for the life of the page, a timeout included, so once
// the Maps script failed or came late no map came back until a reload. Driven through
// LocationsMap: taking the controller out and putting it back asks the loader again in the same
// page, as a Turbo visit to another page with a map does.
describe('Google Maps loader', () => {
  const SCRIPT = 'script[src^="https://maps.googleapis.com/maps/api/js"]'

  const visit = () =>
    cy.visit('/bali/empty_state/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
        cy.spy(win.console, 'warn').as('consoleWarn')
      }
    })

  const mount = (markup) => cy.get('body').then(([page]) => page.insertAdjacentHTML('beforeend', markup))

  // The map goes in after the page has loaded: a script inserted while the page loads holds its
  // load event back, and cy.visit with it, until the script has arrived.
  const visitAndMountMap = (attributes = {}) => {
    visit()

    cy.request('/bali/locations_map/default').then(({ body }) => {
      const component = new DOMParser().parseFromString(body, 'text/html')
        .querySelector('[data-controller="locations-map"]')
      Object.entries(attributes).forEach(([name, value]) => component.setAttribute(name, value))

      mount(component.outerHTML)
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

  // Taken out and put back while the script loads, the map has two connects waiting on it, and
  // each built a map in the same element with every marker on it.
  it('builds one map when it reconnects while the script loads', () => {
    stubGoogleMaps({ delay: 2000 })
    visitAndMountMap()
    cy.get(SCRIPT)
    cy.window().should((win) => expect(win.__fakeMaps, 'still loading').to.eq(undefined))

    reconnect()

    mapBuilt()
    cy.window().its('__fakeMaps.registry.markers').should('have.length', 6)
  })

  // A timeout is the caller giving up, not the script: it still runs once it arrives, and a new
  // one would load a second copy of the API over it.
  describe('loadGoogleMapsApi when the script outlives the timeout', () => {
    const settled = (promise) => promise.then(() => 'loaded', (error) => error.message)

    beforeEach(() => {
      cy.clock(Date.now(), ['setTimeout', 'clearTimeout'])
      stubGoogleMaps({ delay: 2000 })
      visit()

      let first
      cy.window().then((win) => { first = settled(win.loadGoogleMapsApi()) })
      cy.get(SCRIPT)
      cy.tick(10000)
      cy.then(() => first).should('eq', 'Timed out loading the Google Maps API')
    })

    it('waits for it on the next call', () => {
      cy.window().should((win) => expect(win.__fakeMaps, 'still loading').to.eq(undefined))

      cy.window().then((win) => settled(win.loadGoogleMapsApi())).should('eq', 'loaded')
      cy.get('@mapsApi.all').should('have.length', 1)
      cy.get(SCRIPT).should('have.length', 1)
    })

    it('hands it to the next call once it has arrived', () => {
      cy.window().its('__fakeMaps').should('exist')

      cy.window().then((win) => settled(win.loadGoogleMapsApi())).should('eq', 'loaded')
      cy.get('@mapsApi.all').should('have.length', 1)
      cy.get(SCRIPT).should('have.length', 1)
    })
  })

  // The maps ask with `timeout: 0`: before, one whose script came after the loader's 10 s stayed
  // an empty box until something reconnected it.
  describe('a map whose script arrives after the default timeout', () => {
    beforeEach(() => {
      cy.clock(Date.now(), ['setTimeout', 'clearTimeout'])
      stubGoogleMaps({ delay: 2000 })
      visitAndMountMap()
      cy.get(SCRIPT)
      cy.tick(10000)
    })

    it('builds the map once the script arrives', () => {
      mapBuilt()
      cy.window().its('__fakeMaps.registry.markers').should('have.length', 6)
    })

    it('builds nothing for a map that left the page before the script arrived', () => {
      cy.get('[data-controller="locations-map"]').then(([element]) => element.remove())

      // The stub defines `__fakeMaps` and calls the loader back in the same task, so a build
      // would already be in the registry here.
      cy.window().its('__fakeMaps').should('exist')
      cy.window().its('__fakeMaps.registry.maps').should('have.length', 0)
    })
  })

  // `coordinates_polygon_group` renders «Clear» and «Clear holes» beside the map, clickable while
  // the script is still loading.
  it('lets drawing-maps clear before its map exists', () => {
    const stored = JSON.stringify({ shells: [[{ lat: 32.51, lng: -117.01 }, { lat: 32.52, lng: -117 }, { lat: 32.5, lng: -117 }]], holes: [] })

    stubGoogleMaps({ delay: 2000 })
    visit()
    mount(`
      <div data-controller="drawing-maps" data-drawing-maps-key="">
        <div data-drawing-maps-target="map"></div>
        <input type="hidden" value='${stored}' data-drawing-maps-target="polygonField">
        <button type="button" data-action="drawing-maps#clearHoles">Clear holes</button>
        <button type="button" data-action="drawing-maps#clear">Clear</button>
      </div>`)
    cy.on('window:confirm', () => true)
    cy.window().should((win) => expect(win.__fakeMaps, 'still loading').to.eq(undefined))

    // Only holes go: the shell the form was rendered with stays in the field.
    cy.contains('button', 'Clear holes').click()
    cy.get('[data-drawing-maps-target="polygonField"]').should('have.value', stored)

    cy.contains('button', /^Clear$/).click()

    // Stimulus catches what an action throws and logs it.
    cy.get('@consoleError').should('not.have.been.called')
  })

  // #1409 — The API loads once per page, with the options of the call that asked first.
  describe('a call after the one that loaded the API', () => {
    // LocationsMap, rendered in `en`, asks for no library; autocomplete-address asks for `places`.
    const autocompleteAddress = `
      <div data-controller="autocomplete-address">
        <input type="text" data-autocomplete-address-target="input">
      </div>`

    const autocompletesBuilt = (count) =>
      cy.window().should((win) => expect(win.__fakeMaps.registry.autocompletes, 'autocompletes built').to.have.length(count))

    beforeEach(() => {
      stubGoogleMaps()
      visitAndMountMap()
      mapBuilt()
    })

    it('gets the libraries it asks for imported into the loaded API', () => {
      mount(autocompleteAddress)

      autocompletesBuilt(1)
      cy.get('@consoleError').should('not.have.been.called')
      cy.get('@mapsApi.all').should('have.length', 1)
    })

    it('warns once about an option the loaded API cannot change', () => {
      const loaderWarnings = (expected) =>
        cy.get('@consoleWarn').should((warn) => {
          const messages = warn.getCalls().map((call) => call.args[0]).filter((message) => /Google Maps/.test(message))

          expect(messages).to.deep.eq(expected)
        })

      cy.window().then((win) => win.loadGoogleMapsApi({ language: 'en' }))
      loaderWarnings([])

      cy.window().then((win) => win.loadGoogleMapsApi({ language: 'es' }))
      cy.window().then((win) => win.loadGoogleMapsApi({ language: 'es' }))
      loaderWarnings([
        'The Google Maps API loads once per page, with the first call\'s options: this call\'s `language` is ignored.'
      ])
    })
  })

  // #1409
  it('encodes the key in the script URL', () => {
    stubGoogleMaps()
    visitAndMountMap({ 'data-locations-map-api-key-value': 'a+b&c=d' })

    cy.wait('@mapsApi').its('request.url').should((url) => {
      expect(new URL(url).searchParams.get('key')).to.eq('a+b&c=d')
    })
  })

  // #1409 — 0 is no deadline, as for XHR.
  it('waits without a deadline on `timeout: 0`', () => {
    cy.clock(Date.now(), ['setTimeout', 'clearTimeout'])
    stubGoogleMaps({ delay: 2000 })
    visit()

    let result
    cy.window().then((win) => {
      result = win.loadGoogleMapsApi({ timeout: 0 }).then(() => 'loaded', (error) => error.message)
    })
    cy.tick(10000)

    cy.window().then(() => result).should('eq', 'loaded')
  })
})
