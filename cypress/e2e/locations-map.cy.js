// #1041 — LocationsMap had no E2E spec, and it is the component furthest from
// being testable head-on: the map is a keyed, paid, canvas-painting script that
// CI cannot load and a test cannot read back. What the controller does AROUND
// it is ordinary DOM work, though — read the location targets Ruby rendered,
// build one marker each, pull the info window's HTML out of a <template>, and
// highlight the card that goes with the marker just clicked.
//
// So the Google script is replaced with `cypress/fixtures/google-maps-stub.js`,
// which records what the controller builds and lets the spec fire a marker
// click. Nothing about Google's own behaviour is under test here; everything
// about Bali's use of it is.
describe('LocationsMap', () => {
  const stubGoogleMaps = () => {
    // `readFile`, not `fixture`: Cypress EVALUATES a .js fixture as a module and
    // this one is meant to run in the page, not in the test.
    cy.readFile('cypress/fixtures/google-maps-stub.js').then((script) => {
      cy.intercept('GET', 'https://maps.googleapis.com/maps/api/js*', {
        statusCode: 200,
        headers: { 'content-type': 'application/javascript' },
        body: script
      }).as('mapsApi')
    })
  }

  // The controller only wires cards to markers above `minWindowWidth` (768).
  const viewport = () => cy.viewport(1280, 900)

  const registry = (callback) => {
    cy.window().should((win) => {
      expect(win.__fakeMaps, 'stub loaded').to.not.eq(undefined)
      expect(win.__fakeMaps.registry.maps, 'map built').to.have.length(1)
      callback(win.__fakeMaps.registry, win)
    })
  }

  const cards = () => cy.get('[data-locations-map-target="card"]')

  describe('markers', () => {
    beforeEach(() => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/default')
    })

    it('builds one marker per location target, at the coordinates Ruby wrote', () => {
      registry(({ markers }) => {
        expect(markers).to.have.length(6)
        expect(markers[0].position).to.deep.eq({
          lat: 32.52535328002182,
          lng: -117.01662677673296
        })
        // Every marker is put on the map that was just built.
        markers.forEach((marker) => expect(marker.map).to.not.eq(undefined))
      })
    })

    it('centers the map where the component said, at the zoom it said', () => {
      registry(({ maps }) => {
        expect(maps[0].center).to.deep.eq({ lat: 32.5036383, lng: -117.0308968 })
        expect(maps[0].zoom).to.eq(12)
      })
    })

    it('passes the marker styling through to the pin', () => {
      registry(({ markers }) => {
        // Location 2 is `color: 'green'`; location 5 is an icon URL, which is an
        // <img> and not a pin at all.
        expect(markers[1].content.className).to.eq('fake-pin')
        expect(markers[4].content.tagName).to.eq('IMG')
        expect(markers[4].content.src).to.include('blu-blank.png')
      })
    })

    it('opens the info view from its template and recenters on the marker', () => {
      registry((_registry, win) => {
        // Only the last location was given an info view.
        win.__fakeMaps.clickMarker(5)
      })

      registry(({ infoWindows, maps }) => {
        expect(infoWindows).to.have.length(1)
        expect(infoWindows[0].content).to.contain('This is an info view')
        expect(infoWindows[0].isOpen).to.eq(true)
        expect(maps[0].center.lat).to.eq(32.516284591574724)
      })
    })

    it('does nothing at all when a location has no info view', () => {
      registry((_registry, win) => {
        win.__fakeMaps.clickMarker(0)
      })

      registry(({ infoWindows, maps }) => {
        // The single info window on this page belongs to the last location and
        // is built up front; a click on any other marker leaves it shut and the
        // map where it was — those markers get no click listener at all.
        expect(infoWindows.every((infoWindow) => !infoWindow.isOpen)).to.eq(true)
        expect(maps[0].center).to.deep.eq({ lat: 32.5036383, lng: -117.0308968 })
      })
    })
  })

  describe('cards', () => {
    beforeEach(() => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/with_cards')
    })

    it('highlights the card of the marker that was clicked', () => {
      cards().should('have.length', 6)
      cards().should('not.have.class', 'is-selected')

      registry((_registry, win) => {
        win.__fakeMaps.clickMarker(5)
      })

      cards().eq(5).should('have.class', 'is-selected')
      cards().eq(0).should('not.have.class', 'is-selected')
    })

    it('drops the highlight when the info window is dismissed', () => {
      registry((_registry, win) => {
        win.__fakeMaps.clickMarker(5)
      })
      cards().eq(5).should('have.class', 'is-selected')

      registry((_registry, win) => {
        win.__fakeMaps.dismissInfoWindow(0)
      })

      cards().should('not.have.class', 'is-selected')
    })
  })

  describe('fit to locations', () => {
    it('leaves the map alone when the fit is not asked for', () => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/default')

      registry(({ maps }) => {
        expect(maps[0].fittedBounds).to.eq(undefined)
      })
    })

    it('fits the viewport to every location', () => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/fitted')

      registry(({ maps }) => {
        expect(maps[0].fittedBounds.points).to.have.length(5)
        expect(maps[0].fittedBounds.points[0]).to.deep.eq({
          lat: 32.52535328002182,
          lng: -117.01662677673296
        })
        // The stub fits spread-out bounds at zoom 10 — under the ceiling (12),
        // so the clamp must leave it alone.
        expect(maps[0].zoom).to.eq(10)
      })
    })

    it('never zooms in past `zoom:` — the single-location case', () => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/fitted?single=true')

      registry(({ maps }) => {
        expect(maps[0].fittedBounds.points).to.have.length(1)
        // The stub zooms a degenerate bounds to street level (21), as the real
        // API would; the controller clamps back to the ceiling it was given.
        expect(maps[0].zoom).to.eq(12)
      })
    })
  })

  describe('clustering', () => {
    it('hands every marker to the clusterer when it is asked for', () => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/default?clustered=true')

      cy.get('[data-controller="locations-map"]').should(($element) => {
        const controller = $element[0].ownerDocument.defaultView.Stimulus
          .getControllerForElementAndIdentifier($element[0], 'locations-map')

        expect(controller.markerCluster, 'clusterer').to.not.eq(undefined)
        expect(controller.markerCluster.markers).to.have.length(6)
      })
    })

    it('builds no clusterer by default', () => {
      viewport()
      stubGoogleMaps()
      cy.visit('/bali/locations_map/default')

      registry(({ markers }) => {
        expect(markers).to.have.length(6)
      })
      cy.get('[data-controller="locations-map"]').should(($element) => {
        const controller = $element[0].ownerDocument.defaultView.Stimulus
          .getControllerForElementAndIdentifier($element[0], 'locations-map')

        expect(controller.markerCluster).to.eq(undefined)
      })
    })
  })
})
