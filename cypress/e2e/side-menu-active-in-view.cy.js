// Un menú más alto que el sidebar hace scroll en su propio contenedor
// (`.sidebar-menu`, `overflow: auto`), no en la ventana. Turbo Drive reemplaza el
// `<body>` en cada visita, así que ese div se reconstruye y nace en `scrollTop: 0`:
// al navegar a una sección de abajo, el item de la página en la que estás quedaba
// fuera de vista. Turbo no ayuda — sólo restaura el scroll del documento.
describe('SideMenu: el item activo entra en vista', () => {
  const contenedor = () => cy.get('.side-menu-component .sidebar-menu')

  // El enlace de la página actual, en su versión visible: cada item renderiza
  // también una copia para el rail colapsado, oculta con `display: none`.
  const itemActivo = () => cy.get('.sidebar-menu a[aria-current="page"]:visible')

  const dentroDelContenedor = ($menu, $item) => {
    const menu = $menu[0].getBoundingClientRect()
    const item = $item[0].getBoundingClientRect()

    expect(item.top, 'el item no queda por encima del corte').to.be.at.least(menu.top - 1)
    expect(item.bottom, 'el item no queda por debajo del corte').to.be.at.most(menu.bottom + 1)
  }

  it('lo desplaza a la vista cuando nace debajo del corte', () => {
    cy.viewport(1440, 900)
    cy.visit('/bali/side_menu/active_item_in_view')

    // La preview existe para esto: sin scroll no hay nada que probar.
    contenedor().should($m => {
      expect($m[0].scrollHeight, 'el menú desborda su contenedor').to.be.greaterThan(
        $m[0].clientHeight
      )
    })

    contenedor().should($m => expect($m[0].scrollTop).to.be.greaterThan(0))

    contenedor().then($menu => itemActivo().then($item => dentroDelContenedor($menu, $item)))
  })

  it('no arrastra el scroll del documento al hacerlo', () => {
    // La ventana es más corta que la página, así que el documento SÍ puede
    // desplazarse: `scrollIntoView` movería los ancestros junto con el sidebar.
    cy.viewport(1440, 300)
    cy.visit('/bali/side_menu/active_item_in_view')

    contenedor().should($m => expect($m[0].scrollTop).to.be.greaterThan(0))
    cy.window().its('scrollY').should('equal', 0)
  })

  it('deja el scroll quieto si el item activo ya se veía', () => {
    cy.viewport(1440, 900)
    // `/dashboard` es el primer item del menú: se ve con el contenedor arriba del todo.
    cy.visit('/bali/side_menu/active_item_in_view?path=/dashboard')

    contenedor().should($m => expect($m[0].scrollTop).to.equal(0))
  })
})
