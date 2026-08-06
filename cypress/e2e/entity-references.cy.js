// #708 — el `#` del BlockEditor contra los endpoints del engine
// (Bali::EntityReferencesController). El preview `with_entity_references` apunta a
// /bali/entity_references, así que esto ejercita la cadena completa: registry del dummy →
// búsqueda → payload → chip. Los datos vienen de los seeds (el proyecto "Bali Component
// Library"), los mismos que carga el workflow de Cypress antes de correr.
//
// Nada de intercept: el valor de la prueba está justamente en que la respuesta la arma el
// engine, no un stub.

describe('BlockEditor: referencias de entidades', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_entity_references')
    cy.get('.bn-editor').should('be.visible')
  })

  const editor = () => cy.get('.bn-editor [contenteditable="true"], .bn-editor[contenteditable="true"]').first()

  // El menú se pinta cuando vuelve el fetch, y el hook pide una vez por tecleo sin garantizar
  // cuál request es la última: en vez de adivinarla, se deja reintentar la aserción. El
  // timeout es amplio a propósito — con la máquina cargada los 4s por default no alcanzan, y
  // eso es lo único que falla acá, nunca el resultado.
  const MENU_TIMEOUT = 20000

  const search = query => {
    editor().click().type(`#${query}`)
    return cy.get('.bn-suggestion-menu', { timeout: MENU_TIMEOUT }).should('be.visible')
  }

  it('busca en el engine y agrupa por la etiqueta que declara el registry', () => {
    // El grupo es `display: { label: }` del registry: sin él el menú diría el entityType
    // crudo, y el punto de #708-2 es que la declaración del tipo lo alimenta.
    search('Bali')
      .should('contain.text', 'Bali Component Library')
      .and('contain.text', 'Project')
  })

  it('inserta el chip con el tipo y el id que el servidor resolvió', () => {
    search('Bali')
    // El timeout de `search` cubre su propia cadena; el resultado dentro del menú necesita
    // el suyo, que es lo que la espera del fetch se come.
    cy.get('.bn-suggestion-menu')
      .contains('Bali Component Library', { timeout: MENU_TIMEOUT })
      .click()

    cy.get('.bn-entity-reference', { timeout: MENU_TIMEOUT })
      .should('have.attr', 'data-entity-type', 'Project')
      .and('contain.text', 'Bali Component Library')
    cy.get('.bn-entity-reference').should('have.attr', 'data-entity-id').and('not.be.empty')
  })

  // Un caso negativo puro ("busca algo que no existe") pasaría igual con el endpoint roto.
  // Este discrimina: el término solo casa con una tarea, y el proyecto se queda fuera.
  it('solo ofrece los tipos cuyo scope casa con el término', () => {
    search('Kanban')
      .should('contain.text', 'Task')
      .and('contain.text', 'Build Kanban component')
      .and('not.contain.text', 'Bali Component Library')
  })
})
