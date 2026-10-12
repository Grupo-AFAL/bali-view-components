import { Controller } from '@hotwired/stimulus'
import { hostColorScheme, observeHostColorScheme } from '../utils/color-scheme.js'

export class DrawingMapsController extends Controller {
  static targets = ['map', 'polygonField']
  static values = {
    latitude: { type: Number, default: 32.5139659 },
    longitude: { type: Number, default: -117.0087694 },
    zoom: { type: Number, default: 12 },
    strokeWeight: { type: Number, default: 5 },
    clickable: { type: Boolean, default: true },
    editable: { type: Boolean, default: true },
    draggable: { type: Boolean, default: true },
    confirmationMessageToClear: { type: String, default: 'Would you like to continue?' }
  }

  // Not with the map: «Clear» and «Clear holes» sit beside it in the form and work before the
  // script has arrived.
  initialize () {
    this.drawnPolygons = []
  }

  async connect () {
    this.themeObserver = observeHostColorScheme(this.rebuildMap)

    const { default: GoogleMapsLoader } = await import('../utils/google-maps-loader.js')

    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['geometry'],
        language: 'es',
        key: this.data.get('key'),
        // No deadline: a script that arrives late still builds.
        timeout: 0
      })
      // Removed during the await, nothing would destroy it; moved, the other connect builds it.
      if (this.map || !this.element.isConnected) return

      this.polygonOptions = {
        fillColor: '#eaeaea',
        fillOpacity: 0.6,
        strokeWeight: this.strokeWeightValue,
        clickable: this.clickableValue,
        editable: this.editableValue,
        draggable: this.draggableValue,
        zIndex: 1
      }

      this.initializeMaps()
      this.initializeDrawing()
    } catch (error) {
      console.error(error)
    }
  }

  disconnect () {
    this.themeObserver.disconnect()
  }

  initializeMaps (center = { lat: this.latitudeValue, lng: this.longitudeValue }, zoom = this.zoomValue) {
    const { DARK, LIGHT } = this.googleMaps.ColorScheme

    this.map = new this.googleMaps.Map(this.mapTarget, {
      center,
      zoom,
      colorScheme: hostColorScheme() === 'dark' ? DARK : LIGHT,
      // While drawing, a click on a place's icon adds a vertex instead of opening the place.
      clickableIcons: !this.editableValue,
      ...(this.editableValue && { draggableCursor: 'crosshair' })
    })

    if (this.editableValue) this.map.addListener('click', this.addVertex)
  }

  // Google reads `colorScheme` only while it builds a map, so a theme switch builds another
  // in the same element and moves onto it what the person had drawn on this one.
  rebuildMap = () => {
    if (!this.map) return

    this.initializeMaps(this.map.getCenter(), this.map.getZoom())
    this.drawnPolygons.forEach(polygon => polygon.setMap(this.map))
    this.sketch?.setMap(this.map)
  }

  initializeDrawing () {
    const parsedValue = JSON.parse(this.polygonFieldTarget.value)
    // The builder renders a field with no value as `[]`: a ring with no vertex, not a shell.
    if (this.isLegacyFormat(parsedValue) && parsedValue.length > 0) {
      this.addPolygon(parsedValue, false)
    }

    const shells = parsedValue.shells || []
    const holes = parsedValue.holes || []

    shells.forEach((paths) => this.addPolygon(paths, false))
    holes.forEach((paths) => this.addPolygon(paths, true))
  }

  // Google retired the Drawing Library and its DrawingManager, so the shape is drawn the way that
  // drew it: a click adds a vertex, and a click on the first vertex closes the shape.
  addVertex = ({ latLng }) => {
    if (this.sketch) {
      this.sketch.getPath().push(latLng)
      return
    }

    this.sketch = new this.googleMaps.Polyline({
      map: this.map,
      path: [latLng],
      editable: true,
      strokeWeight: this.strokeWeightValue
    })
    this.sketch.addListener('click', this.clickSketch)
  }

  // A click on the line itself lands on the line, not on the map.
  clickSketch = (event) => {
    if (event.vertex === 0 && this.sketch.getPath().getLength() >= 3) {
      this.closeSketch()
    } else if (event.vertex === undefined) {
      this.addVertex(event)
    }
  }

  closeSketch () {
    const vertices = this.sketch.getPath().getArray()
    this.discardSketch()

    this.addPolygon(vertices, this.isHole(vertices))
    this.storeCoordinates()
  }

  discardSketch () {
    this.sketch?.setMap(null)
    this.sketch = null
  }

  isHole = (vertices) => {
    return this.drawnPolygons.some((drawnPolygon) => {
      return vertices.every((vertex) => this.googleMaps.geometry.poly.containsLocation(vertex, drawnPolygon))
    })
  }

  addPolygon = (paths, hole) => {
    // In the options: assigned to the polygon once built, the colour never reaches the map.
    const polygon = new this.googleMaps.Polygon({
      ...this.polygonOptions,
      ...(hole && { fillColor: 'red' }),
      paths,
      map: this.map
    })
    polygon.metadata = { hole }

    this.drawnPolygons.push(polygon)
    this.setPolygonListener(polygon)
  }

  setPolygonListener = (polygon) => {
    polygon.getPaths().forEach((path) => {
      this.googleMaps.event.addListener(path, 'set_at', () => this.storeCoordinates())
      this.googleMaps.event.addListener(path, 'insert_at', () => this.storeCoordinates())
    })

    // A click inside a polygon lands on the polygon, and that is where a hole is drawn.
    if (this.editableValue) polygon.addListener('click', this.addVertex)
  }

  coordinatesFromDrawnPolygons = () => {
    const shellsCoordinates = []
    const holesCoordinates = []
    this.drawnPolygons.forEach(polygon => {
      const coordinates = []
      polygon.getPaths().forEach((path) => {
        path.forEach((latlng) => {
          coordinates.push({ lat: latlng.lat(), lng: latlng.lng() })
        })
      })

      if (polygon.metadata.hole) {
        holesCoordinates.push(coordinates)
      } else {
        shellsCoordinates.push(coordinates)
      }
    })

    return { shells: shellsCoordinates, holes: holesCoordinates }
  }

  storeCoordinates = () => {
    const shellsAndHolesCoordinates = this.coordinatesFromDrawnPolygons()

    this.polygonFieldTarget.value = JSON.stringify(shellsAndHolesCoordinates)
  }

  isLegacyFormat = (values) => {
    return Array.isArray(values)
  }

  clear = () => {
    if (!window.confirm(this.confirmationMessageToClearValue)) return

    this.discardSketch()
    this.drawnPolygons.forEach((polygon) => polygon.setMap(null))
    this.drawnPolygons = []
    this.storeCoordinates()
  }

  clearHoles = () => {
    // With no map nothing is drawn yet, and storing that would erase the shells in the field.
    if (!this.map) return
    if (!window.confirm(this.confirmationMessageToClearValue)) return

    const shells = this.drawnPolygons.map(polygon => {
      if (!polygon.metadata.hole) return polygon

      polygon.setMap(null)
      return null
    })
    this.drawnPolygons = shells.filter(element => element !== null)

    this.storeCoordinates()
  }
}
