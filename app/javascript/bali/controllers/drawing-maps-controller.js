import { Controller } from '@hotwired/stimulus'
import { GoogleMapsLoader } from '..'

export class DrawingMapsController extends Controller {
  static targets = ['map', 'polygonField']
  static values = {
    latitude: { type: Number, default: 32.5139659 },
    longitude: { type: Number, default: -117.0087694 },
    zoom: { type: Number, default: 12 },
    strokeWeight: { type: Number, default: 5 },
    clickable: { type: Boolean, default: true },
    editable: { type: Boolean, default: true },
    draggable: { type: Boolean, default: true }
  }

  async connect () {
    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['drawing'],
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
    const paths = Array.isArray(parsedValue) ? parsedValue : []
    const polygon = new this.googleMaps.Polygon({ ...polygonOptions, paths })
    polygon.setMap(this.map)
    this.setPolygonListener(polygon)
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
      this.setPolygonListener
    )
  }

  setPolygonListener = polygon => {
    this.storeCoordinates(polygon)
    polygon.addListener('dragend', () => this.storeCoordinates(polygon))
    polygon.addListener('mouseup', () => this.storeCoordinates(polygon))
  }

  storeCoordinates (polygon) {
    const coordinates = []

    polygon.getPaths().forEach((path, index) => {
      path.forEach((latlng, index) => {
        coordinates.push({ lat: latlng.lat(), lng: latlng.lng() })
      })
    })

    this.polygonFieldTarget.value = JSON.stringify(coordinates)
  }
}
