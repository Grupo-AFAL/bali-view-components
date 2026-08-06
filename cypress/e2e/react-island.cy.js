// Infraestructura react-island (#703): monta el contador de juguete del dummy
// a traves del circuito COMPLETO que usa un host real — startIslandLoader en el
// bundle principal lee las metas de react_island_meta_tags, inyecta la entry
// island-demo.js, registerIsland registra sobre window.Stimulus con guard, y la
// subclase de ReactIslandController monta React con values→props.
//
// Se mide visibilidad y numero de instancias de controller, no textContent
// suelto (memoria del repo): un doble registro deja UNA isla visible porque el
// segundo mount pisa al primero — solo el conteo de instancias lo delata.

const instancias = (win) =>
  win.Stimulus.controllers.filter((c) => c.identifier === 'react-island-demo')

describe('ReactIsland', () => {
  it('monta la isla via el loader lazy y mapea values a props', () => {
    cy.visit('/bali/react_island/default')

    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.get('[data-testid="count"]').should('have.text', '3')

    cy.get('[data-testid="increment"]').click()
    cy.get('[data-testid="count"]').should('have.text', '4')
  })

  it('monta dos islas independientes, cada una con sus props', () => {
    cy.visit('/bali/react_island/two_islands')

    cy.get('[data-testid="counter-island"]').should('have.length', 2).and('be.visible')
    cy.get('[data-testid="count"]').eq(0).should('have.text', '10')
    cy.get('[data-testid="count"]').eq(1).should('have.text', '20')

    // Incrementar una no toca a la otra: roots de React separados.
    cy.get('[data-testid="increment"]').eq(0).click()
    cy.get('[data-testid="count"]').eq(0).should('have.text', '11')
    cy.get('[data-testid="count"]').eq(1).should('have.text', '20')
  })

  it('mantiene UNA instancia de controller por isla tras navegar con Turbo', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))

    cy.get('[data-testid="goto-two-islands"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 2).and('be.visible')
    // Los controllers de la pagina anterior se desconectaron; si la entry se
    // registrara dos veces habria 4 instancias aqui.
    cy.window().should((win) => expect(instancias(win)).to.have.length(2))

    cy.get('[data-testid="goto-default"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 1).and('be.visible')
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))
  })

  it('desmonta al navegar y remonta fresco al volver (sin cache de Turbo)', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="increment"]').click()
    cy.get('[data-testid="count"]').should('have.text', '4')

    cy.get('[data-testid="goto-two-islands"]').click()
    cy.get('[data-testid="counter-island"]').should('have.length', 2)

    cy.get('[data-testid="goto-default"]').click()
    // Mount nuevo desde los values del servidor: si React sobreviviera al
    // cache de Turbo (o el root no se desmontara) aqui habria un 4 o un editor
    // roto, no el valor inicial.
    cy.get('[data-testid="counter-island"]').should('be.visible')
    cy.get('[data-testid="count"]').should('have.text', '3')
  })

  it('pinta el fallback y reporta por onError cuando loadComponent falla', () => {
    cy.visit('/bali/react_island/load_error')

    cy.get('.text-error').should('be.visible')
    cy.get('[data-testid="counter-island"]').should('not.exist')

    cy.window().should((win) => {
      const errores = win.__baliIslandErrors || []
      expect(errores.some((e) => e.phase === 'load' && e.identifier === 'react-island-demo')).to.equal(true)
    })
  })

  // El caso que se perdía: con las metas presentes y el import() fallando
  // (digest rotado tras un deploy, red caída, CSP), `replaceChildren` borraba el
  // contenido server-rendered del mount. Para Bali::Gantt `mode: :interactive`
  // eso significa perder el tablero navegable y quedarse con un <p>.
  it('un fallo de carga NO destruye el contenido server-rendered del mount', () => {
    cy.visit('/bali/react_island/load_error')

    cy.get('#isla-con-fallback [data-testid="fallback-server"]')
      .should('be.visible')
      .and('contain.text', 'esto es el fallback de la isla')
    // Sigue siendo usable, no una captura de pantalla: el link es alcanzable.
    cy.get('#isla-con-fallback [data-testid="fallback-server"] a')
      .should('have.attr', 'href')
      .and('include', '/lookbook')

    // Y el aviso se pone ENCIMA, para que se lea antes que el contenido.
    cy.get('#isla-con-fallback').children().first().should('have.class', 'text-error')

    // El mount vacío se comporta como antes: el aviso es todo lo que hay.
    cy.get('[data-controller="react-island-demo"]').first().children()
      .should('have.length', 1)
      .and('have.class', 'text-error')
  })

  it('el ErrorBoundary atrapa errores de render y reporta por onError', () => {
    cy.visit('/bali/react_island/default')
    cy.get('[data-testid="counter-island"]').should('be.visible')

    cy.get('[data-testid="explode"]').click()

    cy.get('[data-testid="counter-island"]').should('not.exist')
    cy.get('.text-error').should('be.visible')

    cy.window().should((win) => {
      const errores = win.__baliIslandErrors || []
      expect(errores.some((e) => e.phase === 'render' && e.identifier === 'react-island-demo')).to.equal(true)
    })
  })
})
