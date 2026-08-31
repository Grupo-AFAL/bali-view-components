// #1084 — la busqueda remota de un slim_select manda ademas del termino: un scope fijo
// (`ajax_extra_params`) y uno tomado de otro campo del formulario (`ajax_param_selectors`).
//
// Se afirma sobre la REQUEST interceptada y no sobre la lista de opciones: lo que este
// cambio agrega es lo que viaja en el query, y una lista que coincide puede coincidir por
// casualidad. El recorte del preview lo hace el endpoint del dummy con `family`, asi que
// la lista se mira despues como confirmacion de que el parametro llego a destino.
//
// El controller no busca con menos de dos caracteres (`ajaxPlaceholder` es lo que se ve
// hasta entonces), asi que todos los terminos de aca abajo tienen al menos dos.
const search = term => {
  cy.get('.ss-main').click()
  cy.get('.ss-content .ss-search input').clear().type(term)
}

describe('SlimSelect ajax dependiente de otro campo', () => {
  beforeEach(() => {
    cy.intercept('GET', '/users.json*').as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote_dependent')
  })

  it('manda los parametros fijos y omite el dependiente mientras no haya nada elegido', () => {
    search('jo')

    cy.wait('@remoteSearch').then(({ request }) => {
      expect(request.query.q, 'el termino').to.equal('jo')
      expect(request.query.source, 'el parametro fijo').to.equal('bali')
      expect(request.query, 'sin campo elegido no hay recorte').to.not.have.property('family')
    })
  })

  it('agrega el parametro del campo del que depende y acota la busqueda', () => {
    cy.get('#user-family').select('Smith')
    search('jo')

    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Smith')

    // `.ss-optgroup` y no `.ss-list` entera: SlimSelect deja la opcion SELECCIONADA arriba
    // de todo, fuera del grupo, asi que la lista completa incluye la que traia el widget.
    // Los resultados de la busqueda son los del grupo, el que el controller rotula con
    // `resultsText`. Y `should` con callback y no `each`, que no reintenta.
    cy.get('.ss-content .ss-list .ss-optgroup .ss-option').should($options => {
      expect($options.length, 'resultados').to.be.greaterThan(0)
      $options.each((_i, option) => expect(option.textContent.trim()).to.match(/Smith$/))
    })
  })

  // El campo se lee EN CADA BUSQUEDA, no al conectar: cambiarlo despues es todo el caso
  // de uso, y leerlo una sola vez es exactamente como fallaria en silencio.
  it('vuelve a leer el campo cuando cambia entre dos busquedas', () => {
    cy.get('#user-family').select('Smith')
    search('jo')
    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Smith')

    cy.get('#user-family').select('Doe')
    search('joh')
    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Doe')
  })

  it('vuelve a omitir el parametro cuando el campo se vacia', () => {
    cy.get('#user-family').select('Smith')
    search('jo')
    cy.wait('@remoteSearch')

    cy.get('#user-family').select('')
    search('joh')

    cy.wait('@remoteSearch').then(({ request }) => {
      expect(request.query).to.not.have.property('family')
      expect(request.query.source).to.equal('bali')
    })
  })
})
