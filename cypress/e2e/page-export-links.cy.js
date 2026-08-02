// El ⋯ de acciones secundarias vive en el PageHeader, FUERA del nodo que el turbo_stream de
// un submit de filtros reemplaza. Que el href quede al día después de filtrar es
// invisible para Minitest: el HTML servido siempre trae el estado correcto.
describe('Page export links', () => {
  const exportLink = '[data-export-links-target="link"]'
  const secondaryActions = '[aria-label="More actions"]'
  // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the
  // origin is derived from it rather than written out. A literal
  // `http://localhost:3001` ignores CYPRESS_BASE_URL and quietly tests another
  // checkout's server whenever the suite runs from a git worktree.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  it('carries the active slice from the server render', () => {
    cy.visit('/bali/index_page/complete?group_by=genre&q%5Bname_cont%5D=a&page=2')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('format=csv')
      expect(href).to.include('group_by=genre')
      expect(href).to.include('name_cont')
      // Exportar la página 2 sola nunca es lo que "exportar" quiere decir.
      expect(href).to.not.include('page=')
    })
  })

  it('re-syncs the href from the URL, so filtering does not freeze it', () => {
    // `filters#_submit` empuja la URL nueva al history ANTES de enviar el form, así que
    // cuando llega el evento la URL ya describe el recorte nuevo. Se despacha sobre
    // `documentElement` y burbujeando porque es lo que hace Turbo: el controlador escucha
    // en `document`, y un dispatch sobre `window` no llega ahí — su ruta de propagación es
    // solo [window].
    cy.visit('/bali/index_page/complete')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      expect($link.attr('href')).to.not.include('group_by')
    })

    cy.window().then((win) => {
      win.history.pushState({}, '', '?group_by=genre&page=3')
      win.document.documentElement.dispatchEvent(new win.Event('turbo:load', { bubbles: true }))
    })

    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('group_by=genre')
      expect(href).to.include('format=csv')
      expect(href).to.not.include('page=')
    })
  })

  it('follows a real filter submit that answers with a turbo_stream', () => {
    // EL caso para el que existe el controlador, y el único que el evento sintético de
    // arriba no prueba: la respuesta es un turbo_stream que reemplaza solo el listado, así
    // que no hay visita, `turbo:load` NO se dispara y el ⋯ tampoco se reconecta. Va contra
    // la app dummy porque los previews de Lookbook no tienen controller que responda
    // `turbo_stream`.
    cy.visit(`${appOrigin}/admin/movies`)

    cy.get('[data-filters-target="searchInput"]').type('Alien')
    cy.get('[data-action*="filters#submitSearch"]').click()

    cy.location('search').should('include', 'name_or_genre_or_studio_name_cont')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('format=csv')
      expect(href).to.include('name_or_genre_or_studio_name_cont')
    })
  })

  it('opts the download out of Turbo Drive', () => {
    // Un CSV no es una respuesta que Turbo Drive pueda renderizar: la visita se queda a
    // mitad de camino en vez de disparar la descarga.
    cy.visit('/bali/index_page/complete')

    cy.get(secondaryActions).click()
    cy.get(exportLink).each(($link) => {
      expect($link.attr('data-turbo')).to.equal('false')
    })
  })
})
