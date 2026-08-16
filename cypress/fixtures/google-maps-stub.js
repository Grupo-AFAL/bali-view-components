// Stands in for the Google Maps JavaScript API in locations-map.cy.js.
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
  const registry = { maps: [], markers: [], infoWindows: [], clusterers: [] }

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

    setCenter (center) {
      this.center = center
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
    }

    // Deliberately silent: in the real API `closeclick` fires when the user
    // dismisses the window, never when code closes it. Conflating the two here
    // would hide the difference the controller depends on.
    close () {
      this.isOpen = false
    }
  }

  class FakeAdvancedMarkerElement extends ListenerHost {
    constructor (options) {
      super()
      Object.assign(this, options)
      registry.markers.push(this)
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
      InfoWindow: FakeInfoWindow,
      OverlayView,
      event: { trigger () {} },
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

    dismissInfoWindow (index) {
      registry.infoWindows[index].emit('closeclick')
    }
  }

  window.__googleMapsApiOnLoadCallback()
})()
