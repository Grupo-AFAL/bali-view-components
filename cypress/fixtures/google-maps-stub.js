// Stands in for the Google Maps JavaScript API in locations-map.cy.js and
// google-maps-color-scheme.cy.js.
//
// The real API is a paid, keyed, network-loaded script that paints into a
// canvas: a test can neither load it (there is no key in CI) nor read anything
// back out of it. What the LocationsMap controller does around it, though, is
// ordinary DOM work — one marker per location target, an info window built from
// a <template>, and the card highlighting — and all of that is worth freezing.
//
// So this file replaces the script the loader injects. It records what the
// controller builds and exposes `window.__fakeMaps` for the spec to drive:
// nothing here asserts anything, it only makes the controller's side effects
// observable.
(function () {
  const registry = { maps: [], markers: [], infoWindows: [], clusterers: [], polygons: [] }

  class ListenerHost {
    constructor () {
      this.listeners = {}
    }

    // The real API returns a handle with `remove()`; the controller ignores it.
    addListener (event, handler) {
      if (!this.listeners[event]) this.listeners[event] = []
      this.listeners[event].push(handler)
      return { remove () {} }
    }

    emit (event, payload) {
      (this.listeners[event] || []).forEach((handler) => handler(payload))
    }
  }

  class FakeMap extends ListenerHost {
    constructor (element, options) {
      super()
      this.element = element
      this.options = options
      this.center = options.center
      this.zoom = options.zoom
      registry.maps.push(this)
    }

    getCenter () {
      return this.center
    }

    setCenter (center) {
      this.center = center
    }

    getZoom () {
      return this.zoom
    }

    setZoom (zoom) {
      this.zoom = zoom
    }

    // The real fitBounds picks whatever zoom contains the bounds. The stub
    // mimics only the two ends the controller has to handle: a degenerate
    // bounds (one point) zooms to street level, anything with spread zooms
    // out — so a spec can tell a clamped zoom from a fitted one.
    fitBounds (bounds) {
      this.fittedBounds = bounds
      const spread = bounds.points.some(
        (point) => point.lat !== bounds.points[0].lat || point.lng !== bounds.points[0].lng
      )
      this.zoom = spread ? 10 : 21
      this.emit('bounds_changed')
    }

    // MarkerClusterer asks for this before it draws anything; null keeps it
    // from trying to.
    getProjection () {
      return null
    }
  }

  // MarkerClusterer copies this prototype onto its own with a `for...in`, which
  // only sees ENUMERABLE properties — so a `class` here would hand it nothing
  // and `setMap` would be undefined the moment a clustered map is built.
  function OverlayView () {}
  OverlayView.prototype.setMap = function (map) {
    this.map = map
  }
  OverlayView.prototype.getMap = function () {
    return this.map
  }
  OverlayView.prototype.getProjection = function () {
    return null
  }

  // The window is drawn the way Maps JavaScript API 3.66 draws it, as far as its
  // colours go: a white bubble whatever the map's colorScheme, and a close icon
  // that its own sheet paints `light-dark(#000, #fff)`.
  const bubbleStyle = window.document.createElement('style')
  bubbleStyle.textContent = `
    .gm-style-iw-c { background-color: #fff; padding: 12px }
    .gm-ui-hover-effect > span { display: block; width: 24px; height: 24px; background-color: light-dark(#000, #fff) }
  `
  window.document.head.append(bubbleStyle)

  class FakeInfoWindow extends ListenerHost {
    constructor (options) {
      super()
      this.content = options.content
      this.isOpen = false
      registry.infoWindows.push(this)
    }

    open (map, marker) {
      this.isOpen = true
      this.map = map
      this.marker = marker

      this.bubble?.remove()
      this.bubble = window.document.createElement('div')
      this.bubble.className = 'gm-style-iw-c'
      this.bubble.innerHTML = `<button class="gm-ui-hover-effect"><span></span></button><div class="gm-style-iw-d">${this.content}</div>`
      map.element.append(this.bubble)
    }

    // Deliberately silent: in the real API `closeclick` fires when the user
    // dismisses the window, never when code closes it. Conflating the two here
    // would hide the difference the controller depends on.
    close () {
      this.isOpen = false
      this.bubble?.remove()
    }
  }

  class FakeAdvancedMarkerElement extends ListenerHost {
    constructor (options) {
      super()
      Object.assign(this, options)
      registry.markers.push(this)
    }
  }

  // `setMap` is how the geocoder's pin and a drawn polygon are put on a map, and
  // moved to another.
  class FakeOverlay extends ListenerHost {
    constructor (options = {}) {
      super()
      this.options = options
      this.map = options.map
    }

    setMap (map) {
      this.map = map
    }
  }

  class FakeMarker extends FakeOverlay {
    constructor (options) {
      super(options)
      registry.markers.push(this)
    }
  }

  class FakePolygon extends FakeOverlay {
    constructor (options) {
      super(options)
      registry.polygons.push(this)
    }

    getPaths () {
      return [this.options.paths]
    }
  }

  class FakeLatLngBounds {
    constructor () {
      this.points = []
    }

    extend (point) {
      this.points.push(point)
      return this
    }
  }

  class FakePinElement {
    constructor (options) {
      this.options = options
      this.element = window.document.createElement('div')
      this.element.className = 'fake-pin'
    }
  }

  window.google = {
    maps: {
      Map: FakeMap,
      ColorScheme: { DARK: 'DARK', LIGHT: 'LIGHT', FOLLOW_SYSTEM: 'FOLLOW_SYSTEM' },
      InfoWindow: FakeInfoWindow,
      LatLngBounds: FakeLatLngBounds,
      OverlayView,
      Marker: FakeMarker,
      Animation: { DROP: 'DROP' },
      Polygon: FakePolygon,
      // No `drawing` library: the API dropped DrawingManager in 3.65, and
      // drawing-maps fails to build it inside its `try`, as it does against Google.
      // Nothing here fires: the polygon's edits are not under test.
      event: {
        trigger () {},
        addListener () {
          return { remove () {} }
        }
      },
      importLibrary: () =>
        Promise.resolve({
          AdvancedMarkerElement: FakeAdvancedMarkerElement,
          PinElement: FakePinElement
        })
    }
  }

  window.__fakeMaps = {
    registry,

    // A marker click carries the coordinates back through `latLng`, which is
    // how the controller finds the card that goes with it.
    clickMarker (index) {
      const marker = registry.markers[index]

      marker.emit('click', {
        stop () {},
        latLng: {
          lat: () => marker.position.lat,
          lng: () => marker.position.lng
        }
      })
    },

    // The close button shuts the window and then fires `closeclick`.
    dismissInfoWindow (index) {
      registry.infoWindows[index].isOpen = false
      registry.infoWindows[index].bubble.remove()
      registry.infoWindows[index].emit('closeclick')
    }
  }

  window.__googleMapsApiOnLoadCallback()
})()
