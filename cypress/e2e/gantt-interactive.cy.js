// Gantt fase 3 (#719): `mode: :interactive` renderiza el fallback DENTRO del
// elemento de montaje de la isla y el GanttController lo reemplaza al montar.
// Lo que estos specs miden es el SWAP, que es la apuesta de D16: el fallback
// tiene que estar antes, la isla despues, y la geometria tiene que ser la misma
// a ambos lados (misma TimeScale, mismos px/dia) para que el cambio no se lea
// como un parpadeo.
//
// Se mide presencia/visibilidad de nodos, nunca textContent suelto (memoria del
// repo).
//
// NO se retrasa el bundle para "ver el antes": un <script> inyectado antes del
// load retrasa el propio evento load, asi que `cy.visit` espera el retraso
// entero y devuelve el control con la isla YA montada — la ventana que se
// queria observar no existe desde fuera. Se mide el ORDEN desde dentro de la
// pagina (observarSwap) y se comprueba el estado sin isla bloqueando el bundle.

// Deja a la isla sin bundle: lo que quede en pantalla es el fallback
// definitivo, que es lo que ve un visitante sin JavaScript.
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

// Anota, DESDE la pagina, si el tablero server-rendered estaba presente al
// inicio y si seguia estandolo cuando React inserto su lienzo.
const observarSwap = (win) => {
  const swap = { fallbackAlInicio: null, fallbackCuandoMontaLaIsla: null }
  win.__swap = swap

  const hayFallback = () => !!win.document.querySelector('[data-controller="gantt"] .bali-gantt-canvas')
  const hayEsqueleto = () => !!win.document.querySelector('[data-controller="gantt"] .bali-gantt-skeleton')

  win.document.addEventListener('DOMContentLoaded', () => {
    swap.fallbackAlInicio = hayFallback() || hayEsqueleto()
  })

  const observer = new win.MutationObserver(() => {
    if (!win.document.querySelector('.react-flow')) return
    if (swap.fallbackCuandoMontaLaIsla === null) {
      swap.fallbackCuandoMontaLaIsla = hayFallback() || hayEsqueleto()
      observer.disconnect()
    }
  })
  observer.observe(win.document.documentElement, { childList: true, subtree: true })
}

const anchoDe = (el) => Math.round(el.getBoundingClientRect().width)

