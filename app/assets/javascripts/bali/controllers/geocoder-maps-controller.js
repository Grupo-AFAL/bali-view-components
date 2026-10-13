import { Controller } from '@hotwired/stimulus'
import * as formatters from '../utils/formatters.js'
import { hostColorScheme, observeHostColorScheme } from '../utils/color-scheme.js'
import { inLanguageOf } from '../utils/language.js'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968
const DEFAULT_ZOOM = 15
const TIJUANA_CITY = 'Tijuana'

const TEXTS = {
  en: { addressNotFound: 'We could not find that address on the map.' },
  es: { addressNotFound: 'No encontramos esa dirección en el mapa.' }
}

export class GeocoderMapsController extends Controller {
  static values = { draggableMarker: { type: Boolean, default: false } }
  static targets = [
    'map',
    'latitude',
    'longitude',
    'streetNumber',
    'route',
    'sublocalityLevel1',
    'locality',
    'administrativeAreaLevel1',
    'country',
    'postalCode'
  ]

  async connect () {
    this.themeObserver = observeHostColorScheme(this.rebuildMap)
    // On the element, not on each field: a field put in later geocodes too.
    this.element.addEventListener('change', this.geocodeAddress)

    const { default: GoogleMapsLoader, googleMapsConfig } = await import('../utils/google-maps-loader.js')

    const testMode = this.data.get('testMode') === 'true'
    if (testMode) return

    const { key, language, mapId } = googleMapsConfig({ key: this.data.get('key') })
    this.mapId = mapId

    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['marker'],
        key,
        language,
        // No deadline: a script that arrives late still builds.
        timeout: 0
      })
      // Removed during the await, nothing would destroy it; moved, the other connect builds it.
      if (this.map || !this.element.isConnected) return

      this.initializeMap()
      this.initializeAddress()
    } catch (error) {
      console.error(error)
    }
  }

  disconnect () {
    this.themeObserver.disconnect()
    this.element.removeEventListener('change', this.geocodeAddress)
  }

  initializeMap (center = { lat: TIJUANA_LAT, lng: TIJUANA_LNG }, zoom = DEFAULT_ZOOM) {
    const { DARK, LIGHT } = this.googleMaps.ColorScheme

    this.map = new this.googleMaps.Map(this.mapTarget, {
      center,
      zoom,
      mapId: this.mapId,
      colorScheme: hostColorScheme() === 'dark' ? DARK : LIGHT
    })
  }

  // Google reads `colorScheme` only while it builds a map, so a theme switch builds another
  // in the same element and moves the pin onto it.
  rebuildMap = () => {
    if (!this.map) return

    this.initializeMap(this.map.getCenter(), this.map.getZoom())
    if (this.marker) this.marker.map = this.map
  }

  initializeAddress () {
    if (this.isAddressPresent()) {
      this.setAddressPin({
        lat: formatters.toFloat(this.latitudeTarget.value),
        lng: formatters.toFloat(this.longitudeTarget.value)
      })
    } else {
      this.geolocate()
    }
  }

  get addressFields () {
    return [
      this.routeTarget,
      this.streetNumberTarget,
      this.sublocalityLevel1Target,
      this.localityTarget,
      this.postalCodeTarget
    ]
  }

  geocodeAddress = ({ target }) => {
    if (!this.map || !this.addressFields.includes(target)) return

    const geocoder = new this.googleMaps.Geocoder()
    geocoder.geocode({ address: this.getAddress() }, (results, status) => {
      if (status === 'OK') {
        const location = results[0].geometry.location.toJSON()
        this.setAddressPin(location)
        this.setLatLng(location)
      } else if (status === 'ZERO_RESULTS') {
        window.alert(inLanguageOf(this.element, TEXTS).addressNotFound)
      } else {
        // A denied key or a spent quota is for the app to fix, not the person filling the form.
        console.error(`Geocoding the address failed: ${status}`)
      }
    })
  }

  getAddress () {
    return [
      `${this.routeTarget.value} ${this.streetNumberTarget.value}`,
      this.sublocalityLevel1Target.value,
      this.postalCodeTarget.value,
      this.getCity(),
      'Baja California'
    ].join(', ')
  }

  getCity () {
    if (this.hasLocalityTarget && this.localityTarget.value.length > 0) {
      return this.localityTarget.value
    }

    return TIJUANA_CITY
  }

  isAddressPresent () {
    return (
      this.latitudeTarget.value.length > 0 &&
      this.longitudeTarget.value.length > 0
    )
  }

  setAddressPin (position) {
    this.map.setCenter(position)
    this.map.setZoom(DEFAULT_ZOOM)

    if (this.marker) {
      this.marker.position = position
      return
    }

    this.marker = new this.googleMaps.marker.AdvancedMarkerElement({
      map: this.map,
      position,
      gmpDraggable: this.draggableMarkerValue
    })
    // Read back after a drag, `position` is a literal, not a LatLng (3.66).
    this.marker.addEventListener('gmp-dragend', () => this.setLatLng(this.marker.position))
  }

  setLatLng ({ lat, lng }) {
    this.latitudeTarget.value = lat
    this.longitudeTarget.value = lng
  }

  geolocate = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(position => {
        const geolocation = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }

        this.map.setCenter(geolocation)
        this.map.setZoom(DEFAULT_ZOOM)
      })
    }
  }
}
