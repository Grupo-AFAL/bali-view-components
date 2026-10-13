import { stubGoogleMaps } from '../support/google_maps'

// #1443 — The four map controllers took the key from three different places, three of them loaded
// the API in Spanish whatever the page, and LocationsMap in the request's locale. All four read
// googleMapsConfig() now: the key and map ID `google_maps_meta_tags` puts in the <head>, and the
// language of the <html>.
describe('Google Maps configuration', () => {
  const PAGE = '<meta name="bali-google-maps-key" content="page-key"><meta name="bali-google-maps-map-id" content="page-map-id">'

  const MARKUP = {
    'drawing-maps': (attributes = '') => `
      <div data-controller="drawing-maps" ${attributes}>
        <div data-drawing-maps-target="map" class="h-96"></div>
        <input type="hidden" value="[]" data-drawing-maps-target="polygonField">
      </div>`,
    'geocoder-maps': () => `
      <div data-controller="geocoder-maps">
        <div data-geocoder-maps-target="map" class="h-96"></div>
        <input type="text" data-geocoder-maps-target="route">
        <input type="text" data-geocoder-maps-target="streetNumber">
        <input type="text" data-geocoder-maps-target="sublocalityLevel1">
        <input type="text" data-geocoder-maps-target="locality">
        <input type="text" data-geocoder-maps-target="postalCode">
        <input type="hidden" value="32.52" data-geocoder-maps-target="latitude">
        <input type="hidden" value="-117.02" data-geocoder-maps-target="longitude">
      </div>`,
    'autocomplete-address': () => `
      <div data-controller="autocomplete-address">
        <input type="text" data-autocomplete-address-target="input">
      </div>`
  }

  // The page is rendered in English; its <html> and <head> are then given what the test needs.
  const visit = ({ lang = 'es-MX', head = PAGE } = {}) => {
    cy.visit('/bali/empty_state/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'warn').as('consoleWarn')
      }
    })
    cy.document().then((doc) => {
      if (lang) doc.documentElement.lang = lang
      else doc.documentElement.removeAttribute('lang')
      doc.head.insertAdjacentHTML('beforeend', head)
    })
  }

  const mount = (markup) => cy.get('body').then(([body]) => body.insertAdjacentHTML('beforeend', markup))

  // As the component renders in English, with no key configured in the dummy.
  const mountLocationsMap = () =>
    cy.request('/bali/locations_map/default').then(({ body }) => {
      mount(new DOMParser().parseFromString(body, 'text/html').querySelector('[data-controller="locations-map"]').outerHTML)
    })

  const loadedWith = (expected) =>
    cy.wait('@mapsApi').its('request.url').should((url) => {
      const params = new URL(url).searchParams

      expect({ key: params.get('key'), language: params.get('language') }).to.deep.eq(expected)
    })

  const mapsBuilt = (callback) =>
    cy.window().should((win) => {
      expect(win.__fakeMaps?.registry.maps, 'map built').to.have.length(1)
      callback(win.__fakeMaps.registry.maps)
    })

  beforeEach(() => {
    cy.viewport(1280, 900)
    stubGoogleMaps()
  })

  it('locations-map loads with the key of the page and the language of the <html>', () => {
    visit()
    mountLocationsMap()

    loadedWith({ key: 'page-key', language: 'es-MX' })
  })

  Object.entries(MARKUP).forEach(([name, markup]) => {
    it(`${name} loads with the key of the page and the language of the <html>`, () => {
      visit()
      mount(markup())

      loadedWith({ key: 'page-key', language: 'es-MX' })
    })
  })

  it('takes a key written on the element over the page\'s', () => {
    visit()
    mount(MARKUP['drawing-maps']('data-drawing-maps-key="element-key"'))

    loadedWith({ key: 'element-key', language: 'es-MX' })
  })

  it('loads in English on a page with no lang', () => {
    visit({ lang: null })
    mount(MARKUP['drawing-maps']())

    loadedWith({ key: 'page-key', language: 'en' })
  })

  it('builds the maps with markers on the map ID of the page', () => {
    visit()
    mountLocationsMap()
    mapsBuilt((maps) => expect(maps[0].options.mapId).to.eq('page-map-id'))

    visit()
    mount(MARKUP['geocoder-maps']())
    mapsBuilt((maps) => expect(maps[0].options.mapId).to.eq('page-map-id'))
  })

  it('makes a map ID up when the page has none', () => {
    visit({ head: '' })
    mount(MARKUP['geocoder-maps']())

    mapsBuilt((maps) => expect(maps[0].options.mapId).to.match(/^\d+$/))
  })

  // On an English page LocationsMap asked for `en` and autocomplete-address for `es`, and the
  // loader warned that the second was ignored.
  it('loads two maps on one page in one language, with no warning', () => {
    visit({ lang: 'en' })
    mountLocationsMap()
    mapsBuilt(() => {})

    mount(MARKUP['autocomplete-address']())

    cy.window().should((win) => expect(win.__fakeMaps.registry.autocompletes, 'autocomplete built').to.have.length(1))
    cy.get('@consoleWarn').should('not.have.been.calledWithMatch', /Google Maps API loads once per page/)
  })

  // The example of docs/guides/external-services.md, as written.
  it('hands a controller of the app the same configuration', () => {
    visit()

    cy.window().then(async (win) => {
      const { key, language, mapId } = win.googleMapsConfig()
      const maps = await win.loadGoogleMapsApi({ key, language })
      // eslint-disable-next-line no-new
      new maps.Map(win.document.body, { center: { lat: 32.52, lng: -117.02 }, zoom: 15, mapId })
    })

    loadedWith({ key: 'page-key', language: 'es-MX' })
    mapsBuilt((maps) => expect(maps[0].options.mapId).to.eq('page-map-id'))
  })
})
