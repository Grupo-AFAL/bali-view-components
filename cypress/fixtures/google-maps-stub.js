// Stands in for the Google Maps JavaScript API in locations-map.cy.js,
// google-maps-color-scheme.cy.js, google-maps-loader.cy.js and the specs of the
// drawing-maps, autocomplete-address and geocoder-maps controllers.
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
  const registry = { maps: [], markers: [], infoWindows: [], clusterers: [], polygons: [], polylines: [], autocompletes: [], geocodes: [] }

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

  // The real API hands back LatLng objects wherever it was given literals: a polygon's path,
  // a click, a geocoded location.
  class FakeLatLng {
    constructor (lat, lng) {
      this.latitude = lat
      this.longitude = lng
    }

    lat () {
      return this.latitude
    }

    lng () {
      return this.longitude
    }

    toJSON () {
      return { lat: this.latitude, lng: this.longitude }
    }
  }

  const toLatLng = (point) => point instanceof FakeLatLng ? point : new FakeLatLng(point.lat, point.lng)

  // A path: `insert_at` and `set_at` fire as the real MVCArray fires them, which is how a
  // controller hears a vertex added or dragged.
  class FakeMVCArray extends ListenerHost {
    constructor (items = []) {
      super()
      this.items = items
    }

    getArray () {
      return this.items
    }

    getAt (index) {
      return this.items[index]
    }

    getLength () {
      return this.items.length
    }

    forEach (callback) {
      this.items.forEach(callback)
    }

    push (item) {
      this.items.push(item)
      this.emit('insert_at', this.items.length - 1)
      return this.items.length
    }

    setAt (index, item) {
      this.items[index] = item
      this.emit('set_at', index)
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

  // On a map built without a `mapId` the real one draws nothing and logs this error.
  class FakeAdvancedMarkerElement extends ListenerHost {
    constructor (options) {
      super()
      Object.assign(this, options)
      if (this.map && !this.map.options.mapId) {
        console.error('The map is initialized without a valid Map ID, which will prevent use of Advanced Markers.')
      }
      registry.markers.push(this)
    }

    // Its `gmp-*` events are DOM events, heard with addEventListener.
    addEventListener (event, handler) {
      this.addListener(event, handler)
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

    getMap () {
      return this.map
    }

    setOptions (options) {
      Object.assign(this.options, options)
    }
  }

  // The real one still builds, and says on construction that it is deprecated.
  class FakeMarker extends FakeOverlay {
    constructor (options) {
      super(options)
      console.warn('As of February 21st, 2024, google.maps.Marker is deprecated. Please use google.maps.marker.AdvancedMarkerElement instead.')
      registry.markers.push(this)
    }
  }

  class FakePolyline extends FakeOverlay {
    constructor (options) {
      super(options)
      this.path = new FakeMVCArray(options.path.map(toLatLng))
      registry.polylines.push(this)
    }

    getPath () {
      return this.path
    }
  }

  // One ring, which is all the controllers hand it.
  class FakePolygon extends FakeOverlay {
    constructor (options) {
      super(options)
      this.paths = new FakeMVCArray([new FakeMVCArray(options.paths.map(toLatLng))])
      registry.polygons.push(this)
    }

    getPath () {
      return this.paths.getAt(0)
    }

    getPaths () {
      return this.paths
    }
  }

  // Ray casting over the polygon's ring, as `google.maps.geometry.poly.containsLocation`.
  const containsLocation = (point, polygon) => {
    const vertices = polygon.getPath().getArray()
    const { lat, lng } = toLatLng(point).toJSON()
    let inside = false

    for (let i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      const [a, b] = [vertices[i], vertices[j]]
      if ((a.lat() > lat) !== (b.lat() > lat) &&
          lng < ((b.lng() - a.lng()) * (lat - a.lat())) / (b.lat() - a.lat()) + a.lng()) {
        inside = !inside
      }
    }

    return inside
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

  class FakeAutocomplete extends ListenerHost {
    constructor (input, options) {
      super()
      console.warn('As of March 1st, 2025, google.maps.places.Autocomplete is not available to new customers. Please use google.maps.places.PlaceAutocompleteElement instead.')
      this.input = input
      this.options = options
      registry.autocompletes.push(this)
    }
  }

  // <gmp-place-autocomplete> draws its own input in a closed shadow root, in the scheme of the
  // operating system unless the page says otherwise, and is a form-associated element: it
  // submits what it holds under its `name`. All three measured on 3.66.
  class FakePlaceAutocompleteElement extends window.HTMLElement {
    static formAssociated = true

    constructor (options = {}) {
      super()
      this.attachShadow({ mode: 'closed' }).innerHTML = '<style>:host { display: block; color-scheme: light dark }</style>'
      this.internals = this.attachInternals()
      this.currentValue = ''
      Object.assign(this, options)
      registry.autocompletes.push(this)
    }

    get value () {
      return this.currentValue
    }

    set value (value) {
      this.currentValue = value ?? ''
      this.internals.setFormValue(this.currentValue)
    }

    get name () {
      return this.getAttribute('name')
    }

    set name (name) {
      this.setAttribute('name', name)
    }
  }
  window.customElements.define('gmp-place-autocomplete', FakePlaceAutocompleteElement)

  // Only the fields asked for arrive, as with the real `fetchFields`.
  class FakePlace {
    constructor (place) {
      this.place = place
    }

    fetchFields ({ fields }) {
      const all = {
        formattedAddress: this.place.formattedAddress,
        location: toLatLng(this.place.location),
        addressComponents: this.place.addressComponents
      }
      fields.forEach((field) => { this[field] = all[field] })

      return Promise.resolve({ place: this })
    }
  }

  // Answers with `__fakeMaps.geocoderReply`; the callback is called later, as the real one is.
  class FakeGeocoder {
    geocode (request, callback) {
      registry.geocodes.push(request)
      const { status, location } = window.__fakeMaps.geocoderReply
      const results = status === 'OK' ? [{ geometry: { location: toLatLng(location) } }] : []

      setTimeout(() => callback(results, status), 0)
    }
  }

  // What the script's `libraries=` and a later importLibrary put on google.maps; a name the API
  // does not know is rejected, as the real one rejects it.
  const libraries = {
    marker: { AdvancedMarkerElement: FakeAdvancedMarkerElement, PinElement: FakePinElement },
    places: { Autocomplete: FakeAutocomplete, PlaceAutocompleteElement: FakePlaceAutocompleteElement },
    geometry: { poly: { containsLocation } },
    geocoding: { Geocoder: FakeGeocoder }
  }

  const importLibrary = (name) => {
    if (!libraries[name]) return Promise.reject(new Error(`The library ${name} is unknown.`))

    window.google.maps[name] = libraries[name]
    return Promise.resolve(libraries[name])
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
      Polyline: FakePolyline,
      LatLng: FakeLatLng,
      // In the core, before any importLibrary, as on 3.66.
      Geocoder: FakeGeocoder,
      event: {
        trigger () {},
        addListener (instance, event, handler) {
          return instance.addListener(event, handler)
        }
      },
      importLibrary
    }
  }

  const requested = new URL(window.document.currentScript.src).searchParams.get('libraries')
  requested?.split(',').forEach((name) => { window.google.maps[name] = libraries[name] })

  // A click lands on the topmost clickable polygon under it, and on the map only where there is
  // none: a click inside a shell never reaches the map's listeners (measured on 3.66).
  const clickTarget = (map, latLng) =>
    registry.polygons.filter((polygon) => polygon.map === map && polygon.options.clickable !== false && containsLocation(latLng, polygon)).pop() || map

  window.__fakeMaps = {
    registry,

    geocoderReply: { status: 'OK', location: { lat: 32.5322, lng: -117.0372 } },

    // On the map the person last saw: a theme switch builds another.
    click (point) {
      const map = registry.maps[registry.maps.length - 1]
      const latLng = toLatLng(point)

      clickTarget(map, latLng).emit('click', { latLng, stop () {} })
    },

    // On the line being drawn, which takes the click: a vertex reports `vertex`, the handle
    // halfway along a segment `edge`, and the line between them neither (measured on 3.66).
    clickVertex (vertex) {
      const line = registry.polylines[registry.polylines.length - 1]

      line?.emit('click', { vertex, latLng: line.getPath().getAt(vertex), stop () {} })
    },

    clickMidpoint (edge) {
      const line = registry.polylines[registry.polylines.length - 1]
      const [from, to] = [line.getPath().getAt(edge), line.getPath().getAt(edge + 1)]

      line.emit('click', { edge, latLng: toLatLng({ lat: (from.lat() + to.lat()) / 2, lng: (from.lng() + to.lng()) / 2 }), stop () {} })
    },

    clickLine (point) {
      registry.polylines[registry.polylines.length - 1].emit('click', { latLng: toLatLng(point), stop () {} })
    },

    // The person picks a suggestion: the element shows its text and fires `gmp-select`.
    selectPlace (place) {
      registry.autocompletes.filter((element) => element.isConnected).forEach((element) => {
        element.value = place.formattedAddress

        const event = new window.Event('gmp-select')
        event.placePrediction = { toPlace: () => new FakePlace(place) }
        element.dispatchEvent(event)
      })
    },

    // Where a drag leaves the pin, `position` reads back as a literal (measured on 3.66).
    dragMarker (index, point) {
      const marker = registry.markers[index]

      marker.position = { lat: point.lat, lng: point.lng }
      marker.emit('gmp-dragend')
    },

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
