// El offset del banner es geometria, asi que se mide geometria: el `top` y el `height`
// COMPUTADOS del riel fijo contra la altura real de la franja. Nada de textContent y nada
// de pixeles hardcodeados — la franja mide lo que midan su fuente y su padding, y lo que
// esta bajo prueba es que el sidebar la siga, no cuanto mide.
describe('AppLayout: el sidebar fijo arranca debajo del banner', () => {
  const ESCRITORIO = [1440, 900]

  const visitar = (banners) => {
    cy.viewport(...ESCRITORIO)
    cy.visit(`/bali/app_layout/with_banner?banners=${banners}`)
    // El offset lo escribe el controlador tras medir, asi que hay que esperar a que la
    // variable exista: sin esto se mide el frame anterior a `connect()`.
    cy.get('body').should($body => {
      expect($body[0].style.getPropertyValue('--bali-banner-height')).to.not.equal('')
    })
  }

  // La franja y el riel se tocan sin solaparse ni dejar pagina entre medio.
  const sidebarPegadoAlBanner = () => {
    cy.get('.app-layout-banner').then($banner => {
      const franja = $banner[0].getBoundingClientRect()

      cy.get('.side-menu-component--fixed').should($sidebar => {
        const riel = $sidebar[0].getBoundingClientRect()

        expect(riel.top, 'el riel arranca donde termina la franja').to.be.closeTo(franja.bottom, 1)
        expect(riel.bottom, 'y llega hasta el fondo del viewport').to.be.closeTo(
          $sidebar[0].ownerDocument.defaultView.innerHeight, 1
        )
      })
    })
  }

  it('con un banner, el riel baja exactamente su altura', () => {
    visitar(1)
    sidebarPegadoAlBanner()

    cy.get('.side-menu-component--fixed').should($sidebar => {
      expect($sidebar[0].getBoundingClientRect().top, 'no sigue en cero').to.be.greaterThan(0)
    })
  })

  // El caso que gc parchea a mano con `top: 5.5rem !important`: dos franjas apiladas.
  it('con dos banners apilados, baja la suma de los dos', () => {
    visitar(2)
    sidebarPegadoAlBanner()

    cy.get('.app-layout-banner').then($conDos => {
      const alturaConDos = $conDos[0].getBoundingClientRect().height

      visitar(1)
      cy.get('.app-layout-banner').should($conUno => {
        expect(alturaConDos, 'dos franjas miden mas que una').to.be.greaterThan(
          $conUno[0].getBoundingClientRect().height
        )
      })
    })
  })

  it('al descartar uno de los dos, el riel sube a la nueva altura', () => {
    visitar(2)

    cy.get('.side-menu-component--fixed').then($antes => {
      const topAntes = $antes[0].getBoundingClientRect().top

      cy.get('.app-layout-banner [data-action="alert#dismiss"]').click()

      cy.get('.side-menu-component--fixed').should($despues => {
        expect($despues[0].getBoundingClientRect().top, 'el riel subio').to.be.lessThan(topAntes)
      })

      sidebarPegadoAlBanner()
    })
  })

  // Sin banner no hay variable que valga: el riel se queda donde siempre estuvo, y esa es
  // la garantia de que este cambio no toca a quien no usa el slot.
  it('sin banner, el riel sigue pegado al techo', () => {
    cy.viewport(...ESCRITORIO)
    cy.visit('/bali/app_layout/default')

    cy.get('.side-menu-component--fixed').should($sidebar => {
      expect($sidebar[0].getBoundingClientRect().top, 'top 0').to.be.closeTo(0, 1)
    })
  })

  // D726-1: franja completa. Si el banner tomara el padding-left del sidebar, su borde
  // izquierdo arrancaria a 16rem y quedaria metido en la columna de contenido.
  it('la franja ocupa el ancho completo, no la columna de contenido', () => {
    visitar(2)

    cy.get('.app-layout-banner').should($banner => {
      const franja = $banner[0].getBoundingClientRect()

      expect(franja.left, 'pegada al borde izquierdo').to.be.closeTo(0, 1)
      expect(franja.width, 'ancho completo del viewport').to.be.closeTo(
        $banner[0].ownerDocument.defaultView.innerWidth, 1
      )
    })
  })
})
