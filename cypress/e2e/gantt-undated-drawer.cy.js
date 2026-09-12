// Gantt (#1015): los items sin fechas no desaparecen. No pueden tener barra ni
// fila, asi que viven en un drawer server-rendered (Data#undated_items) que el
// pie de la isla delata y abre: "10 items · 2 with no dates". El preview
// `default` trae dos sin fechas (Docs, Announcement).
//
// Se mide con `:modal` (el DrawerController abre con showModal()), no con
// clases ni textContent suelto (memoria del repo). Y se cierra al final: un
// <dialog> en top layer que nadie cierra deja la pagina entera inerte (#854).

describe('Gantt undated drawer', () => {
  beforeEach(() => {
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow', { timeout: 10000 }).should('exist')
  })

  it('el drawer server-rendered sobrevive el swap y vive junto al mount', () => {
    // Junto al mount, no adentro: React retira los hijos del mount en su
    // primer commit y un drawer adentro se esfumaria con el esqueleto.
    cy.get('.bali-gantt > dialog.drawer-component').should('exist')
    cy.get('.bali-gantt-mount dialog').should('not.exist')
    cy.get('dialog.drawer-component:modal').should('not.exist')

    // Nombrado para la isla, y NO compartido: un trigger broadcast de la
    // pagina no debe abrirlo.
    cy.get('.bali-gantt').then(($gantt) => {
      const drawerId = $gantt.attr('data-gantt-undated-drawer-id-value')
      expect(drawerId, 'undated drawer id value').to.match(/.+/)
      cy.get(`dialog#${drawerId}`).should('have.attr', 'data-drawer-shared-value', 'false')
    })
  })

  it('el pie delata los sin-fechas y el link abre el drawer con la lista', () => {
    cy.contains('button', 'with no dates').should('be.visible').click()

    cy.get('dialog.drawer-component:modal').should('exist')
    cy.get('dialog.drawer-component').within(() => {
      cy.contains('li', 'Docs').should('be.visible')
      cy.contains('li', 'Announcement').should('be.visible')
      // La forma exacta del reporte: sin fechas Y sin grupo — no tiene fila
      // ni barra en ningún lado; el drawer es el único lugar donde existe.
      cy.contains('li', 'Postmortem review').should('be.visible')
      // Solo los sin fechas: ninguna fila del tablero se cuela.
      cy.contains('li', 'Component API').should('not.exist')
    })

    // Consulta, no decision: se cierra y la pagina sigue viva.
    cy.get('dialog.drawer-component button[aria-label="Close drawer"]').click()
    cy.get('dialog.drawer-component:modal').should('not.exist')
    cy.contains('button', 'with no dates').click()
    cy.get('dialog.drawer-component:modal').should('exist')
    cy.get('dialog.drawer-component button[aria-label="Close drawer"]').click()
    cy.get('dialog.drawer-component:modal').should('not.exist')
  })
})
