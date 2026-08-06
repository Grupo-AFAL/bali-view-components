// `mobile_bottom_padding` es CSS puro, pero su mitad que importa vive detras de una media
// query: hay que MEDIRLA con un viewport de telefono de verdad, no deducirla de la hoja.
// Lo que se mide es el padding COMPUTADO de <main>, que es donde aterriza el aire (el del
// contenedor lo pone una utilidad de Tailwind y le ganaria a cualquier regla de la capa).
describe('AppLayout: aire abajo en telefono', () => {
  const main = '.app-layout-content > main'
  const conOpcion = '/bali/app_layout/default?mobile_bottom_padding=true'

  it('en escritorio deja 1rem, que es lo que ya habia', () => {
    cy.viewport(1440, 900)
    cy.visit(conOpcion)
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('16px')
    })
  })

  // 4rem y no `env(safe-area-inset-bottom)`: la barra flotante de Safari se pinta ENCIMA de
  // la pagina y no se refleja en safe-area, asi que la constante no la reemplaza el entorno.
  it('bajo 640px deja 4rem para la barra flotante del navegador', () => {
    cy.viewport(390, 844)
    cy.visit(conOpcion)
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('64px')
    })
  })

  // Opt-in: sin la opcion, el layout es exactamente el de antes en los dos anchos.
  it('sin la opcion no agrega nada, ni en telefono', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/app_layout/default')
    cy.get('body').should('not.have.class', 'app-layout--mobile-bottom-padding')
    cy.get(main).should($m => {
      expect(getComputedStyle($m[0]).paddingBottom).to.equal('0px')
    })
  })
})
