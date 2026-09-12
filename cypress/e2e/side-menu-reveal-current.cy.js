// #1099 — Cada navegación re-renderiza el sidebar y su scroll vuelve arriba. En un menú
// más alto que la pantalla eso deja el ítem activo fuera de vista: llegás a una página y
// el menú no te muestra dónde estás.
//
// El preview recorta el menú a 380 px con 18 entradas y la página actual
// (`/reports/audit-log`) casi al final, que es la única forma de ver el comportamiento:
// en un menú que entra en pantalla no hay nada que revelar.
const PREVIEW = '/bali/side_menu/reveal_current'
const MENU = '.sidebar-menu'
const CURRENT = '.side-menu-expanded[aria-current="page"]'

describe('SideMenu reveal current item', () => {
  it('opens already scrolled to the item for the current page', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
    cy.get(CURRENT).should('be.visible')
  })

  // Visible de verdad y no solo "en el DOM": el ítem tiene que caer DENTRO de la caja del
  // menú, que es lo que fallaba. `should('be.visible')` de Cypress no lo distingue.
  it('leaves the current item inside the menu box', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).then(($menu) => {
      const menuRect = $menu[0].getBoundingClientRect()

      cy.get(CURRENT).then(($item) => {
        const itemRect = $item[0].getBoundingClientRect()

        expect(itemRect.top).to.be.at.least(menuRect.top)
        expect(itemRect.bottom).to.be.at.most(menuRect.bottom)
      })
    })
  })

  it('does nothing when the option is off', () => {
    cy.visit(`${PREVIEW}?reveal_current=false`)

    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })

  // Solo mueve el scroll del propio menú. `scrollIntoView` habría movido también los
  // ancestros que hiciera falta, hasta el documento.
  it('never scrolls the page', () => {
    cy.visit(PREVIEW)

    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
    cy.window().its('scrollY').should('equal', 0)
  })

  // La guarda de visibilidad: sin ella el menú saltaría en cada carga de una página cuyo
  // ítem ya se ve.
  it('stays put when the current item is already in view', () => {
    cy.visit('/bali/side_menu/default')

    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })
})

// El otro caso que el issue dejaba abierto: un drawer móvil cerrado está `inert` y
// trasladado fuera de pantalla, así que medirlo en `connect` gastaría el scroll en un panel
// que nadie está viendo. El reveal espera a `open()`.
describe('SideMenu reveal current item — mobile drawer', () => {
  const FIXED = `${PREVIEW}?fixed=true`

  beforeEach(() => cy.viewport(390, 700))

  it('does not spend the reveal while the drawer is closed', () => {
    cy.visit(FIXED)

    cy.get('.side-menu-component').should('have.attr', 'inert')
    cy.get(MENU).should('have.prop', 'scrollTop', 0)
  })

  it('reveals the current item when the drawer opens', () => {
    cy.visit(FIXED)

    cy.get('[data-controller~="side-menu-trigger"]').first().click()

    cy.get('.side-menu-component').should('have.class', 'is-active')
    cy.get(MENU).should('have.prop', 'scrollTop').and('be.greaterThan', 0)
  })
})
