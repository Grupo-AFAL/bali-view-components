// #1091 — el editor persiste en una de dos formas de JSON, y con `format: :json` cual te
// tocaba no lo decidia el host: BlockNote borra las marcas de comentario de
// `editor.document`, asi que el editor cambia solo a la forma ProseMirror para no perderlas.
// El primer usuario que dejaba un comentario reescribia la columna en el otro esquema, y con
// auto-guardado eso pasaba sin que nadie lo pidiera.
//
// Los tres editores del preview cargan EL MISMO documento —uno que ya trae marcas— y se
// diferencian solo en `format:`. Se afirma sobre el VALOR del hidden input, que es lo que el
// host termina guardando; el `data-content-format` de al lado es lo que le ahorra adivinarlo
// por la estructura.
//
// El editor del DOCUMENTO y no cualquier `.bn-editor`: con comentarios encendidos, cada
// comentario de la barra lateral monta el suyo, asi que el selector suelto devuelve cuatro.
// El de primer nivel es el hijo directo del `.bn-container` de `.bn-with-comments`, el mismo
// alcance que usa block-editor-comments.cy.js.
const editorDe = seccion =>
  cy.get(`[data-test="${seccion}"] .bn-with-comments > .bn-container > .bn-editor`)
const inputDe = seccion =>
  cy.get(`[data-test="${seccion}"] input[data-block-editor-target="output"]`)

const escribirEn = seccion => {
  editorDe(seccion).should('exist')
  editorDe(seccion).find('.bn-block-content').should('have.length.at.least', 1)
  editorDe(seccion).type('{moveToEnd} listo', { delay: 0 })
}

// Se espera al TEXTO TECLEADO y no a que el input deje de estar vacio: el servidor lo
// rendea ya con el contenido original, asi que "no vacio" es verdad antes de que el editor
// haya escrito una sola vez — y en este preview ese contenido original es ProseMirror, con
// lo que dos de los tres casos pasarian sin haber medido nada. El write esta debounceado
// 500ms.
const valorDe = seccion =>
  inputDe(seccion).should($input => expect($input.val()).to.include('listo'))
    .then($input => JSON.parse($input.val()))

describe('BlockEditor: forma del contenido persistido', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_pinned_format')
  })

  it('con :json y marcas de comentario escribe la forma ProseMirror, como siempre', () => {
    escribirEn('adaptive')

    valorDe('adaptive').should(content => {
      expect(content.type, 'la raiz').to.equal('doc')
    })
    inputDe('adaptive').should('have.attr', 'data-content-format', 'prosemirror')
  })

  it('con :blocks se queda en el Array de bloques aunque haya marcas', () => {
    escribirEn('pinned-blocks')

    valorDe('pinned-blocks').should(content => {
      expect(Array.isArray(content), 'la raiz es un Array de bloques').to.equal(true)
      expect(content.length).to.be.greaterThan(0)
      // La forma que el host lee del lado de Rails: props, no attrs.
      expect(content[0]).to.have.property('props')
    })
    inputDe('pinned-blocks').should('have.attr', 'data-content-format', 'blocks')
  })

  it('con :prosemirror escribe la forma ProseMirror aunque no hubiera hecho falta', () => {
    escribirEn('pinned-prosemirror')

    valorDe('pinned-prosemirror').should(content => {
      expect(content.type).to.equal('doc')
    })
    inputDe('pinned-prosemirror').should('have.attr', 'data-content-format', 'prosemirror')
  })

  // Perder el anclaje de un hilo es un intercambio que el host puede querer; perderlo en
  // silencio es lo que este `format:` existe para evitar.
  it('avisa por consola cuando :blocks descarta una marca de comentario', () => {
    cy.window().then(win => cy.spy(win.console, 'warn').as('warn'))

    escribirEn('pinned-blocks')
    valorDe('pinned-blocks')

    cy.get('@warn').should('have.been.calledWithMatch', /does not persist comment marks/)
  })
})
