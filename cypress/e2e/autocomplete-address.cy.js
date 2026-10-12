import { stubGoogleMaps } from '../support/google_maps'

// #1423 — `google.maps.places.Autocomplete` is closed to new customers since March 2025. The
// controller builds a `<gmp-place-autocomplete>` (Places API (New)) in place of its `input`
// target, which has to keep feeding the form and the nine address targets.
describe('autocomplete-address', () => {
  const PLACE = {
    formattedAddress: 'Av. Revolución 1234, Zona Centro, 22000 Tijuana, B.C., México',
    location: { lat: 32.5322, lng: -117.0372 },
    addressComponents: [
      { longText: '1234', shortText: '1234', types: ['street_number'] },
      { longText: 'Avenida Revolución', shortText: 'Av. Revolución', types: ['route'] },
      { longText: 'Zona Centro', shortText: 'Zona Centro', types: ['sublocality_level_1', 'sublocality', 'political'] },
      { longText: 'Tijuana', shortText: 'Tijuana', types: ['locality', 'political'] },
      { longText: 'Baja California', shortText: 'B.C.', types: ['administrative_area_level_1', 'political'] },
      { longText: 'México', shortText: 'MX', types: ['country', 'political'] },
      { longText: '22000', shortText: '22000', types: ['postal_code'] }
    ]
  }

  const TARGETS = ['street', 'streetNumber', 'neighbourhood', 'city', 'state', 'country', 'postalCode', 'latitude', 'longitude']

  const mount = ({ attributes = '', built = true } = {}) => {
    cy.visit('/bali/empty_state/default')
    cy.get('body').then(([body]) => body.insertAdjacentHTML('beforeend', `
      <form id="address-form">
        <div data-controller="autocomplete-address">
          <label for="address">Address</label>
          <input type="text" id="address" name="address" value="Calle 5" placeholder="Search address" data-autocomplete-address-target="input" ${attributes}>
          ${TARGETS.map((target) => `<input type="text" name="${target}" data-autocomplete-address-target="${target}">`).join('')}
        </div>
      </form>`))
    if (built) {
      cy.window().should((win) => expect(win.__fakeMaps?.registry.autocompletes, 'autocomplete built').to.have.length(1))
      return
    }

    // Nothing to wait for when it builds no box: it would have, a microtask after the import.
    cy.window().should((win) => expect(win.google?.maps?.places, 'places imported').to.not.eq(undefined))
    cy.wait(50)
  }

  const controllerElement = () => cy.get('[data-controller="autocomplete-address"]')
  const submitted = (form) => [...new FormData(form).entries()].filter(([name]) => name === 'address')

  beforeEach(() => {
    cy.viewport(1280, 900)
    stubGoogleMaps()
  })

  it('shows one search box, Google\'s, with the placeholder and the value of the input', () => {
    mount()

    controllerElement().should(([element]) => {
      const boxes = element.querySelectorAll('gmp-place-autocomplete')
      const input = element.querySelector('[data-autocomplete-address-target="input"]')

      expect(boxes, 'gmp-place-autocomplete').to.have.length(1)
      expect(boxes[0].placeholder).to.eq('Search address')
      expect(boxes[0].value).to.eq('Calle 5')
      expect(input.hidden, 'input hidden').to.eq(true)
    })
  })

  it('is the field the `<label for>` of the input names', () => {
    mount()

    controllerElement().should(([element]) => {
      expect(element.querySelector('label').control).to.eq(element.querySelector('gmp-place-autocomplete'))
    })
  })

  it('fills the address fields from the place the person picks', () => {
    mount()

    cy.window().then((win) => win.__fakeMaps.selectPlace(PLACE))

    controllerElement().should(([element]) => {
      const values = Object.fromEntries(TARGETS.map((target) =>
        [target, element.querySelector(`[data-autocomplete-address-target="${target}"]`).value]))

      expect(values).to.deep.eq({
        street: 'Avenida Revolución',
        streetNumber: '1234',
        neighbourhood: 'Zona Centro',
        city: 'Tijuana',
        state: 'B.C.',
        country: 'México',
        postalCode: '22000',
        latitude: '32.5322',
        longitude: '-117.0372'
      })
    })
  })

  it('submits the picked address under the name of the input, once', () => {
    mount()
    cy.get('#address-form').should(([form]) => expect(submitted(form)).to.deep.eq([['address', 'Calle 5']]))

    cy.window().then((win) => win.__fakeMaps.selectPlace(PLACE))

    cy.get('#address-form').should(([form]) => expect(submitted(form)).to.deep.eq([['address', PLACE.formattedAddress]]))
  })

  // The element declares `color-scheme: light dark` on itself, which follows the operating system.
  it('takes the color scheme of the page', () => {
    mount()

    cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'afal-dark'))

    controllerElement().should(([element]) => {
      const box = element.querySelector('gmp-place-autocomplete')

      expect(box && element.ownerDocument.defaultView.getComputedStyle(box).colorScheme).to.eq('dark')
    })
  })

  // Turbo snapshots the page before it leaves: a `<gmp-place-autocomplete>` left in it comes back
  // beside the one the next connect builds.
  it('hands the input back, with what the box held, before Turbo caches the page', () => {
    mount()
    controllerElement().then(([element]) => {
      const box = element.querySelector('gmp-place-autocomplete')
      if (box) box.value = 'Calle 7'
    })

    cy.document().then((doc) => doc.dispatchEvent(new Event('turbo:before-cache')))

    controllerElement().should(([element]) => {
      const input = element.querySelector('[data-autocomplete-address-target="input"]')

      expect(element.querySelectorAll('gmp-place-autocomplete'), 'gmp-place-autocomplete').to.have.length(0)
      expect([input.hidden, input.disabled, input.value, input.id]).to.deep.eq([false, false, 'Calle 7', 'address'])
    })
  })

  ;['disabled', 'readonly'].forEach((attribute) => {
    it(`leaves a ${attribute} input as it is`, () => {
      const expectUntouched = () => controllerElement().should(([element]) => {
        const input = element.querySelector('[data-autocomplete-address-target="input"]')

        expect(element.querySelectorAll('gmp-place-autocomplete'), 'gmp-place-autocomplete').to.have.length(0)
        expect([input.hidden, input.disabled, input.readOnly]).to.deep.eq([false, attribute === 'disabled', attribute === 'readonly'])
      })

      mount({ attributes: attribute, built: false })
      expectUntouched()

      cy.document().then((doc) => doc.dispatchEvent(new Event('turbo:before-cache')))
      expectUntouched()
    })
  })

  it('builds one box again when it is moved', () => {
    mount()

    controllerElement().then(([element]) => element.parentNode.append(element))

    cy.window().should((win) => expect(win.__fakeMaps.registry.autocompletes, 'built twice').to.have.length(2))
    controllerElement().should(([element]) => {
      expect(element.querySelectorAll('gmp-place-autocomplete'), 'gmp-place-autocomplete').to.have.length(1)
    })
  })
})
