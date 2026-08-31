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

const montarHilo = () =>
  cy.get('.bn-threads-sidebar').first().then($sidebar => {
    const host = $sidebar[0].ownerDocument.createElement('div')
    host.dataset.test = 'sonda-hilo'
    host.innerHTML = hilo
    $sidebar[0].appendChild(host)
  })

const sonda = selector => cy.get(`[data-test="sonda-hilo"] ${selector}`)

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
