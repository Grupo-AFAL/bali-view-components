// El view switch solo se puede probar de verdad navegando: lo que importa es qué sobrevive
// al cambio de modo, y eso vive en el query string que arma el servidor.
describe('DataTable view switch', () => {
  const viewSwitch = '.view-switch-component'
  const savedViews = '[data-controller~="saved-views"]'

  it('keeps the filters, the applied saved view and the grouping when the mode changes', () => {
    cy.visit('/bali/data_table/complete?group_by=genre&saved_view=1&q%5Bname_cont%5D=a&page=2')

    cy.get(`${viewSwitch} a[aria-pressed="true"]`).should('contain.text', 'Table')
    cy.get('table').should('exist')
    cy.get(savedViews).should('contain.text', 'Indie only')

    cy.get(viewSwitch).contains('a', 'Cards').click()

    cy.location('search').should((search) => {
      expect(search).to.include('view=grid')
      expect(search).to.include('group_by=genre')
      expect(search).to.include('saved_view=1')
      expect(search).to.include('name_cont')
      // Cambiar de vista vuelve a la primera página: `page` es lo único que se tira.
      expect(search).to.not.include('page=')
    })

    cy.get('table').should('not.exist')
    cy.get('.card-title').should('have.length.greaterThan', 0)
    cy.get(`${viewSwitch} a[aria-pressed="true"]`).should('contain.text', 'Cards')
    cy.get(savedViews).should('contain.text', 'Indie only')
  })

  it('renders the third mode, which Bali knows nothing about', () => {
    cy.visit('/bali/data_table/complete')
    cy.get(viewSwitch).contains('a', 'Timeline').click()

    cy.get('.gantt-chart-component').should('exist')
    cy.get('table').should('not.exist')
    cy.get(`${viewSwitch} a[aria-pressed="true"]`).should('contain.text', 'Timeline')
  })

  it('falls back to the first declared view when ?view= is unknown', () => {
    // El param crudo nunca llega al contenido sin pasar por las vistas declaradas: sin el
    // gateo, un `?view=` inventado dejaba el listado vacío.
    cy.visit('/bali/data_table/complete?view=kanban')

    cy.get(`${viewSwitch} a[aria-pressed="true"]`).should('contain.text', 'Table')
    cy.get('table').should('exist')
  })

  it('keeps the display mode when filters are applied from the cards view', () => {
    // El submit de filtros reconstruye la URL desde `url:`, sin query string: el modo
    // sobrevive porque viaja como hidden field, igual que la agrupación.
    cy.visit('/bali/data_table/complete?view=grid')

    cy.get('input[type="hidden"][name="view"]').should('have.value', 'grid')
  })
})
