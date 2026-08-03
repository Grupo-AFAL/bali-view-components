// La toolbar que manda el servidor es, por definicion, la fila SIN colapsar: nadie la puede
// colapsar hasta que existe el controlador. Medido en /admin/studios, la pagina pinta a los
// 260ms y `connect()` no corre hasta los 1189ms —lo que tarda en ejecutarse un bundle de
// 4.8 MB—, asi que durante un segundo se veian cuatro controles que despues desaparecian de
// golpe dentro del ⋯.
//
// Ahora los colapsables llegan con el lugar RESERVADO y sin dibujarse, y el controlador los
// destapa al terminar su primer `apply()`. `visibility: hidden` y no `display: none`: la
// caja se conserva, asi que la medicion que decide el colapso mide lo mismo que sin esto.
//
// Sobre por que la pagina es /admin/studios y no un preview, ver
// data-table-toolbar-alignment.cy.js.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const url = `${appOrigin}/admin/studios`

const ATRIBUTO = 'data-toolbar-overflow-settling'
const toolbar = () => cy.get('[data-controller~="toolbar-overflow"]')

describe('DataTable: la toolbar reserva el lugar de lo que puede colapsar', () => {
  // Sobre el HTML crudo, que es lo que el navegador pinta antes de ejecutar nada. Sin
  // timing: lo que se comprueba es el contrato del servidor, no una carrera.
  it('lo manda reservado desde el servidor', () => {
    cy.request(url).its('body').then(html => {
      expect(html, 'la fila marcada').to.include(ATRIBUTO)
      // El `&` de la variante arbitraria sale escapado en el atributo, asi que se busca el
      // tramo que no lo lleva.
      expect(html, 'y la utilidad que esconde').to.include(
        `[[${ATRIBUTO}]_`
      )
      expect(html, 'con la salida para quien no ejecuta scripts').to.include('<noscript>')
    })
  })

  it('lo destapa entero una vez que el controlador corrio', () => {
    cy.viewport(1900, 1000)
    cy.visit(url)
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')

    toolbar().should('not.have.attr', ATRIBUTO)
    cy.get('[data-toolbar-overflow-target="item"]').each($item => {
      expect(window.getComputedStyle($item[0]).visibility, 'ningun control queda escondido')
        .to.equal('visible')
    })
  })

  // Lo que separa este arreglo de un `display: none` que romperia la medicion. Se prueba
  // volviendo a poner el atributo, porque el estado real dura lo que tarda el bundle.
  it('reserva la caja en vez de sacarla del layout', () => {
    cy.viewport(2600, 1000)
    cy.visit(url)
    cy.get('[data-controller~="toolbar-overflow"]').should('exist')
    // A este ancho la fila entra entera, asi que los colapsables siguen en ella.
    cy.get('[data-toolbar-overflow-target="menu"]').should($menu => {
      expect($menu[0].children.length, 'nada colapso a este ancho').to.equal(0)
    })

    cy.get('[data-toolbar-overflow-priority="30"]').then($item => {
      const antes = Math.round($item[0].getBoundingClientRect().width)
      expect(antes, 'el control mide algo para empezar').to.be.greaterThan(0)

      cy.get('[data-controller~="toolbar-overflow"]').invoke('attr', ATRIBUTO, '')
      cy.get('[data-toolbar-overflow-priority="30"]').should($otra => {
        expect(window.getComputedStyle($otra[0]).visibility).to.equal('hidden')
        expect(Math.round($otra[0].getBoundingClientRect().width), 'y conserva su caja')
          .to.equal(antes)
      })
    })
  })
})
