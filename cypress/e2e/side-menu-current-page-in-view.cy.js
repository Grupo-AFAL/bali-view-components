// El menú hace scroll dentro de `.sidebar-menu`, no dentro de la ventana. Turbo Drive
// reemplaza el `<body>` en cada visita, así que ese div se reconstruye y nace en
// `scrollTop: 0`: el item de la página en la que estás quedaba fuera de vista. El porqué
// completo vive en el docblock de `revealCurrentPage` en side_menu/index.js.
describe('SideMenu: la página actual entra en vista', () => {
  const RUTA = '/bali/side_menu/current_page_in_view'

  const contenedor = () => cy.get('.side-menu-component .sidebar-menu')

  // El enlace de la página actual, en su versión visible: cada item renderiza también
  // una copia para el rail colapsado, oculta con `display: none`.
  const enlaceActual = () => cy.get('.sidebar-menu a[aria-current="page"]:visible')

  const dentroDelContenedor = ($menu, $item) => {
    const menu = $menu[0].getBoundingClientRect()
    const item = $item[0].getBoundingClientRect()

    expect(item.top, 'no queda por encima del corte').to.be.at.least(menu.top - 1)
    expect(item.bottom, 'no queda por debajo del corte').to.be.at.most(menu.bottom + 1)
  }

  const desborda = $m =>
    expect($m[0].scrollHeight, 'el menú desborda su contenedor').to.be.greaterThan(
      $m[0].clientHeight
    )

  it('la desplaza a la vista cuando nace debajo del corte', () => {
    cy.viewport(1440, 900)
    cy.visit(RUTA)

    contenedor().should(desborda)
    contenedor().should($m => expect($m[0].scrollTop).to.be.greaterThan(0))
    contenedor().then($menu => enlaceActual().then($item => dentroDelContenedor($menu, $item)))
  })

  it('no arrastra el scroll del documento al hacerlo', () => {
    // La ventana es más corta que la página, así que el documento SÍ puede desplazarse:
    // `scrollIntoView` movería los ancestros junto con el sidebar.
    cy.viewport(1440, 300)
    cy.visit(RUTA)

    contenedor().should($m => expect($m[0].scrollTop).to.be.greaterThan(0))
    cy.window().its('scrollY').should('equal', 0)
  })

  it('no mueve nada cuando la página actual ya se veía', () => {
    cy.viewport(1440, 900)
    // `/dashboard` es el primer item: se ve con el contenedor arriba del todo.
    cy.visit(`${RUTA}?path=/dashboard`)

    contenedor().should(desborda)
    contenedor().should($m => expect($m[0].scrollTop).to.equal(0))
  })

  // En el rail colapsado los hijos de un grupo viven en un panel `display: none`, así que
  // el enlace con `aria-current` no es visible: lo único visible que dice "estás aquí" es
  // el disparador del grupo. El modo `:dropdown` tiene exactamente la misma forma — su
  // panel también está cerrado — y se arregla por el mismo camino.
  //
  // Entra YA colapsado, con la preferencia en localStorage, y no colapsando a mano: el
  // scroll que deja el rail expandido al encogerse sobrevive al toggle, y un test que
  // colapsa a mano pasa con ese resto sin haber revelado nada. Es además el caso real —
  // `restoreCollapseState()` existe porque el usuario vuelve a un sidebar colapsado.
  it('en el rail colapsado revela el disparador del grupo que contiene la página', () => {
    cy.viewport(1440, 900)
    cy.visit(`${RUTA}?path=/ledger/balances&collapsible=true`, {
      onBeforeLoad: win => win.localStorage.setItem('bali_sideMenuCollapsed', 'true')
    })

    cy.get('.side-menu-component').should('have.class', 'is-collapsed')
    contenedor().should(desborda)

    // Cypress considera invisible lo que su contenedor con overflow recorta, así que
    // `be.visible` es literalmente "entró en vista"; la geometría lo confirma.
    const disparador = () => cy.get('.side-menu-collapsed-flyout .menu-item')

    disparador().should('be.visible')
    contenedor().then($menu => disparador().then($t => dentroDelContenedor($menu, $t)))
  })
})
