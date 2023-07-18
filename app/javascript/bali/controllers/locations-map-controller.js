import { Controller } from '@hotwired/stimulus'
import { GoogleMapsLoader } from '..'
import { MarkerClusterer } from '@googlemaps/markerclusterer'

const TIJUANA_LAT = 32.5036383
const TIJUANA_LNG = -117.0308968

export class LocationsMapController extends Controller {
  static targets = ['container', 'userAddress']
  static values = {
    enableClustering: Boolean,
    zoom: { type: Number, default: 12 },
    centerLatitude: { type: Number, default: TIJUANA_LAT },
    centerLongitude: { type: Number, default: TIJUANA_LNG }
  }

  connect = async () => {
    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['drawing'],
        language: 'es',
        key: this.data.get('key')
      })

      this.googleMarkers = await this.googleMaps.importLibrary('marker')

      this.userAddresses = this.loadUserAddresses()
      this.initializeMap()
      this.addMarkers()
    } catch (error) {
      console.error(error)
    }
  }

  initializeMap = () => {
    this.map = new this.googleMaps.Map(this.containerTarget, {
      center: { lat: this.centerLatitudeValue, lng: this.centerLongitudeValue },
      zoom: this.zoomValue,
      mapId: Date.now().toString()
    })
  }

  addMarkers = () => {
    const markers = this.userAddresses.map(userAddress => this.generateMarker(userAddress))

    if (this.enableClusteringValue) {
      this.markerCluster = new MarkerClusterer({ map: this.map, markers })
    }
  }

  generateMarker = userAddress => {
    const infowindow = new this.googleMaps.InfoWindow({
      content: this.infoWindowTemplate(userAddress)
    })

    const position = { lat: userAddress.lat, lng: userAddress.lng }

    const marker = new this.googleMarkers.AdvancedMarkerElement({
      position,
      map: this.map,
      title: userAddress.name,
      content: this.markerContentElement(userAddress)
    })

    marker.addListener('click', () => {
      if (this.openInfoWindow) {
        this.openInfoWindow.close()
        this.openInfoWindow = null
      }

      this.map.setCenter(position)

      infowindow.open(this.map, marker)
      this.openInfoWindow = infowindow
    })

    return marker
  }

  markerContentElement = (userAddress) => {
    if (userAddress.marker.url) {
      const img = document.createElement('img')
      img.src = userAddress.marker.url
      return img
    }

    const pinElement = new this.googleMarkers.PinElement({
      background: userAddress.marker.color,
      borderColor: userAddress.marker.borderColor || userAddress.marker.color,
      glyph: userAddress.marker.label,
      glyphColor: userAddress.marker.label ? 'white' : null
    })
    return pinElement.element
  }

  loadUserAddresses = () => {
    return this.userAddressTargets.map(target => {
      const data = target.dataset

      return {
        name: data.name,
        phone: data.phone,
        street: data.street,
        streetNumber: data.streetNumber,
        additionalInfo: data.additionalInfo,
        neighbourhood: data.neighbourhood,
        postalCode: data.postalCode,
        deliveredAt: data.deliveredAt,
        lat: parseFloat(data.lat),
        lng: parseFloat(data.lng),
        marker: {
          url: data.markerUrl, label: data.markerLabel, color: data.markerColor,
          borderColor: data.markerBorderColor
        }
      }
    })
  }

  infoWindowTemplate = (userAddress) => {
    let additionalInfo = ''
    if (userAddress.additionalInfo.lenght > 0) {
      additionalInfo = `${userAddress.additionalInfo} <br />`
    }

    let phone = ''
    if (userAddress.phone) {
      phone = `
        <h6 class="title is-6 mt-1">Teléfono</h6>
        <p class="subtitle is-6">${userAddress.phone}</p>`
    }

    let deliveredAt = ''
    if (userAddress.deliveredAt) {
      deliveredAt = `
      <h6 class="title is-6 mt-1">Entregado</h6>
      <p class="subtitle is-6">${userAddress.deliveredAt}</p>`
    }

    return `
      <div class="info-window">
        <h5 class="title is-5">${userAddress.name}</h5>

        <h6 class="title is-6">Dirección</h6>
        <p class="subtitle is-6">
          ${userAddress.street} ${userAddress.streetNumber} <br />
          ${additionalInfo}
          ${userAddress.neighbourhood}, ${userAddress.postalCode} <br />
        </p>

        ${phone}

        ${deliveredAt}
      </div>
      `
  }
}
