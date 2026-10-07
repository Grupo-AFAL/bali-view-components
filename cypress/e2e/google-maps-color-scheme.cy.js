import { stubGoogleMaps } from '../support/google_maps'

// #1344 — Google paints a map light unless it is built with `colorScheme`, and reads that
// option only while it builds the map. Each controller that builds a google.maps.Map passes
// the page's scheme, and builds the map again when <html data-theme> switches to a theme of
// the other scheme, carrying over what the person had on it.
describe('Google maps follow the color scheme of the page', () => {
  const registry = (callback) => {
    cy.window().should((win) => {
      expect(win.__fakeMaps, 'stub loaded').to.not.eq(undefined)
      callback(win.__fakeMaps.registry, win)
    })
  }

  // The page arrives in the theme, as a host's does from `bali_theme`: LocationsMap builds
  // its map while the page loads, before a test could switch anything.
  const visitIn = (theme, path) => {
    cy.intercept({ method: 'GET', pathname: `/lookbook/preview${path.split('?')[0]}` }, (req) => {
      req.continue((res) => {
        res.body = res.body.replace(/<html data-theme="[^"]*"/, `<html data-theme="${theme}"`)
      })
    })
    cy.visit(path)
  }

  // Resolves once the theme observers have run: they are microtasks, and a timeout comes
  // after all of them.
  const switchTheme = (theme) =>
    cy.document().then((doc) => {
      doc.documentElement.setAttribute('data-theme', theme)
      return new Cypress.Promise((resolve) => setTimeout(resolve, 0))
    })

  const MOVED = { center: { lat: 32.53, lng: -117.04 }, zoom: 16 }

  const moveFirstMap = () =>
    registry(({ maps }) => {
      maps[0].setCenter(MOVED.center)
      maps[0].setZoom(MOVED.zoom)
    })

  const expectRebuiltWhereLeft = (maps) => {
    expect(maps, 'maps built').to.have.length(2)
    expect(maps[1].options.colorScheme).to.eq('DARK')
    expect(maps[1].center).to.deep.eq(MOVED.center)
    expect(maps[1].zoom).to.eq(MOVED.zoom)
  }

  beforeEach(() => {
    cy.viewport(1280, 900)
    stubGoogleMaps()
  })

  describe('LocationsMap', () => {
    const controller = (callback) =>
      cy.get('[data-controller="locations-map"]').should(($element) => {
        callback($element[0].ownerDocument.defaultView.Stimulus
          .getControllerForElementAndIdentifier($element[0], 'locations-map'))
      })

    it('builds the map dark on a dark page', () => {
      visitIn('afal-dark', '/bali/locations_map/default')

      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('DARK')
      })
    })

    it('builds the map light on a light page', () => {
      visitIn('afal', '/bali/locations_map/default')

      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('LIGHT')
      })
    })

    it('builds it again dark when the page turns dark, with the markers and the open info window', () => {
      visitIn('afal', '/bali/locations_map/default')
      registry((_registry, win) => win.__fakeMaps.clickMarker(5))
      moveFirstMap()

      switchTheme('afal-dark')

      registry(({ maps, markers, infoWindows }) => {
        expectRebuiltWhereLeft(maps)
        expect(markers.filter((marker) => marker.map === maps[1]), 'markers on the new map').to.have.length(6)
        expect(infoWindows[0].isOpen).to.eq(true)
        expect(infoWindows[0].map, 'info window on the new map').to.eq(maps[1])
      })
    })

    it('leaves shut an info window the person closed', () => {
      visitIn('afal', '/bali/locations_map/default')
      registry((_registry, win) => win.__fakeMaps.clickMarker(5))
      registry((_registry, win) => win.__fakeMaps.dismissInfoWindow(0))

      switchTheme('afal-dark')

      registry(({ maps, infoWindows }) => {
        expect(maps).to.have.length(2)
        expect(infoWindows[0].isOpen).to.eq(false)
        expect(infoWindows[0].map, 'not opened on the new map').to.eq(maps[0])
      })
    })

    it('builds nothing when the switch keeps the scheme', () => {
      visitIn('afal', '/bali/locations_map/default')
      registry(({ maps }) => expect(maps).to.have.length(1))

      switchTheme('light')
      registry(({ maps }) => expect(maps, 'afal to light').to.have.length(1))

      switchTheme('afal-dark')
      registry(({ maps }) => expect(maps, 'light to afal-dark').to.have.length(2))
    })

    it('stops following the page once it is disconnected', () => {
      visitIn('afal', '/bali/locations_map/default')
      registry(({ maps }) => expect(maps).to.have.length(1))
      cy.get('[data-controller="locations-map"]').then(($element) => $element.remove())

      switchTheme('afal-dark')

      registry(({ maps }) => expect(maps).to.have.length(1))
    })

    // Moved onto the new map with setMap, a clusterer keeps the clusters it worked out on
    // the old one and paints none of them there: measured against the real API, which the
    // stub cannot show, so what this pins is that the clusterer on the new map is a new one.
    it('hands the markers to a new clusterer on the new map', () => {
      visitIn('afal', '/bali/locations_map/default?clustered=true')
      let firstClusterer
      controller((locationsMap) => {
        firstClusterer = locationsMap.markerCluster
        expect(firstClusterer, 'clusterer').to.not.eq(undefined)
      })

      switchTheme('afal-dark')

      controller((locationsMap) => {
        const { maps } = locationsMap.element.ownerDocument.defaultView.__fakeMaps.registry

        expect(maps).to.have.length(2)
        expect(locationsMap.markerCluster).to.not.eq(firstClusterer)
        expect(locationsMap.markerCluster.getMap()).to.eq(maps[1])
        expect(locationsMap.markerCluster.markers).to.have.length(6)
        expect(firstClusterer.getMap(), 'the first one off the old map').to.eq(null)
      })
    })
  })

  // Neither controller has a component, so the spec mounts the markup the controllers
  // guide shows on a page with no map of its own, in the theme the test is about.
  const mount = (theme, markup) => {
    cy.visit('/bali/empty_state/default')
    switchTheme(theme)
    cy.get('body').then(($body) => $body[0].insertAdjacentHTML('beforeend', markup))
  }

  describe('drawing-maps', () => {
    const POLYGON = {
      shells: [[{ lat: 32.51, lng: -117.01 }, { lat: 32.52, lng: -117.0 }, { lat: 32.5, lng: -117.0 }]],
      holes: []
    }

    const drawingMaps = `
      <div data-controller="drawing-maps" data-drawing-maps-key="">
        <div data-drawing-maps-target="map" class="h-96"></div>
        <input type="hidden" value='${JSON.stringify(POLYGON)}' data-drawing-maps-target="polygonField">
      </div>`

    it('builds the map in the scheme of the page', () => {
      mount('afal-dark', drawingMaps)
      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('DARK')
      })

      mount('afal', drawingMaps)
      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('LIGHT')
      })
    })

    it('builds it again dark when the page turns dark, with the polygon and the drawing tools', () => {
      mount('afal', drawingMaps)
      registry(({ polygons }) => expect(polygons).to.have.length(1))
      moveFirstMap()

      switchTheme('afal-dark')

      registry(({ maps, polygons, drawingManagers }) => {
        expectRebuiltWhereLeft(maps)
        expect(polygons[0].map, 'polygon on the new map').to.eq(maps[1])
        expect(drawingManagers[0].map, 'drawing tools on the new map').to.eq(maps[1])
      })
    })
  })

  describe('geocoder-maps', () => {
    const geocoderMaps = `
      <div data-controller="geocoder-maps" data-geocoder-maps-key="">
        <div data-geocoder-maps-target="map" class="h-96"></div>
        <input type="text" data-geocoder-maps-target="route">
        <input type="text" data-geocoder-maps-target="streetNumber">
        <input type="text" data-geocoder-maps-target="sublocalityLevel1">
        <input type="text" data-geocoder-maps-target="locality">
        <input type="text" data-geocoder-maps-target="postalCode">
        <input type="hidden" value="32.52" data-geocoder-maps-target="latitude">
        <input type="hidden" value="-117.02" data-geocoder-maps-target="longitude">
      </div>`

    it('builds the map in the scheme of the page', () => {
      mount('afal-dark', geocoderMaps)
      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('DARK')
      })

      mount('afal', geocoderMaps)
      registry(({ maps }) => {
        expect(maps).to.have.length(1)
        expect(maps[0].options.colorScheme).to.eq('LIGHT')
      })
    })

    it('builds it again dark when the page turns dark, with the pin', () => {
      mount('afal', geocoderMaps)
      registry(({ markers }) => expect(markers).to.have.length(1))
      moveFirstMap()

      switchTheme('afal-dark')

      registry(({ maps, markers }) => {
        expectRebuiltWhereLeft(maps)
        expect(markers[0].map, 'pin on the new map').to.eq(maps[1])
      })
    })
  })
})
