import { stubGoogleMaps } from '../support/google_maps'

// #1423 — The pin was a `google.maps.Marker`, deprecated since February 2024; a failed lookup
// raised an English `window.alert` on a Spanish page; and the address fields kept their listeners
// after the controller left.
describe('geocoder-maps', () => {
  const ROUTE = '[data-geocoder-maps-target="route"]'
  const PIN = { lat: 32.5322, lng: -117.0372 }

  const mount = () => {
    cy.visit('/bali/empty_state/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
        cy.spy(win.console, 'warn').as('consoleWarn')
        cy.stub(win, 'alert').as('alert')
      }
    })
    cy.get('body').then(([body]) => body.insertAdjacentHTML('beforeend', `
      <div lang="es" data-controller="geocoder-maps" data-geocoder-maps-key="" data-geocoder-maps-draggable-marker-value="true">
        <div data-geocoder-maps-target="map" class="h-96"></div>
        <input type="text" data-geocoder-maps-target="route">
        <input type="text" data-geocoder-maps-target="streetNumber">
        <input type="text" data-geocoder-maps-target="sublocalityLevel1">
        <input type="text" data-geocoder-maps-target="locality">
        <input type="text" data-geocoder-maps-target="postalCode">
        <input type="hidden" value="32.52" data-geocoder-maps-target="latitude">
        <input type="hidden" value="-117.02" data-geocoder-maps-target="longitude">
      </div>`))
    cy.window().should((win) => expect(win.__fakeMaps?.registry.markers, 'pin dropped').to.have.length(1))
  }

  const reply = (geocoderReply) => cy.window().then((win) => { win.__fakeMaps.geocoderReply = geocoderReply })

  const typeRoute = () => cy.get(ROUTE).then(([route]) => {
    route.value = 'Avenida Revolución'
    route.dispatchEvent(new Event('change', { bubbles: true }))
  })

  const expectLatLng = (expected) =>
    cy.get('[data-geocoder-maps-target="latitude"], [data-geocoder-maps-target="longitude"]')
      .should(($fields) => expect($fields.toArray().map((field) => field.value)).to.deep.eq(expected))

  const geocodes = () => cy.window().its('__fakeMaps.registry.geocodes')

  beforeEach(() => {
    cy.viewport(1280, 900)
    stubGoogleMaps()
  })

  it('pins the address the person types, and fills its latitude and longitude', () => {
    mount()

    typeRoute()

    expectLatLng(['32.5322', '-117.0372'])
    cy.window().should((win) => {
      const pins = win.__fakeMaps.registry.markers.filter((marker) => marker.map)

      expect(pins.map((pin) => pin.position)).to.deep.eq([PIN])
    })
  })

  // google.maps.Marker warns that it is deprecated; an AdvancedMarkerElement on a map built
  // without a map ID draws nothing and logs an error (both measured on 3.66).
  it('pins with an AdvancedMarkerElement, on a map with a map ID', () => {
    mount()

    cy.get('@consoleWarn').should('not.have.been.calledWithMatch', /google\.maps\.Marker is deprecated/)
    cy.get('@consoleError').should('not.have.been.calledWithMatch', /Map ID/)
  })

  it('writes where the person drags the pin', () => {
    mount()

    cy.window().then((win) => win.__fakeMaps.dragMarker(0, { lat: 32.54, lng: -117.05 }))

    expectLatLng(['32.54', '-117.05'])
  })

  it('says in the language of the page that the address is not on the map', () => {
    mount()
    reply({ status: 'ZERO_RESULTS' })

    typeRoute()

    cy.get('@alert').should('have.been.calledOnceWith', 'No encontramos esa dirección en el mapa.')
  })

  // A denied key or a spent quota is the app's to fix, not the person's.
  it('does not alert the person about a failure of the setup', () => {
    mount()
    reply({ status: 'REQUEST_DENIED' })

    typeRoute()

    cy.get('@consoleError').should('have.been.calledWithMatch', /REQUEST_DENIED/)
    cy.get('@alert').should('not.have.been.called')
  })

  it('geocodes from an address field put in after the map was built', () => {
    mount()
    cy.get(ROUTE).then(([route]) => route.replaceWith(route.cloneNode()))

    typeRoute()

    geocodes().should('have.length', 1)
  })

  it('stops listening once it leaves the page', () => {
    const errors = []
    cy.on('uncaught:exception', (error) => {
      errors.push(error.message)
      return false
    })
    mount()
    cy.get('[data-controller="geocoder-maps"]').then(([element]) => element.removeAttribute('data-controller'))
    cy.window().should((win) => {
      const element = win.document.querySelector('[data-geocoder-maps-target="map"]').parentNode
      expect(win.Stimulus.getControllerForElementAndIdentifier(element, 'geocoder-maps'), 'disconnected').to.eq(null)
    })

    typeRoute()

    // The lookup is asked for inside the `change` handler, so it would already be here.
    geocodes().should('have.length', 0)
    cy.then(() => expect(errors, 'errors from its listeners').to.deep.eq([]))
  })
})
