import { Controller } from '@hotwired/stimulus'
import { GoogleMapsLoader } from '../../../javascript/bali'
import { MarkerClusterer } from '@googlemaps/markerclusterer'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968

export class LocationsMapController extends Controller {
  static targets = ['map', 'location']
  static values = {
    enableClustering: Boolean,
    zoom: { type: Number, default: 12 },
    centerLatitude: { type: Number, default: TIJUANA_LAT },
    centerLongitude: { type: Number, default: TIJUANA_LNG },
    locale: { type: String, default: 'en' },
    apiKey: { type: String, default: '' }
  }

  connect = async () => {
    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['drawing'],
        language: this.localeValue,
        key: this.apiKeyValue
      })

      this.googleMarkers = await this.googleMaps.importLibrary('marker')

      this.loadLocations()
      this.initializeMap()
      this.addMarkers()
    } catch (error) {
      console.error(error)
    }
  }

  initializeMap = () => {
    this.map = new this.googleMaps.Map(this.mapTarget, {
      center: { lat: this.centerLatitudeValue, lng: this.centerLongitudeValue },
      zoom: this.zoomValue,
      mapId: Date.now().toString()
    })
  }

  addMarkers = () => {
    const markers = this.locations.map(location =>
      this.generateMarker(location)
    )

    if (this.enableClusteringValue) {
      this.markerCluster = new MarkerClusterer({ map: this.map, markers })
    }
  }

  generateMarker = location => {
    const position = { lat: location.lat, lng: location.lng }

    const marker = new this.googleMarkers.AdvancedMarkerElement({
      position,
      map: this.map,
      title: location.name,
      content: this.markerContentElement(location)
    })

    const infoViewContent = document.getElementById(location.infoViewId)?.innerHTML

    if (infoViewContent) {
      const infowindow = new this.googleMaps.InfoWindow({ content: infoViewContent })

      infowindow.addListener('closeclick', this.unselectLocationCards);

      marker.addListener('click', (e) => {
        e.stop()

        this.unselectLocationCards()
        this.highligthDomElement(e.latLng.lat(), e.latLng.lng());
      })

      marker.addListener('click', (e) => {
        e.stop();

        if (this.openInfoWindow) {
          this.openInfoWindow.close()
          this.openInfoWindow = null
        }

        this.map.setCenter(position)

        infowindow.open(this.map, marker)
        this.openInfoWindow = infowindow
      })
    }

    return marker
  }

  markerContentElement = location => {
    if (location.marker.url) {
      const img = document.createElement('img')
      img.src = location.marker.url
      return img
    }

    const pinElement = new this.googleMarkers.PinElement({
      background: location.marker.color,
      borderColor: location.marker.borderColor || location.marker.color,
      glyph: location.marker.label,
      glyphColor: location.marker.glyphColor || location.marker.color
    })

    return pinElement.element
  }

  loadLocations = () => {
    this.locations = this.locationTargets.map(target => {
      const data = target.dataset

      return {
        infoViewId: data.infoViewId,
        name: data.name,
        lat: parseFloat(data.lat),
        lng: parseFloat(data.lng),
        marker: {
          url: data.markerUrl,
          label: data.markerLabel,
          color: data.markerColor,
          borderColor: data.markerBorderColor,
          glyphColor: data.markerGlyphColor
        }
      }
    })
  }

  unselectLocationCards = () => {
    document.querySelectorAll(`[data-locations-map-target="card"]`)
      .forEach(element => { element.classList.remove('is-selected') })
  }

  highligthDomElement = (lat, lng) => {
    const elements = document.querySelectorAll(
      `[data-locations-map-target="card"][data-latitude="${lat}"][data-longitude="${lng}"]`
    )

    elements[0]?.scrollIntoView({ behavior: "smooth", block: "center" })

    elements.forEach(element => { element.classList.add('is-selected') })
  }
}
