import { Controller } from '@hotwired/stimulus'
import GoogleMapsLoader from 'bali/utils/google-maps-loader'

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

  async connect () {
    this.drawnPolygons = []

    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['drawing', 'geometry'],
        language: 'es',
        key: this.data.get('key')
      })

      const polygonOptions = {
        fillColor: '#eaeaea',
        fillOpacity: 0.6,
        strokeWeight: this.strokeWeightValue,
        clickable: this.clickableValue,
        editable: this.editableValue,
        draggable: this.draggableValue,
        zIndex: 1
      }

      this.initializeMaps()
      this.initializeDrawing(polygonOptions)
      this.initializeDrawingManager(polygonOptions)
      this.setDrawingManagerListener()
    } catch (error) {
      console.error(error)
    }
  }

  initializeMaps () {
    this.map = new this.googleMaps.Map(this.mapTarget, {
      center: {
        lat: this.latitudeValue,
        lng: this.longitudeValue
      },
      zoom: this.zoomValue
    })
  }

  initializeDrawing (polygonOptions) {
    const parsedValue = JSON.parse(this.polygonFieldTarget.value)
    if (this.isLegacyFormat(parsedValue)) {
      const paths = Array.isArray(parsedValue) ? parsedValue : []
      this.drawAndConfigurePolygonFromPaths(paths, polygonOptions, false)
    }

    const shells = parsedValue.shells || []
    const holes = parsedValue.holes || []

    shells.forEach((paths) => {
      this.drawAndConfigurePolygonFromPaths(paths, polygonOptions, false)
    })

    holes.forEach((paths) => {
      this.drawAndConfigurePolygonFromPaths(paths, polygonOptions, true)
    })
  }

  initializeDrawingManager (polygonOptions) {
    if (!this.editableValue) return

    this.drawingManager = new this.googleMaps.drawing.DrawingManager({
      drawingMode: this.googleMaps.drawing.OverlayType.POLYGON,
      drawingControl: true,
      drawingControlOptions: {
        position: this.googleMaps.ControlPosition.TOP_CENTER,
        drawingModes: [this.googleMaps.drawing.OverlayType.POLYGON]
      },
      polygonOptions
    })
    this.drawingManager.setMap(this.map)
  }

  setDrawingManagerListener () {
    if (!this.editableValue) return

    this.googleMaps.event.addListener(
      this.drawingManager,
      'polygoncomplete',
      this.storePolygonAndAddListeners
    )
  }

  storePolygonAndAddListeners = (polygon) => {
    polygon.metadata ||= {}
    polygon.metadata.hole = false

    if (this.isHole(polygon)) {
      polygon.metadata.hole = true
      polygon.fillColor = 'red'
    }

    this.setPolygonListener(polygon)
    this.drawnPolygons.push(polygon)
    this.storeCoordinates()
  }

  isHole = (polygon) => {
    if (this.drawnPolygons.length === 0) return false

    const polygonVertices = polygon.getPath().getArray()
    let result = false
    for (const drawnPolygon of this.drawnPolygons) {
      const allVerticesWithinPolygon = polygonVertices.every((vertice) => {
        return this.googleMaps.geometry.poly.containsLocation(vertice, drawnPolygon)
      })

      if (allVerticesWithinPolygon) {
        result = true
        break
      }
    }

    return result
  }

  setPolygonListener = (polygon) => {
    polygon.getPaths().forEach((path, index) => {
      this.googleMaps.event.addListener(path, 'set_at', () => this.storeCoordinates())
      this.googleMaps.event.addListener(path, 'insert_at', () => this.storeCoordinates())
    })
  }

  coordinatesFromDrawnPolygons = () => {
    const shellsCoordinates = []
    const holesCoordinates = []
    this.drawnPolygons.forEach(polygon => {
      const coordinates = []
      polygon.getPaths().forEach((path, index) => {
        path.forEach((latlng, index) => {
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

  drawAndConfigurePolygonFromPaths = (paths, polygonOptions, hole) => {
    const polygon = new this.googleMaps.Polygon({ ...polygonOptions, paths })
    polygon.setMap(this.map)
    polygon.metadata = { hole }
    this.drawnPolygons.push(polygon)
    this.setPolygonListener(polygon)

    if (hole) {
      polygon.fillColor = 'red'
    }
  }

  clear = () => {
    if (!window.confirm(this.confirmationMessageToClearValue)) return

    this.drawnPolygons.forEach((polygon) => polygon.setMap(null))
    this.drawnPolygons = []
    this.storeCoordinates()
  }

  clearHoles = () => {
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
