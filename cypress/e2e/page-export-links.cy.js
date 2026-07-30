// El ⋯ de acciones secundarias vive en el PageHeader, FUERA del nodo que el turbo_stream de
// un submit de filtros reemplaza. Que el href quede al día después de filtrar es
// invisible para Minitest: el HTML servido siempre trae el estado correcto.
describe('Page export links', () => {
  const exportLink = '[data-export-links-target="link"]'
  const secondaryActions = '[aria-label="More actions"]'

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
    // `connect()` ya la ve. Sin esto el link se queda con el slice de la carga inicial.
    cy.visit('/bali/index_page/complete')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      expect($link.attr('href')).to.not.include('group_by')
    })

    cy.window().then((win) => {
      win.history.pushState({}, '', '?group_by=genre&page=3')
      win.dispatchEvent(new win.Event('turbo:load'))
    })

    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('group_by=genre')
      expect(href).to.include('format=csv')
      expect(href).to.not.include('page=')
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
