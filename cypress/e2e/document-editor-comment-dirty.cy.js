// Responder un comentario marcaba el documento como «Cambios sin guardar», y en un visor
// de solo lectura ese aviso ya no se limpiaba nunca.
//
// El listener de `input` cuelga del CONTENEDOR del área del editor —BlockNote construye su
// ProseMirror del lado del cliente, así que al conectar no hay otra cosa a la que colgarse—
// y el composer flotante de BlockNote vive DENTRO de ese contenedor. Su `input` burbujeaba,
// `contentChanged` llamaba a `scheduleSave` y `_dirty` quedaba en true. Con
// `auto_save: false` no hay guardado que lo limpie: el aviso se queda para siempre sobre un
// documento que quien lee no puede haber cambiado ni puede guardar (#1111).
//
// La preview `default` es exactamente el caso reportado: `auto_save: false` y comentarios
// encendidos. `?editable=false` la vuelve el visor.
//
// Monta el markup que BlockNote emite para el composer y dispara el `input` real que
// burbujea: el composer flotante sólo lo abre un click sobre un ancla real, y lo que se
// prueba acá es de dónde vino el evento, no cómo apareció la tarjeta.

const composerFlotante = `
  <div data-floating-ui-portal>
    <div tabindex="-1" data-floating-ui-focusable style="position:absolute;top:0;left:0">
      <div class="bn-thread mantine-Card-root mantine-Paper-root">
        <div class="bn-thread-composer">
          <div class="bn-root bn-container bn-mantine bn-comment-editor">
            <div class="tiptap ProseMirror bn-editor bn-default-styles" contenteditable="true">
              <p class="bn-inline-content" data-test="respuesta">Sí, de acuerdo</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>`

const areaEditor = () => cy.get('[data-document-editor-target="editorArea"]:visible')
// Sin `:visible`: el `<span>` del estado arranca vacío, y un inline vacío mide 0×0, así que
// Cypress lo daría por invisible justo en el estado que esta prueba necesita leer.
const estado = () => cy.get('[data-document-editor-target="saveStatus"]')

// El constructor sale de la ventana del AUT, no de la del runner: el nodo vive en el
// iframe de la app y un evento construido afuera no es del mismo reino.
const dispararInput = nodo => {
  const win = nodo.ownerDocument.defaultView
  nodo.dispatchEvent(new win.Event('input', { bubbles: true, composed: true }))
}

const teclearEn = selector => cy.get(selector).then($nodo => dispararInput($nodo[0]))

const montarComposer = () =>
  areaEditor().then($area => {
    const host = $area[0].ownerDocument.createElement('div')
    host.dataset.test = 'sonda-composer'
    host.innerHTML = composerFlotante
    $area[0].appendChild(host)
  })

const visitar = query => {
  cy.viewport(1280, 900)
  cy.visit(`/bali/document_editor/default${query}`)
  areaEditor().find('.bn-editor').should('contain.text', 'Project Overview')
  estado().should('have.text', '')
  montarComposer()
}

describe('DocumentEditor: visor de solo lectura', () => {
  beforeEach(() => visitar('?editable=false'))

  it('no marca cambios sin guardar al teclear una respuesta', () => {
    teclearEn('[data-test="respuesta"]')

    estado().should('have.text', '')
  })

  // El editor no es editable, así que no hay ningún `input` legítimo que pueda venir del
  // documento: el aviso no puede aparecer por ninguna vía.
  it('no ofrece un botón de guardar que pudiera limpiarlo', () => {
    cy.get('[data-document-editor-target="saveButton"]').should('not.exist')
  })
})

describe('DocumentEditor: editor con auto_save apagado', () => {
  beforeEach(() => visitar(''))

  it('no marca cambios sin guardar al teclear una respuesta', () => {
    teclearEn('[data-test="respuesta"]')

    estado().should('have.text', '')
  })

  // La otra mitad del contrato: el arreglo filtra por origen del evento, no apaga el aviso.
  // Un `input` del ProseMirror del documento tiene que seguir marcándolo.
  it('sí lo marca cuando el input viene del documento', () => {
    areaEditor().find('.bn-editor').first().then($editor => dispararInput($editor[0]))

    estado().should('not.have.text', '')
  })
})
