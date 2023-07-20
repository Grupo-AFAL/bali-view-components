import { Controller } from '@hotwired/stimulus'
import { GoogleMapsLoader, formatters } from '..'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968
const DEFAULT_ZOOM = 15
const TIJUANA_CITY = 'Tijuana'

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
    const testMode = this.data.get('testMode') === 'true'
    if (testMode) return

    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['places'],
        language: 'es',
        key: this.data.get('key')
      })
      this.initializeMap()
      this.initializeAddressListeners()
      this.initializeAddress()
    } catch (error) {
      console.error(error)
    }
  }

  initializeMap () {
    this.map = new this.googleMaps.Map(this.mapTarget, {
      center: {
        lat: TIJUANA_LAT,
        lng: TIJUANA_LNG
      },
      zoom: DEFAULT_ZOOM
    })
  }

  initializeAddressListeners () {
    this.routeTarget.addEventListener('change', this.geocodeAddress)
    this.streetNumberTarget.addEventListener('change', this.geocodeAddress)
    this.sublocalityLevel1Target.addEventListener('change', this.geocodeAddress)
    this.localityTarget.addEventListener('change', this.geocodeAddress)
    this.postalCodeTarget.addEventListener('change', this.geocodeAddress)
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

  geocodeAddress = () => {
    const geocoder = new this.googleMaps.Geocoder()
    geocoder.geocode({ address: this.getAddress() }, (results, status) => {
      if (status === 'OK') {
        this.setAddressPin(results[0].geometry.location)
        this.setLatLng(results[0].geometry.location)
      } else {
        window.alert('Geocode was not successful for the following reason: ' + status)
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

  setAddressPin (location) {
    this.map.setCenter(location)
    this.map.setZoom(DEFAULT_ZOOM)

    if (this.marker) {
      this.marker.setMap(null)
    }

    this.marker = new this.googleMaps.Marker({
      map: this.map,
      position: location,
      animation: this.googleMaps.Animation.DROP,
      draggable: this.draggableMarkerValue
    })
    this.marker.addListener('dragend', () => {
      this.setLatLng(this.marker.getPosition())
    })
  }

  setLatLng (location) {
    this.latitudeTarget.value = location.lat()
    this.longitudeTarget.value = location.lng()
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
