// `app_layout/with_topbar` es la config de referencia del app shell: sidebar fijo como LA
// navegacion + Bali::Topbar como barra de cuenta sobre la columna de contenido. Lo que se
// cuida aca es que siga siendo UNA franja de chrome, que no repita destinos, y que en movil
// el sidebar se siga abriendo desde la hamburguesa del propio Topbar.
describe('AppLayout with_topbar: la franja de chrome', () => {
  const anchoEscritorio = () => {
    cy.viewport(1440, 900)
    cy.visit('/bali/app_layout/with_topbar')
    cy.get('.bali-topbar').should('be.visible')
  }

  it('no repite en el topbar los destinos que ya lleva el sidebar', () => {
    anchoEscritorio()

    const enElSidebar = ['Dashboard', 'Movies', 'Studios']
    cy.get('.side-menu-component a').then($sidebar => {
      const nombres = [...$sidebar].map(a => a.textContent.trim())
      enElSidebar.forEach(n => expect(nombres, `${n} vive en el sidebar`).to.include(n))
    })

    cy.get('.bali-topbar a').then($top => {
      const nombres = [...$top].map(a => a.textContent.trim())
      enElSidebar.forEach(n =>
        expect(nombres, `${n} no se repite en el topbar`).to.not.include(n)
      )
    })
  })

  it('es un header/banner con UN solo nav en la pagina: el del sidebar', () => {
    anchoEscritorio()

    // Topbar y no Navbar a proposito: con el sidebar cargando los destinos, la franja
    // superior es chrome (banner), no un segundo landmark de navegacion vacio.
    cy.get('header.bali-topbar').should('exist')
    cy.get('.bali-topbar nav').should('not.exist')
    cy.get('nav.side-menu-component').should('exist')
  })

  it('pone el command palette a la izquierda y con relleno, no con borde', () => {
    anchoEscritorio()

    cy.get('[data-controller="command"] .bali-command-trigger').should($t => {
      const caja = $t[0].getBoundingClientRect()
      const cuenta = $t[0].ownerDocument
        .querySelector('.bali-topbar [aria-label="Notifications"]')
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

  it('deja los breadcrumbs sobre el fondo de la pagina, fuera del Topbar', () => {
    anchoEscritorio()

    cy.get('.bali-topbar .breadcrumbs').should('not.exist')
    cy.get('.breadcrumbs').should($bc => {
      const fondo = window.getComputedStyle($bc[0].parentElement).backgroundColor
      expect(fondo, 'sin fondo propio').to.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })

    // Arriba del titulo y dentro del cuerpo, no en la franja de chrome.
    cy.get('main .breadcrumbs').should('exist')
    cy.get('.breadcrumbs').then($bc => {
      cy.get('.page-header-component .title').then($t => {
        expect($bc[0].getBoundingClientRect().bottom).to.be.at.most(
          $t[0].getBoundingClientRect().top
        )
      })
    })
  })

  // Con un Topbar real en el slot, la fila movil por defecto de AppLayout
  // (`fixed_sidebar? && !topbar?`) NO se renderiza: la hamburguesa que abre el
  // sidebar en un telefono es la del propio Topbar (lg:hidden).
  it('conserva el disparador del sidebar en movil, dentro del Topbar', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/app_layout/with_topbar')

    cy.get('.app-layout-topbar--default-mobile').should('not.exist')
    cy.get('.bali-topbar [data-controller~="side-menu-trigger"]').should('be.visible')
  })
})
