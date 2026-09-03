// El panel de hilos era de solo lectura por CSS y por nada más: tres reglas
// `display: none !important` escondían la caja de responder, el botón de reacción y la
// barra de acciones en TODOS los sidebars, mientras noventa líneas más abajo el mismo
// archivo le daba a `.bn-thread-composer` un margen, un borde superior y un `min-height`
// —o sea, lo estilizaba como si se viera— y los docs prometían responder y reaccionar
// desde ahí. Medido: el composer existía en el DOM con rect 0×0.
//
// Lo que lo volvía defecto y no preferencia: un hilo cuyo ancla se borró
// («Contenido original eliminado») no tiene popover que abrir, así que con el panel
// inerte no quedaba NINGUNA vía para responderle (#1111).
//
// Maneja la cascada y no la interacción, igual que block-editor-comments.cy.js: monta el
// markup que BlockNote emite dentro del sidebar real y lee lo que pintan las hojas que se
// embarcan. Mantine sólo monta esos controles con un hover o un click de verdad sobre un
// hilo, y nada de lo que se prueba acá depende de cómo apareció la tarjeta.

const hilo = `
  <div class="bn-thread mantine-Card-root mantine-Paper-root">
    <div class="bn-thread-comments">
      <div class="bn-thread-comment">
        <p>Este párrafo está de más</p>
        <div class="bn-comment-actions-wrapper">
          <div class="bn-action-toolbar"><button type="button">Resolver</button></div>
        </div>
        <button type="button" class="bn-comment-add-reaction">+</button>
      </div>
    </div>
    <div class="bn-thread-composer">
      <div class="bn-root bn-container bn-mantine bn-comment-editor">
        <div class="tiptap ProseMirror bn-editor bn-default-styles">
          <p class="bn-inline-content">Responder…</p>
        </div>
      </div>
      <div class="bn-action-toolbar"><button type="button">Guardar</button></div>
    </div>
  </div>`

const CONTROLES = [
  ['.bn-thread-composer', 'la caja de responder'],
  ['.bn-comment-add-reaction', 'el botón de reacción'],
  ['.bn-thread-composer .bn-action-toolbar', 'la barra de acciones del composer'],
  ['.bn-comment-actions-wrapper', 'el menú de acciones del comentario']
]

const montarHilo = (raiz = '.bn-threads-sidebar') =>
  cy.get(raiz).first().then($sidebar => {
    const host = $sidebar[0].ownerDocument.createElement('div')
    host.dataset.test = 'sonda-hilo'
    host.innerHTML = hilo
    $sidebar[0].appendChild(host)
  })

const sonda = selector => cy.get(`[data-test="sonda-hilo"] ${selector}`)

// El markup de arriba es sintético a propósito —Mantine sólo monta esos controles con
// un hover o un click de verdad— pero eso deja el arreglo colgando de un supuesto que
// nada verifica: que BlockNote SIGA emitiendo estas clases. Si un bump de versión
// renombra `.bn-thread-composer`, la sonda sigue verde y el defecto vuelve entero y en
// silencio. Esto no prueba comportamiento; falla el día que la clase deje de existir,
// que es lo que hacía falta.
//
// Va aparte y sobre el DOM sin tocar: el hilo sintético cuelga de un `.bn-threads-sidebar`
// real, y BlockNote rastrea el mouse sobre el documento entero —`findClosestEditorElement`
// sube por el nodo bajo el cursor— así que un click con ese markup montado revienta en
// su propio manejador.
describe('BlockEditor: las clases de BlockNote de las que cuelga el modo', () => {
  const CLASES = ['.bn-thread-composer', '.bn-comment-editor', '.bn-comment-actions-wrapper']

  CLASES.forEach(clase => {
    it(`BlockNote sigue emitiendo ${clase} en el DOM real`, () => {
      cy.viewport(1280, 900)
      cy.visit('/bali/block_editor/with_comments')
      cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
      cy.get('.bn-threads-sidebar .bn-thread').first().click()

      cy.get(`.bn-threads-sidebar ${clase}`).should('exist')
    })
  })
})

