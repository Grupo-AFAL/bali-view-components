// Dos contratos básicos del editor que se rompen en silencio, cada uno por su lado.
//
// 1. Enter parte el bloque. Suena a que no hace falta probarlo, y por eso estuvo roto:
//    basta que el bundle cargue DOS copias de `prosemirror-model` para que
//    `Transaction.split` tire `RangeError: Can not convert <> to a Fragment`, porque
//    `Fragment.from` valida con un `instanceof` contra su propia copia. El editor
//    monta, pinta y deja escribir; lo único que no hace es bajar de línea. Ninguna
//    suite de Ruby puede ver eso, y el duplicado lo mete el lockfile, no el código:
//    entra solo cuando alguien sube `@blocknote/*` y yarn agrega una entrada nueva en
//    vez de re-resolver la vieja. Ver `resolutions` en spec/dummy/package.json.
//
// 2. El heading que abre el documento no lleva aire arriba. BlockNote le pone 18px a
//    TODOS los headings; en el primer bloque no hay nada de qué separarse y el campo
//    arranca con el texto hundido, que se lee como un input desalineado.
//
// El editor es React montado por Stimulus: hay que esperar el contenido, no el
// contenedor, o se mide el div vacío que mandó el servidor.
const editor = () => cy.get('.bn-editor.bn-default-styles')
const bloques = () => cy.get('.bn-block-content')

const abrir = ruta => {
  cy.visit(ruta)
  editor().should('exist')
  bloques().should('have.length.at.least', 1)
}

const escribir = texto => editor().type(texto, { delay: 0 })

describe('BlockEditor: edición básica', () => {
  it('Enter parte el bloque en vez de seguir en la misma línea', () => {
    abrir('bali/block_editor/default')

    escribir('Primera linea{enter}Segunda linea{enter}Tercera linea')

    bloques().should('have.length', 3)
    bloques().eq(0).should('contain.text', 'Primera linea')
    bloques().eq(1).should('contain.text', 'Segunda linea')
    bloques().eq(2).should('contain.text', 'Tercera linea')

    // Y la línea de abajo no se quedó pegada a la de arriba, que es como se ve el
    // fallo desde afuera cuando `split` explota.
    bloques().eq(0).should('not.contain.text', 'Segunda linea')
  })

  // El `RangeError` no rompe el render, así que sin esto pasa desapercibido.
  it('no tira excepciones de prosemirror al partir un bloque', () => {
    cy.visit('bali/block_editor/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
      }
    })
    editor().should('exist')

    escribir('Uno{enter}Dos')

    cy.get('@consoleError').should(spy => {
      const mensajes = spy.getCalls().map(c => String(c.args[0]))
      const prosemirror = mensajes.filter(m => /prosemirror|Fragment/i.test(m))
      expect(prosemirror, `console.error: ${prosemirror.join(' | ')}`).to.have.length(0)
    })
  })
})

describe('BlockEditor: el heading que abre el documento', () => {
  const headings = () => cy.get('.bn-block-content[data-content-type="heading"]')

  it('no lleva padding arriba, y los demás sí', () => {
    abrir('bali/block_editor/with_initial_content')

    headings().should('have.length.at.least', 2)

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'el primero').to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'el segundo').to.eq(18)
    })
  })

  it('también cuando el heading se escribe a mano en un editor vacío', () => {
    abrir('bali/block_editor/default')

    escribir('# Titulo{enter}Un parrafo.{enter}## Otro heading')

    headings().should('have.length', 2)

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'el que abre').to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'el que sigue a un parrafo').to.eq(18)
    })
  })

  // El aire de los demás headings sale del tamaño del cuerpo, no de los 18px fijos de
  // BlockNote ni del `em` del propio heading (que en un h1 daría 54px).
  it('escala ese aire con `size:`', () => {
    abrir('bali/block_editor/with_initial_content?size=xs')

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop)).to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop)).to.eq(13.5)
    })
  })
})
