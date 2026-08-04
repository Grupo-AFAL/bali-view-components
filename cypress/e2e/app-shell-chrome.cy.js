// `app_layout/with_navbar` es la config de referencia del app shell: sidebar fijo + navbar.
// Lo que se cuida aca es que siga siendo UNA franja de chrome y que no repita destinos.
// A 1440 hay sidebar; abajo de 1024 el layout es el movil, y ahi lo unico que importa es
// que la hamburguesa siga existiendo.
describe('AppLayout with_navbar: la franja de chrome', () => {
  const anchoEscritorio = () => {
    cy.viewport(1440, 900)
    cy.visit('/bali/app_layout/with_navbar')
    cy.get('.navbar').should('be.visible')
  }

  it('no repite en el navbar los destinos que ya lleva el sidebar', () => {
    anchoEscritorio()

    const enElSidebar = ['Dashboard', 'Movies', 'Studios']
    cy.get('.side-menu-component a').then($sidebar => {
      const nombres = [...$sidebar].map(a => a.textContent.trim())
      enElSidebar.forEach(n => expect(nombres, `${n} vive en el sidebar`).to.include(n))
    })

    cy.get('.navbar a').then($nav => {
      const nombres = [...$nav].map(a => a.textContent.trim())
      enElSidebar.forEach(n =>
        expect(nombres, `${n} no se repite en el navbar`).to.not.include(n)
      )
    })
  })

  it('pone el command palette a la izquierda y con relleno, no con borde', () => {
    anchoEscritorio()

    cy.get('[data-controller="command"] .bali-command-trigger').should($t => {
      const caja = $t[0].getBoundingClientRect()
      const cuenta = $t[0].ownerDocument
        .querySelector('.navbar [aria-label="Notifications"]')
        .getBoundingClientRect()

      expect(caja.left, 'a la izquierda de los controles de cuenta').to.be.lessThan(cuenta.left)
      // El trigger default es un pozo, no un .btn: relleno pintado y CERO borde
      // propio — con un borde, el outline de focus-visible que queda al cerrar
      // la paleta con Escape se leía como un borde doble.
      expect($t[0].className, 'pozo, no boton').to.not.match(/\bbtn\b/)
      const estilo = window.getComputedStyle($t[0])
      expect(estilo.borderTopWidth, 'sin borde propio').to.eq('0px')
      expect(estilo.backgroundColor, 'y el relleno se pinta').to.not.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })
  })

  it('al cerrar la paleta con Escape el foco vuelve al trigger con UN solo anillo', () => {
    anchoEscritorio()

    cy.get('.bali-command-trigger').click()
    cy.get('[data-command-target="input"]').should('be.focused').type('{esc}')

    // El escenario que motivó el pozo: Escape devuelve el foco al trigger, y ahí
    // el anillo de focus-visible tiene que ser el ÚNICO anillo (borde propio 0px).
    cy.get('.bali-command-trigger').should($t => {
      expect($t[0].ownerDocument.activeElement, 'el foco volvió al trigger').to.eq($t[0])
      const estilo = window.getComputedStyle($t[0])
      expect(estilo.borderTopWidth, 'sin borde propio').to.eq('0px')
      expect(parseFloat(estilo.outlineWidth), 'con el anillo del design system').to.be.greaterThan(0)
      expect(estilo.outlineStyle).to.not.eq('none')
    })
  })

  it('deja los breadcrumbs sobre el fondo de la pagina, fuera de un Topbar', () => {
    anchoEscritorio()

    cy.get('.bali-topbar').should('not.exist')
    cy.get('.breadcrumbs').should($bc => {
      const fondo = window.getComputedStyle($bc[0].parentElement).backgroundColor
      expect(fondo, 'sin fondo propio').to.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })

    // Arriba del titulo y dentro del cuerpo, no en una franja aparte.
    cy.get('main .breadcrumbs').should('exist')
    cy.get('.breadcrumbs').then($bc => {
      cy.get('.page-header-component .title').then($t => {
        expect($bc[0].getBoundingClientRect().bottom).to.be.at.most(
          $t[0].getBoundingClientRect().top
        )
      })
    })
  })

  // Soltar el slot `with_topbar` es lo que vuelve a encender la fila movil por defecto de
  // AppLayout (`fixed_sidebar? && !topbar?`). Sin ella el sidebar no se abre en un telefono.
  it('conserva el disparador del sidebar en movil', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/app_layout/with_navbar')

    cy.get('.app-layout-topbar--default-mobile').should('exist')
    cy.get('.app-layout-topbar--default-mobile [data-controller~="side-menu-trigger"]').should(
      'be.visible'
    )
  })
})
