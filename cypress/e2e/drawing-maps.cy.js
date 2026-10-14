import { stubGoogleMaps } from '../support/google_maps'

// #1423 — Google retired the Drawing Library, so `google.maps.drawing.DrawingManager` no longer
// builds and `coordinates_polygon_group` drew nothing. The controller draws on google.maps.Polygon
// itself and keeps what the field stores: `{ shells: [[{ lat, lng }…]…], holes: […] }`.
describe('drawing-maps', () => {
  const FIELD = '[data-drawing-maps-target="polygonField"]'
  const SHELL = [{ lat: 32.53, lng: -117.04 }, { lat: 32.53, lng: -117 }, { lat: 32.51, lng: -117 }, { lat: 32.51, lng: -117.04 }]
  const HOLE = [{ lat: 32.525, lng: -117.03 }, { lat: 32.525, lng: -117.01 }, { lat: 32.515, lng: -117.02 }]
  const square = (south, west, north, east) => [{ lat: north, lng: west }, { lat: north, lng: east }, { lat: south, lng: east }, { lat: south, lng: west }]

  const mount = (value = { shells: [], holes: [] }, attributes = '') => {
    cy.visit('/bali/empty_state/default')
    cy.get('body').then(([body]) => body.insertAdjacentHTML('beforeend', `
      <div data-controller="drawing-maps" data-drawing-maps-key="" ${attributes}>
        <button type="button" data-action="drawing-maps#clearHoles">Clear holes</button>
        <button type="button" data-action="drawing-maps#clear">Clear</button>
        <div data-drawing-maps-target="map" class="h-96"></div>
        <input type="hidden" value='${JSON.stringify(value)}' data-drawing-maps-target="polygonField">
      </div>`))
    cy.window().should((win) => expect(win.__fakeMaps?.registry.maps, 'map built').to.have.length(1))
  }

  const fakeMaps = (callback) => cy.window().then((win) => callback(win.__fakeMaps))

  // A click per vertex, then one on the first vertex to close the shape.
  const draw = (vertices) => fakeMaps((maps) => {
    vertices.forEach((vertex) => maps.click(vertex))
    maps.clickVertex(0)
  })

  const expectStored = (expected) =>
    cy.get(FIELD).should(($field) => expect(JSON.parse($field.val())).to.deep.eq(expected))

  beforeEach(() => {
    cy.viewport(1280, 900)
    stubGoogleMaps()
  })

  it('draws a shell: a click per vertex, and a click on the first one closes it', () => {
    mount()

    draw(SHELL)

    expectStored({ shells: [SHELL], holes: [] })
  })

  // `coordinates_polygon_group` renders a field with no value as `[]`, the format before shells.
  it('stores no empty shell for a field rendered as `[]`', () => {
    mount([])

    draw(SHELL)

    expectStored({ shells: [SHELL], holes: [] })
  })

  it('reads a single ring, the format before shells, as a shell', () => {
    mount(SHELL)

    fakeMaps(({ registry }) => expect(registry.polygons.map((polygon) => polygon.getPath().getLength())).to.deep.eq([4]))
  })

  // Inside a shell the clicks land on the shell, not on the map.
  it('draws a hole inside a shell, and paints it as one', () => {
    mount({ shells: [SHELL], holes: [] })

    draw(HOLE)

    expectStored({ shells: [SHELL], holes: [HOLE] })
    fakeMaps(({ registry }) => expect(registry.polygons[1].options.fillColor).to.eq('red'))
  })

  it('alternates shell and hole with each shape drawn inside the last', () => {
    const LAKE = square(32.514, -117.032, 32.526, -117.008)
    const ISLAND = square(32.517, -117.026, 32.523, -117.014)
    const POND = square(32.519, -117.022, 32.521, -117.018)
    mount()

    draw(SHELL)
    expectStored({ shells: [SHELL], holes: [] })
    draw(LAKE)
    expectStored({ shells: [SHELL], holes: [LAKE] })
    draw(ISLAND)
    expectStored({ shells: [SHELL, ISLAND], holes: [LAKE] })
    draw(POND)
    expectStored({ shells: [SHELL, ISLAND], holes: [LAKE, POND] })

    fakeMaps(({ registry }) => {
      expect(registry.polygons.map((polygon) => polygon.options.fillColor)).to.deep.eq(['#eaeaea', 'red', '#eaeaea', 'red'])
    })
  })

  it('draws a hole where two shells overlap', () => {
    const NEIGHBOUR = square(32.5, -117.02, 32.52, -116.98)
    const OVERLAP = square(32.512, -117.015, 32.518, -117.005)
    mount({ shells: [SHELL, NEIGHBOUR], holes: [] })

    draw(OVERLAP)

    expectStored({ shells: [SHELL, NEIGHBOUR], holes: [OVERLAP] })
  })

  // Assigned as a property after the polygon is built, the colour never reaches the map (3.66).
  it('paints a stored hole as one', () => {
    mount({ shells: [SHELL], holes: [HOLE] })

    fakeMaps(({ registry }) => {
      expect(registry.polygons.map((polygon) => polygon.options.fillColor)).to.deep.eq(['#eaeaea', 'red'])
    })
  })

  it('closes nothing on the first vertex before there are three', () => {
    mount()

    draw(SHELL.slice(0, 2))

    expectStored({ shells: [], holes: [] })
    fakeMaps(({ registry }) => expect(registry.polylines.map((line) => line.getPath().getLength())).to.deep.eq([2]))
  })

  // Google inserts a vertex where that handle is dragged to, not where it is clicked.
  it('adds no vertex on a click on the handle halfway along a segment, and one on the line', () => {
    mount()
    fakeMaps((maps) => SHELL.slice(0, 2).forEach((vertex) => maps.click(vertex)))

    const vertices = (label, expected) => fakeMaps(({ registry }) => {
      expect(registry.polylines.map((line) => line.getPath().getLength()), label).to.deep.eq(expected)
    })

    fakeMaps((maps) => maps.clickMidpoint(0))
    vertices('after the handle', [2])

    fakeMaps((maps) => maps.clickLine({ lat: 32.53, lng: -117.03 }))
    vertices('after the line', [3])
  })

  it('stores a vertex dragged on a polygon', () => {
    mount({ shells: [SHELL], holes: [] })

    cy.window().then((win) => {
      win.__fakeMaps.registry.polygons[0].getPath().setAt(0, new win.google.maps.LatLng(32.54, -117.05))
    })

    expectStored({ shells: [[{ lat: 32.54, lng: -117.05 }, ...SHELL.slice(1)]], holes: [] })
  })

  it('clears the holes, and then everything', () => {
    mount({ shells: [SHELL], holes: [HOLE] })
    cy.on('window:confirm', () => true)

    cy.contains('button', 'Clear holes').click()
    expectStored({ shells: [SHELL], holes: [] })
    fakeMaps(({ registry }) => expect(registry.polygons.map((polygon) => polygon.map === null)).to.deep.eq([false, true]))

    cy.contains('button', /^Clear$/).click()
    expectStored({ shells: [], holes: [] })
  })

  it('drops a shape half drawn on «Clear»', () => {
    mount()
    cy.on('window:confirm', () => true)
    fakeMaps((maps) => SHELL.slice(0, 2).forEach((vertex) => maps.click(vertex)))

    cy.contains('button', /^Clear$/).click()

    fakeMaps(({ registry }) => expect(registry.polylines.map((line) => line.map)).to.deep.eq([null]))
  })

  it('carries a shape half drawn onto the map a theme switch builds', () => {
    mount()
    fakeMaps((maps) => SHELL.slice(0, 2).forEach((vertex) => maps.click(vertex)))

    cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'afal-dark'))
    cy.window().should((win) => expect(win.__fakeMaps.registry.maps, 'map rebuilt').to.have.length(2))

    fakeMaps(({ registry }) => expect(registry.polylines[0].map, 'line on the new map').to.eq(registry.maps[1]))
    draw(SHELL.slice(2))

    expectStored({ shells: [SHELL], holes: [] })
    fakeMaps(({ registry }) => expect(registry.polygons[0].map).to.eq(registry.maps[1]))
  })

  it('draws nothing when it is not editable', () => {
    mount({ shells: [SHELL], holes: [] }, 'data-drawing-maps-editable-value="false"')

    draw([{ lat: 32.6, lng: -117.1 }, ...HOLE])

    fakeMaps(({ registry }) => expect(registry.polylines).to.have.length(0))
    expectStored({ shells: [SHELL], holes: [] })
  })
})