describe('BlockEditor: panel de hilos interactivo (por omisión)', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    montarHilo()
  })

  it('no marca el sidebar como de solo lectura', () => {
    cy.get('.block-editor-component').should('not.have.attr', 'data-comments-sidebar')
  })

  CONTROLES.forEach(([selector, nombre]) => {
    it(`deja ver ${nombre}`, () => {
      sonda(selector).then($control => {
        const estilo = window.getComputedStyle($control[0])
        const caja = $control[0].getBoundingClientRect()

        expect(estilo.display, `${nombre} no está oculto`).to.not.equal('none')
        expect(caja.height, `${nombre} ocupa alto`).to.be.greaterThan(0)
        expect(caja.width, `${nombre} ocupa ancho`).to.be.greaterThan(0)
      })
    })
  })
})

describe('BlockEditor: panel de hilos con `sidebar: :read_only`', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_read_only_comments_sidebar')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    montarHilo()
  })

  it('marca el sidebar como de solo lectura', () => {
    cy.get('.block-editor-component').should('have.attr', 'data-comments-sidebar', 'read-only')
  })

  CONTROLES.forEach(([selector, nombre]) => {
    it(`esconde ${nombre}`, () => {
      sonda(selector).then($control => {
        expect(window.getComputedStyle($control[0]).display, `${nombre} está oculto`)
          .to.equal('none')
      })
    })
  })

  // Lo que el modo NO se lleva: el hilo se sigue leyendo entero.
  it('sigue mostrando el hilo', () => {
    sonda('.bn-thread-comment').should('be.visible')
  })
})

// El modo terminaba en la raíz del editor: la bandera que lee el CSS estaba en
// `.block-editor-component`, y `comments_container_id:` —opción pública y
// documentada— saca el sidebar de ahí. `sidebar: :read_only` pintaba entonces un panel
// enteramente interactivo, sin error y sin aviso: se pedía una cosa y pasaba la
// contraria (#1113). La bandera viaja ahora con el portal, puesta por el wrapper de
// React sobre el contenedor del anfitrión, porque Rails no pinta lo que hay adentro.
describe('BlockEditor: panel de hilos portaleado con `sidebar: :read_only`', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_portaled_read_only_comments_sidebar')
    cy.get('.bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    cy.get('#panel-de-hilos .bn-threads-sidebar').should('exist')
    montarHilo('#panel-de-hilos .bn-threads-sidebar')
  })

  it('marca el contenedor del anfitrión, que Rails no pinta por dentro', () => {
    cy.get('#panel-de-hilos').should('have.attr', 'data-comments-sidebar', 'read-only')
  })

  // El contenedor no es `.block-editor-component` ni `.document-editor-panel`, que es
  // justo lo que el selector anterior exigía.
  CONTROLES.forEach(([selector, nombre]) => {
    it(`esconde ${nombre}`, () => {
      sonda(selector).then($control => {
        expect(window.getComputedStyle($control[0]).display, `${nombre} está oculto`)
          .to.equal('none')
      })
    })
  })
})

// La otra mitad del modo: el panel deja de ser donde se escribe, y el ancla sigue
// siéndolo. Un hilo sin popover que abrir es lo que volvía defecto al panel inerte.
// Aparte, y sin el hilo sintético montado, por la misma razón que el canario.
describe('BlockEditor: el ancla sigue siendo donde se escribe', () => {
  it('abre un composer con alto real en el popover', () => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_portaled_read_only_comments_sidebar')
    cy.get('.bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    cy.get('#panel-de-hilos .bn-thread').first().click()

    cy.get('[data-floating-ui-portal] .bn-thread-composer').should($composer => {
      expect(window.getComputedStyle($composer[0]).display).to.not.equal('none')
      expect($composer[0].getBoundingClientRect().height).to.be.greaterThan(0)
    })
  })
})
