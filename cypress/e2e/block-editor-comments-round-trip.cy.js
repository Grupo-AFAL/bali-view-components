// #706 — el unico test que prueba que un comentario SOBREVIVE.
//
// Los previews de Lookbook usan el InMemoryThreadStore: no hay servidor detras, asi que
// pueden pasar enteros con el engine roto. Este va contra la pagina del dummy que si
// consume el engine (`/documents/:id`, `comments: { url: :auto, commentable: @document }`)
// y hace el viaje completo: escribir un comentario por la UI de BlockNote, ver el 201 del
// engine, recargar la pagina y encontrarlo otra vez — que solo puede venir de la base.
//
// Un solo `it` a proposito: el estado que se prueba es justo lo que sobrevive entre las
// dos mitades, y Cypress limpia los alias entre tests.
//
// El origen sale del baseUrl configurado y no de un literal, porque cada worktree corre su
// dummy en un puerto distinto.
const origin = new URL(Cypress.config('baseUrl')).origin

const TEXTO = `comentario persistente ${Date.now()}`

const overlay = () => cy.get('#document-editor-overlay')

const abrirEditor = () => {
  cy.contains('button', 'Edit').click()
  overlay().find('.bn-editor', { timeout: 30000 }).should('be.visible')
}

describe('BlockEditor: los comentarios sobreviven a una recarga', () => {
  it('escribe un comentario, el engine lo guarda y sigue ahi tras recargar', () => {
    cy.viewport(1400, 900)
    cy.intercept('POST', '**/bali/block_editor_comments?*').as('crearHilo')
    cy.intercept('GET', '**/bali/block_editor_comments?*').as('listarHilos')

    // El id no se escribe a mano: las semillas usan find_or_initialize_by y no los fijan.
    // El filtro numerico descarta /documents/new, que es el primer enlace del listado.
    cy.visit(`${origin}/documents`)
    cy.get('a[href^="/documents/"]')
      .filter((_i, el) => /^\/documents\/\d+$/.test(el.getAttribute('href')))
      .first().invoke('attr', 'href').then(documento => {
        cy.visit(`${origin}${documento}`)
        abrirEditor()

        // Un comentario necesita texto al que anclarse: sin seleccion la barra de formato
        // no aparece y el boton de comentar no existe.
        overlay().find('.bn-editor').first().click().type('{selectall}')
        cy.get('[aria-label="Add comment"]', { timeout: 10000 }).should('be.visible').click()

        // El composer monta su propio editor BlockNote y se lleva el foco.
        cy.get('.bn-comment-editor [contenteditable="true"]', { timeout: 10000 })
          .should('be.visible')
          .type(TEXTO)

        // Acotado a `.bn-thread` a proposito: el DocumentEditor tiene su propio boton
        // "Save" en la barra superior y es el que gana sin el scope — guarda el documento
        // y descarta el comentario pendiente, sin que ninguna asercion lo note.
        cy.get('.bn-comment-editor').closest('.bn-thread').contains('button', 'Save').click()

        cy.wait('@crearHilo').its('response.statusCode').should('eq', 201)

        // La recarga es el punto: despues de ella el texto no puede venir de ningun lado
        // mas que del GET del engine, porque la marca del documento no lo lleva.
        cy.visit(`${origin}${documento}`)
        abrirEditor()
        overlay().find('.bn-threads-sidebar', { timeout: 30000 }).should('contain.text', TEXTO)

        // Y que lo sirvio el engine, no una cache del navegador. Se revisan TODAS las
        // llamadas y no la siguiente: la pagina monta dos editores y ambos hacen polling,
        // asi que `cy.wait` devolveria un GET cualquiera — incluido el vacio de antes de
        // escribir el comentario.
        cy.get('@listarHilos.all').then(llamadas => {
          const sirvieron = llamadas.some(({ response }) => JSON.stringify(response.body).includes(TEXTO))
          expect(sirvieron, 'algun GET del engine devolvio el hilo').to.equal(true)
        })
      })
  })
})
