import { Controller } from '@hotwired/stimulus'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968

export class LocationsMapController extends Controller {
  static targets = ['map', 'location', 'card']
  static values = {
    enableClustering: Boolean,
    zoom: { type: Number, default: 12 },
    centerLatitude: { type: Number, default: TIJUANA_LAT },
    centerLongitude: { type: Number, default: TIJUANA_LNG },
    locale: { type: String, default: 'en' },
    apiKey: { type: String, default: '' },
    minWindowWidth: { type: Number, default: 768 }
  }

  async connect () {
    const { default: GoogleMapsLoader } = await import('bali/utils/google-maps-loader')
    const { MarkerClusterer } = await import('@googlemaps/markerclusterer')
    this.MarkerClusterer = MarkerClusterer

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
      this.markerCluster = new this.MarkerClusterer({ map: this.map, markers })
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

      if (this.hasCardTarget && window.innerWidth > this.minWindowWidthValue) {
        infowindow.addListener('closeclick', this.unselectCards)

        marker.addListener('click', (e) => {
          e.stop()

          this.unselectCards()
          this.selectCards(e.latLng.lat(), e.latLng.lng())
        })
      }

      marker.addListener('click', (e) => {
        e.stop()

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

  unselectCards = () => {
    this.cardTargets.forEach(card => { card.classList.remove('is-selected') })
  }

  selectCards = (lat, lng) => {
    let scrolledIntoView = false

    for (const card of this.cardTargets) {
      if (parseFloat(card.dataset.latitude) !== lat || parseFloat(card.dataset.longitude) !== lng) continue

      card.classList.add('is-selected')
      if (!scrolledIntoView) {
        card.scrollIntoView({ behavior: 'smooth', block: 'center' })
        scrolledIntoView = true
      }
    }
  }
}
