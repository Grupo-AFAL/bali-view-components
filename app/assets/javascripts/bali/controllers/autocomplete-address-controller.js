import { Controller } from '@hotwired/stimulus'

const COMPONENTS = {
  street_number: ['streetNumber', 'shortText'],
  route: ['street', 'longText'],
  sublocality_level_1: ['neighbourhood', 'shortText'],
  locality: ['city', 'shortText'],
  administrative_area_level_1: ['state', 'shortText'],
  country: ['country', 'longText'],
  postal_code: ['postalCode', 'shortText']
}

export class AutocompleteAddressController extends Controller {
  static values = { apiKey: String }
  static targets = [
    'input',
    'street',
    'streetNumber',
    'neighbourhood',
    'city',
    'state',
    'country',
    'postalCode',
    'latitude',
    'longitude'
  ]

  async connect () {
    // Turbo snapshots the page while it is still connected: left in, the box would come back
    // beside the one the next connect builds.
    document.addEventListener('turbo:before-cache', this.teardown)

    const { default: GoogleMapsLoader, googleMapsConfig } = await import('../utils/google-maps-loader.js')
    const { key, language } = googleMapsConfig({ key: this.apiKeyValue })

    try {
      this.googleMaps = await GoogleMapsLoader({
        libraries: ['places'],
        key,
        language,
        // No deadline: a script that arrives late still builds.
        timeout: 0
      })
      // Removed during the await, nothing would destroy it; moved, the other connect builds it.
      if (this.autocomplete || !this.element.isConnected) return

      this.initializeAutocomplete()
    } catch (error) {
      console.error(error)
    }
  }

  disconnect () {
    document.removeEventListener('turbo:before-cache', this.teardown)
    this.teardown()
  }

  // `google.maps.places.Autocomplete` is closed to new customers since March 2025, and its
  // successor draws its own input and cannot take ours. It is a form-associated element, so it
  // submits under the input's name while the input sits hidden and disabled.
  initializeAutocomplete () {
    const { id, name, value, placeholder, disabled, readOnly } = this.inputTarget
    // The box has no read-only state, and the teardown hands back an enabled input.
    if (disabled || readOnly) return

    this.autocomplete = new this.googleMaps.places.PlaceAutocompleteElement({ name, value, placeholder })
    this.autocomplete.addEventListener('gmp-select', this.fillInAddress)
    // It is labelable: with the input's id a `<label for>` names it, where it would otherwise read
    // Google's own «Buscar un sitio» (3.66).
    if (id) {
      this.inputTarget.removeAttribute('id')
      this.autocomplete.id = id
    }

    this.inputTarget.after(this.autocomplete)
    this.inputTarget.hidden = true
    this.inputTarget.disabled = true
  }

  teardown = () => {
    if (!this.autocomplete) return

    this.inputTarget.value = this.autocomplete.value
    if (this.autocomplete.id) this.inputTarget.id = this.autocomplete.id
    this.inputTarget.hidden = false
    this.inputTarget.disabled = false
    this.autocomplete.remove()
    this.autocomplete = null
  }

  fillInAddress = async ({ placePrediction }) => {
    const place = placePrediction.toPlace()
    await place.fetchFields({ fields: ['addressComponents', 'location'] })

    for (const component of place.addressComponents) {
      const [target, text] = COMPONENTS[component.types[0]] || []
      if (target) this.targets.find(target).value = component[text]
    }

    this.latitudeTarget.value = place.location.lat()
    this.longitudeTarget.value = place.location.lng()
  }
}
