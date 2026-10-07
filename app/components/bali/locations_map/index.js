import { Controller } from '@hotwired/stimulus'
import { optionalPeer } from '../../../assets/javascripts/bali/utils/optional-peer.js'
import { hostColorScheme, observeHostColorScheme } from '../../../assets/javascripts/bali/utils/color-scheme.js'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968

export class LocationsMapController extends Controller {
  static targets = ['map', 'location', 'card']
  static values = {
    enableClustering: Boolean,
    fitToLocations: Boolean,
    zoom: { type: Number, default: 12 },
    centerLatitude: { type: Number, default: TIJUANA_LAT },
    centerLongitude: { type: Number, default: TIJUANA_LNG },
    locale: { type: String, default: 'en' },
    apiKey: { type: String, default: '' },
    minWindowWidth: { type: Number, default: 768 }
  }

  async connect () {
    this.themeObserver = observeHostColorScheme(this.rebuildMap)

    const { default: GoogleMapsLoader } = await import('../../../assets/javascripts/bali/utils/google-maps-loader.js')
    const clusterer = await import('@googlemaps/markerclusterer')
      .catch(optionalPeer('@googlemaps/markerclusterer'))
    if (!clusterer) return
    this.MarkerClusterer = clusterer.MarkerClusterer

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

      if (this.fitToLocationsValue) this.fitMapToLocations()
    } catch (error) {
      console.error(error)
    }
  }

  disconnect () {
    this.themeObserver.disconnect()
  }

  // Frames every location instead of trusting center/zoom. fitBounds picks
  // whatever zoom contains the bounds — for a single location (or a very tight
  // cluster) that is street level, so zoomValue acts as the ceiling the map
  // never zooms in past.
  fitMapToLocations = () => {
    if (this.locations.length === 0) return

    const bounds = new this.googleMaps.LatLngBounds()
    this.locations.forEach(({ lat, lng }) => bounds.extend({ lat, lng }))

    const listener = this.map.addListener('bounds_changed', () => {
      listener.remove()
      if (this.map.getZoom() > this.zoomValue) this.map.setZoom(this.zoomValue)
    })

    this.map.fitBounds(bounds)
  }

  initializeMap = (
    center = { lat: this.centerLatitudeValue, lng: this.centerLongitudeValue },
    zoom = this.zoomValue
  ) => {
    const { DARK, LIGHT } = this.googleMaps.ColorScheme

    this.map = new this.googleMaps.Map(this.mapTarget, {
      center,
      zoom,
      mapId: Date.now().toString(),
      colorScheme: hostColorScheme() === 'dark' ? DARK : LIGHT
    })
  }

  // Google reads `colorScheme` only while it builds a map, so a theme switch builds another
  // in the same element and moves onto it what the person had on this one.
  rebuildMap = () => {
    if (!this.map) return

    this.initializeMap(this.map.getCenter(), this.map.getZoom())

    if (this.markerCluster) {
      // Moved with setMap, a clusterer paints nothing on the new map: its algorithm sees the
      // zoom and markers it already clustered and reports no change (markerclusterer 2.6.2).
      this.markerCluster.setMap(null)
      this.markerCluster = new this.MarkerClusterer({ map: this.map, markers: this.markers })
    } else {
      this.markers.forEach(marker => { marker.map = this.map })
    }

    if (this.openInfoWindow?.isOpen) this.openInfoWindow.open(this.map, this.openInfoWindowAnchor)
  }

  addMarkers = () => {
    this.markers = this.locations.map(location =>
      this.generateMarker(location)
    )

    if (this.enableClusteringValue) {
      this.markerCluster = new this.MarkerClusterer({ map: this.map, markers: this.markers })
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
        this.openInfoWindowAnchor = marker
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