describe('Gantt mode: :interactive', () => {
  it('pinta el tablero estatico dentro del mount y la isla lo reemplaza', () => {
    cy.visit('/bali/gantt/interactive_readonly', { onBeforeLoad: observarSwap })

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')

    cy.window().should((win) => {
      // El servidor mando el tablero dentro del propio elemento de montaje...
      expect(win.__swap.fallbackAlInicio, 'fallback presente al inicio').to.equal(true)
      // ...y ya no estaba cuando React inserto su lienzo: lo reemplazo, no se
      // apilo debajo.
      expect(win.__swap.fallbackCuandoMontaLaIsla, 'fallback al montar').to.equal(false)
    })

    // La isla vive donde vivia el fallback.
    cy.get('[data-controller="gantt"] .react-flow').should('exist')
    cy.get('.bali-gantt-canvas').should('not.exist')
    cy.get('.bali-gantt-row').should('not.exist')
  })

  // La promesa concreta de la fase: las barras no se mueven ni se reescalan al
  // montar, porque Bali::Gantt::TimeScale y timeScale.js comparten densidades y
  // el componente le pasa a la isla el zoom que su fallback ya resolvio.
  //
  // El fallback ya no esta en el DOM cuando se puede medir la isla, asi que se
  // vuelve a pedir el MISMO HTML al servidor y se mide en la misma pagina: el
  // ancho de una barra sale de un `style="width:Npx"` inline, independiente del
  // contenedor, y la isla dibuja en el mismo viewport.
  it('la barra del fallback y el nodo de la isla miden lo mismo', () => {
    cy.visit('/bali/gantt/interactive_readonly')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    cy.window().then((win) =>
      win.fetch(win.location.href, { cache: 'no-store' })
        .then((r) => r.text())
        .then((html) => {
          const fallback = new win.DOMParser()
            .parseFromString(html, 'text/html')
            .querySelector('[data-controller="gantt"]')
          fallback.removeAttribute('data-controller') // que no monte una segunda isla
          const caja = win.document.createElement('div')
          caja.id = 'medicion-fallback'
          caja.style.cssText = 'position:absolute;top:0;left:0;width:1400px;visibility:hidden'
          caja.appendChild(fallback)
          win.document.body.appendChild(caja)
        })
    )

    cy.get('#medicion-fallback .bali-gantt-bar[title^="Component API"]').then(($barra) => {
      const anchoFallback = anchoDe($barra[0])
      expect(anchoFallback).to.be.greaterThan(0)
      cy.contains('.react-flow__node', 'Component API').should(($nodo) => {
        expect(anchoDe($nodo[0])).to.equal(anchoFallback)
      })
    })
  })

  // Sin este handoff la isla abriria en su default ("week") mientras el fallback
  // resolvio `:auto` contra la ventana (aqui, "day"): el swap reescalaria el
  // tablero entero delante del visitante.
  it('la isla abre en el zoom que resolvio el fallback', () => {
    cy.visit('/bali/gantt/interactive_readonly')

    cy.get('[data-controller="gantt"]')
      .should('have.attr', 'data-gantt-initial-zoom-value', 'day')
      .and('have.attr', 'data-gantt-zoom', 'day')

    cy.get('[role="group"][aria-label="Zoom"] .btn-active').should('have.text', 'Day')
  })

  it('fallback: :skeleton pinta un placeholder neutro en vez del tablero', () => {
    sinIsla()
    cy.visit('/bali/gantt/interactive_skeleton')

    cy.get('[data-controller="gantt"] .bali-gantt-skeleton')
      .should('be.visible')
      .and('have.attr', 'aria-busy', 'true')
      .and('have.attr', 'role', 'status')
    cy.get('.bali-gantt-skeleton .skeleton').should('have.length.greaterThan', 0)
    // Neutro de verdad: ni una barra ni una fila del cronograma real.
    cy.get('.bali-gantt-canvas').should('not.exist')
    cy.get('.bali-gantt-bar').should('not.exist')
  })

  it('la isla reemplaza tambien al esqueleto', () => {
    cy.visit('/bali/gantt/interactive_skeleton', { onBeforeLoad: observarSwap })

    cy.get('.react-flow').should('be.visible')
    cy.get('.bali-gantt-skeleton').should('not.exist')
    cy.window().should((win) => {
      expect(win.__swap.fallbackAlInicio, 'esqueleto presente al inicio').to.equal(true)
      expect(win.__swap.fallbackCuandoMontaLaIsla, 'esqueleto al montar').to.equal(false)
    })
  })

  // El caso que justifica que el default sea `:static`: si el bundle nunca
  // llega (red caida, JS desactivado, navegador viejo), lo que queda no es un
  // hueco sino el cronograma, navegable con teclado.
  it('si la isla nunca carga, el fallback queda usable y accesible', () => {
    sinIsla()
    cy.visit('/bali/gantt/interactive_readonly')

    cy.get('.bali-gantt-canvas')
      .should('be.visible')
      .and('have.attr', 'role', 'region')
      .and('have.attr', 'aria-label')
    // tabindex=0: el lienzo con scroll es alcanzable y se desplaza con teclado.
    cy.get('.bali-gantt-canvas').focus().should('have.focus')
    cy.get('details.bali-gantt-group').should('have.length.greaterThan', 0)
    cy.get('.bali-gantt-bar').should('have.length.greaterThan', 0).and('be.visible')

    // Los links de zoom del static son GET planos: funcionan sin JavaScript.
    cy.get('[role="group"][aria-label="Zoom"] a')
      .should('have.length', 3)
      .first()
      .should('have.attr', 'href')
      .and('include', 'gantt_zoom=')

    cy.get('.react-flow').should('not.exist')
  })

  // El preview grande del gate D16: 300 items con semilla fija.
  it('monta con 300 items sobre el fallback estatico', () => {
    cy.visit('/bali/gantt/interactive_stress', { onBeforeLoad: observarSwap })

    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-initial-zoom-value', 'week')
    cy.get('.react-flow', { timeout: 30000 }).should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.get('.bali-gantt-canvas').should('not.exist')
    cy.window().should((win) => {
      expect(win.__swap.fallbackAlInicio, 'fallback de 300 items presente al inicio').to.equal(true)
    })
  })
})
