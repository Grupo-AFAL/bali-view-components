// Gantt (#970): la isla es el UNICO renderer y el esqueleto integrado es el
// unico estado de carga. Lo que mide esta spec es el SWAP — el esqueleto tiene
// que estar dentro del mount ANTES, la isla DESPUES, y en ningun momento una
// caja vacia.
//
// Antes (#719) este archivo tambien comparaba la geometria del tablero
// server-rendered contra la de la isla. Ese tablero ya no existe: no hay dos
// renderers que puedan discrepar, asi que la unica geometria que sigue siendo
// frontera es el ZOOM con el que abre la isla, que el servidor resuelve.
//
// Se mide presencia/visibilidad de nodos, nunca textContent suelto (memoria del
// repo).
//
// NO se retrasa el bundle para "ver el antes": un <script> inyectado antes del
// load retrasa el propio evento load, asi que `cy.visit` espera el retraso
// entero y devuelve el control con la isla YA montada — la ventana que se
// queria observar no existe desde fuera. Se mide el ORDEN desde dentro de la
// pagina (observarSwap) y se comprueba el estado sin isla bloqueando el bundle.

// Deja a la isla sin bundle: lo que quede en pantalla es lo que ve un visitante
// al que el JS nunca le llega.
//
// Se le quitan las METAS a la respuesta HTML, no se bloquea el .js. Bloquear la
// peticion del bundle no funciona: el asset es digerido e inmutable, asi que en
// cuanto un test anterior lo carga el navegador lo sirve de su cache y no hay
// peticion que interceptar (se midio: la isla montaba igual y el test fallaba).
// Sin metas, startIslandLoader no sabe que inyectar — es el modo de fallo que
// documenta docs/api/gantt.md.
const sinIsla = () =>
  cy.intercept({ method: 'GET', url: /\/lookbook\/preview\/bali\/gantt\// }, (req) => {
    req.on('response', (res) => {
      res.body = String(res.body).replace(/<meta name="bali-gantt-(?:js|css)"[^>]*>/g, '')
    })
  })

// Anota, DESDE la pagina, si el esqueleto estaba dentro del mount al inicio y
// si seguia estandolo cuando React inserto su lienzo.
const observarSwap = (win) => {
  const swap = { esqueletoAlInicio: null, esqueletoCuandoMontaLaIsla: null, mountVacio: false }
  win.__swap = swap

  const hayEsqueleto = () => !!win.document.querySelector('[data-controller="gantt"] .bali-gantt-skeleton')

  win.document.addEventListener('DOMContentLoaded', () => {
    swap.esqueletoAlInicio = hayEsqueleto()
  })

  const observer = new win.MutationObserver(() => {
    const mount = win.document.querySelector('[data-controller="gantt"]')
    // La promesa del swap atomico: ni un solo estado intermedio en el que el
    // mount se haya quedado sin esqueleto Y sin lienzo.
    if (mount && !hayEsqueleto() && !win.document.querySelector('.react-flow')) {
      swap.mountVacio = true
    }
    if (!win.document.querySelector('.react-flow')) return
    if (swap.esqueletoCuandoMontaLaIsla === null) {
      swap.esqueletoCuandoMontaLaIsla = hayEsqueleto()
    }
  })
  observer.observe(win.document.documentElement, { childList: true, subtree: true })
}

describe('Gantt: el esqueleto y el swap a la isla', () => {
  it('pinta el esqueleto dentro del mount y la isla lo reemplaza sin caja vacia', () => {
    cy.visit('/bali/gantt/default', { onBeforeLoad: observarSwap })

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')

    cy.window().should((win) => {
      // El servidor mando el esqueleto dentro del propio elemento de montaje...
      expect(win.__swap.esqueletoAlInicio, 'esqueleto presente al inicio').to.equal(true)
      // ...y ya no estaba cuando React inserto su lienzo: lo reemplazo, no se
      // apilo debajo.
      expect(win.__swap.esqueletoCuandoMontaLaIsla, 'esqueleto al montar').to.equal(false)
      // Y entre uno y otro nunca hubo un mount sin nada dentro.
      expect(win.__swap.mountVacio, 'mount vacio en algun momento del swap').to.equal(false)
    })

    // La isla vive donde vivia el esqueleto.
    cy.get('[data-controller="gantt"] .react-flow').should('exist')
    cy.get('.bali-gantt-skeleton').should('not.exist')
  })

  // Sin las metas, startIslandLoader no inyecta nada y el controller NUNCA
  // llega a registrarse, asi que no hay aviso dentro del mount: lo unico que
  // queda es el esqueleto y un error en consola nombrando la meta que falta.
  // (El aviso ANTEPUESTO al contenido del mount es el otro modo de fallo — el
  // controller registrado cuyo import() revienta — y lo cubre el preview
  // load_error en react-island.cy.js.)
  //
  // Es justo el caso que hace necesario el <noscript>: el esqueleto dice
  // `aria-busy` y significa "cargando", y aqui eso seria mentira para siempre.
  it('si el bundle nunca llega, queda el esqueleto y el fallo se nombra', () => {
    sinIsla()
    cy.visit('/bali/gantt/default', {
      onBeforeLoad: (win) => cy.stub(win.console, 'error').as('consoleError')
    })

    cy.get('[data-controller="gantt"] .bali-gantt-skeleton')
      .should('be.visible')
      .and('have.attr', 'aria-busy', 'true')
      .and('have.attr', 'role', 'status')
    cy.get('.react-flow').should('not.exist')

    // El mensaje para quien no tiene JavaScript viaja en el HTML aunque este
    // navegador si lo tenga (un <noscript> no se renderiza, pero esta ahi).
    cy.get('[data-controller="gantt"] noscript').should('exist')

    cy.get('@consoleError').should('have.been.calledWithMatch', /bali-gantt-js/)
  })

  // Sin este handoff la isla abriria en su default ("week") mientras el
  // servidor resolvio `:auto` contra la ventana (aqui, "day"): montar
  // reescalaria el tablero entero delante del visitante. Es la unica geometria
  // que sigue cruzando la frontera Ruby↔JS.
  it('la isla abre en el zoom que resolvio el servidor', () => {
    cy.visit('/bali/gantt/default')

    cy.get('[data-controller="gantt"]')
      .should('have.attr', 'data-gantt-initial-zoom-value', 'day')

    cy.get('[role="group"][aria-label="Zoom"] .btn-active').should('have.text', 'Day')
  })

  it('monta con 300 items sobre el esqueleto', () => {
    cy.visit('/bali/gantt/stress', { onBeforeLoad: observarSwap })

    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-initial-zoom-value', 'week')
    cy.get('.react-flow', { timeout: 30000 }).should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.get('.bali-gantt-skeleton').should('not.exist')
    cy.window().should((win) => {
      expect(win.__swap.esqueletoAlInicio, 'esqueleto de 300 items presente al inicio').to.equal(true)
      expect(win.__swap.mountVacio, 'mount vacio en algun momento del swap').to.equal(false)
    })
  })

  // Un documento vacio es cosa de la isla, no del componente: monta igual, con
  // su toolbar, en vez de que el servidor pinte otra cosa en su lugar.
  it('un documento vacio monta la isla igual', () => {
    cy.visit('/bali/gantt/empty')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('not.exist')
    cy.get('[role="group"][aria-label="Zoom"]').should('be.visible')
    cy.get('.bali-gantt-skeleton').should('not.exist')
  })
})
