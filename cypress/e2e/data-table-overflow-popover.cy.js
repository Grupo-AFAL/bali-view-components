// El ⋯ es un popover: abrir uno de sus hijos no puede cambiarle el tamano. Lo hacia porque
// el contenedor del menu forzaba `position: static` en todo `.dropdown-content` de adentro,
// una decision tomada cuando el ⋯ ERA el modo de movil. Desde #842 la valvula salta a
// cualquier ancho, asi que esa regla se aplicaba tambien en escritorio: medido en
// /admin/studios a 1900px, el panel del ⋯ pasaba de 320x176 a 320x338 al abrir Views.
//
// Sobre por que la pagina es /admin/studios y no un preview, ver
// data-table-toolbar-alignment.cy.js.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const estudios = () => cy.visit(`${appOrigin}/admin/studios`)

const disparadorPuntos = () => cy.get('[data-toolbar-overflow-target="overflow"] .btn').first()
const primerHijo = () =>
  cy.get('[data-toolbar-overflow-target="menu"] .dropdown').first().find('.btn').first()
const contenidoDelHijo = () =>
  cy.get('[data-toolbar-overflow-target="menu"] .dropdown .dropdown-content').first()

const caja = el => {
  const b = el.getBoundingClientRect()
  return { w: Math.round(b.width), h: Math.round(b.height) }
}

describe('DataTable: el popover del ⋯', () => {
  it('no cambia de tamano cuando se abre uno de sus hijos', () => {
    cy.viewport(1900, 1000)
    estudios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    disparadorPuntos().click()
    cy.get('[data-toolbar-overflow-target="menu"]').should('be.visible')

    cy.get('[data-toolbar-overflow-target="menu"]').then($menu => {
      const panel = $menu[0].closest('.dropdown-content')
      const antes = caja(panel)

      primerHijo().click()
      contenidoDelHijo()
        .should('be.visible')
        .then($sub => {
          expect(window.getComputedStyle($sub[0]).position, 'el hijo flota').to.equal('absolute')
          expect(caja(panel), 'y el contenedor no se movio').to.deep.equal(antes)
        })
    })
  })

  // #1080: flotar no alcanza, hay que flotar POR ENCIMA de la banda de contenido. El panel
  // del ⋯ tiene su propio contexto de apilamiento (absolute + z-index), asi que un hijo
  // absoluto de adentro se pinta arriba de la tabla — salvo que un ancestro con
  // `overflow` lo RECORTE, que es lo que hacia el `overflow-y-auto` del contenedor del
  // menu. Recortado, del panel asomaba un borde y `elementFromPoint` en su centro devolvia
  // un `<td>`: el control quedaba inservible justo en los anchos donde el ⋯ es la unica
  // salida. Se mide con hit-testing y no con clases porque el sintoma es de pintado.
  it('deja el panel del hijo clicable por encima de la tabla', () => {
    cy.viewport(1440, 900)
    estudios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    disparadorPuntos().click()
    primerHijo().click()

    contenidoDelHijo()
      .should('be.visible')
      .then($sub => {
        const panel = $sub[0]
        const b = panel.getBoundingClientRect()
        const puntos = [
          ['arriba', b.top + 4],
          ['al medio', b.top + b.height / 2],
          ['abajo', b.bottom - 4]
        ]

        puntos.forEach(([donde, y]) => {
          const encima = panel.ownerDocument.elementFromPoint(b.left + b.width / 2, y)
          expect(panel.contains(encima), `${donde} el panel recibe el click`).to.equal(true)
        })
      })
  })

  // En un telefono apilar en flujo sigue siendo lo razonable, y es la razon por la que la
  // regla existe: anidados y absolutos se posicionan contra el contenedor y se salen del
  // viewport (medido: left -115px en 375px).
  it('deja los hijos apilados en flujo en un telefono, sin salirse', () => {
    cy.viewport(375, 800)
    estudios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    disparadorPuntos().click()
    primerHijo().click()

    contenidoDelHijo().should($sub => {
      expect(window.getComputedStyle($sub[0]).position).to.equal('static')

      const b = $sub[0].getBoundingClientRect()
      expect(b.left, 'no se sale por la izquierda').to.be.at.least(0)
      expect(b.right, 'ni por la derecha').to.be.at.most(375)
    })
  })
})
