// Los comentarios del BlockEditor se rompian por el alcance de dos selectores, no por una
// interaccion, asi que esto maneja la cascada en vez de la interaccion: monta el markup que
// BlockNote emite dentro del contenedor real y lee lo que pintan las hojas que se embarcan.
// Es el mismo enfoque que document-editor.cy.js usa para el tooltip, y por la misma razon —
// el composer flotante solo lo monta un click real sobre una seleccion real, y nada de lo
// que se prueba aca depende de como aparecio la tarjeta.
//
// Lo que reproduce, medido sobre /lookbook/preview/bali/block_editor/with_comments antes
// del arreglo:
//   - el `.bn-container` anidado de cada comentario media 163px y su `.bn-editor` 0px,
//     porque `.bn-with-comments .bn-container > .bn-editor` lo alcanzaba con
//     `flex: 1; min-width: 0`. Una letra por renglon.
//   - la tarjeta flotante no tenia ancho propio: 165px con tres letras, 966px con una
//     linea larga. `.bn-floating-composer` / `.bn-floating-thread`, los selectores que la
//     hoja usaba para acotarla, no existen en el DOM (0 elementos).

const LARGO =
  'este es otro comentario con un texto que se expande conforme voy escribiendo y ' +
  'quiero ver hasta donde me limita asdfkjasldkfj alksdjflajsdlkfjasldkfj alksdjflkajsdf'

const comentario = texto => `
  <div data-floating-ui-portal>
    <div tabindex="-1" data-floating-ui-focusable style="position:absolute;top:0;left:0">
      <div class="bn-thread mantine-Card-root mantine-Paper-root">
        <div class="bn-root bn-container bn-mantine bn-comment-editor">
          <div class="tiptap ProseMirror bn-editor bn-default-styles">
            <p class="bn-inline-content">${texto}</p>
          </div>
        </div>
      </div>
    </div>
  </div>`

describe('BlockEditor: comentarios', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')

    cy.get('.bn-with-comments > .bn-container').then($container => {
      const doc = $container[0].ownerDocument
      const host = doc.createElement('div')
      host.dataset.test = 'sondas'
      host.innerHTML = comentario('est') + comentario(LARGO)
      $container[0].appendChild(host)
    })
  })

  const tarjetas = () => cy.get('[data-test="sondas"] .bn-thread')

  it('deja al editor anidado con el ancho de su tarjeta, no en cero', () => {
    cy.get('[data-test="sondas"] .bn-comment-editor').each($anidado => {
      const estilo = window.getComputedStyle($anidado[0])
      const editor = $anidado[0].querySelector('.bn-editor')

      // La regla de dos columnas es del contenedor de primer nivel y de nadie mas.
      expect(estilo.display, 'el contenedor anidado no es una fila flex').to.not.equal('flex')
      expect(editor.getBoundingClientRect().width, 'el editor mide algo').to.be.greaterThan(100)
    })
  })

  // No hay un tercer caso que mida los renglones del parrafo. Se escribio y pasaba igual
  // con la hoja vieja: en esta sonda el contenedor flotante es `position: absolute` sin
  // ancho, o sea shrink-to-fit sobre max-content, y ahi el texto entra en una linea aunque
  // el `.bn-editor` mida cero. La letra por renglon necesita el ancho que Floating UI le
  // escribe a la caja real. Los dos casos de arriba SI fallan sin el arreglo — verificado
  // revirtiendo index.css y reconstruyendo — y son los que describen la causa.

  it('la burbuja flotante mide lo mismo con tres letras que con un parrafo', () => {
    tarjetas().should('have.length', 2)
    tarjetas().then($t => {
      const anchos = [...$t].map(el => Math.round(el.getBoundingClientRect().width))

      expect(anchos[0], 'corta y larga miden igual').to.equal(anchos[1])
      expect(anchos[0], 'y ese ancho es el declarado').to.equal(320)
    })
  })
})

// El preview se llama `with_comments` y no traia ninguno (#863). No era cosmetico: es lo
// que hizo invisible a #832 — para reproducir el desborde del hilo hubo que crear un
// comentario a mano por la UI, y el barrido de previews contaba la pagina como 200.
//
// Un comentario vive en DOS lados y necesita los dos para ser uno de verdad: el hilo en el
// store, y la marca `comment` sobre el texto al que ancla. Sembrar solo el store deja los
// hilos en la barra pero rotulados "Original content deleted" — medido.
describe('BlockEditor: el preview de comentarios abre con comentarios', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    // La barra lateral se puebla desde el store cuando el editor monta.
    cy.get('.bn-threads-sidebar .bn-thread', { timeout: 20000 }).should('have.length', 2)
  })

  it('los hilos estan anclados al texto, no huerfanos', () => {
    // La marca es la mitad que el JSON de bloques no puede llevar: viaja en la forma
    // ProseMirror de `initial_content`. Sin ella la barra pinta hilos que no apuntan a nada.
    cy.get('.bn-editor .bn-thread-mark').should('have.length', 2)
    cy.get('.bn-threads-sidebar').should('not.contain.text', 'Original content deleted')
  })

  it('mantiene el ancho de la barra con una URL larga sin cortes', () => {
    // El caso de #832, ahora ejercitado por el preview en vez de a mano: un hilo cuyo
    // comentario lleva una URL que no tiene donde partirse. Se mide el desborde real del
    // contenedor, no las clases.
    cy.get('.bn-threads-sidebar').should($sidebar => {
      const el = $sidebar[0]
      expect(el.scrollWidth, 'la barra no desborda horizontalmente').to.equal(el.clientWidth)
    })
  })
})
