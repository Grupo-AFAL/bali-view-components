// `button_to` envuelve su boton en un `<form>`, y daisyUI pinta el item del menu sobre
// `li > *` salvo que sea un `.btn`. El form no lo es, asi que se llevaba el padding, el
// radio y el hover del item mientras el boton quedaba adentro con una segunda caja propia:
// Delete medido 192x49 con un hover de 168x37 adentro, contra los 192x37 de Edit (#829).
//
// El arreglo es `display: contents` sobre el form, y lo que esta prueba cuida es la CASCADA,
// que es donde se puede romper sin que falle ningun assert de Ruby. El default vive en
// @layer components (`.bali-delete-link-form`) justamente para que la utilidad del call site
// le gane: como utilidad sobre el elemento las dos empataban en capa y especificidad, y el
// desempate lo ganaba la hoja compilada — medido, `.contents` se emite ANTES que
// `.inline-block`, asi que `class="inline-block contents"` renderiza inline-block y el
// `form_class` no hacia nada.
describe('El item Delete de un menu es la misma caja que sus vecinos', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/actions_dropdown/default')
    cy.get('[data-dropdown-target="trigger"]').first().click()
  })

  // Se devuelve el rect y no el nodo: lo que sale de un `.then` lo re-envuelve Cypress, y
  // un `<li>` devuelto ahi vuelve como sujeto, no como elemento.
  const cajaDelItemDe = texto =>
    cy.contains('li > *', texto).then($el => {
      const r = $el[0].closest('li').getBoundingClientRect()
      return { w: Math.round(r.width), h: Math.round(r.height) }
    })

  it('el form no genera caja, asi que el boton ES el item', () => {
    cy.get('li > form').first().should($form => {
      expect(window.getComputedStyle($form[0]).display, 'el form no dibuja caja')
        .to.equal('contents')
    })
  })

  it('Delete mide lo mismo que un item de enlace', () => {
    cajaDelItemDe('Edit').then(enlace => {
      cajaDelItemDe('Delete').then(borrar => {
        expect(borrar.h, 'mismo alto').to.equal(enlace.h)
        expect(borrar.w, 'mismo ancho').to.equal(enlace.w)
      })
    })
  })

  // La segunda mitad del defecto: dos cajas de hover anidadas, una con radio de 4px dentro
  // de otra de 8px. Con el form fuera del arbol queda una sola.
  it('el boton llena su item, sin una segunda caja adentro', () => {
    cy.contains('li > form button', 'Delete').should($btn => {
      const boton = $btn[0].getBoundingClientRect()
      const item = $btn[0].closest('li').getBoundingClientRect()

      expect(Math.round(boton.width), 'el boton no queda embutido').to.equal(Math.round(item.width))
      expect(Math.round(boton.left)).to.equal(Math.round(item.left))
    })
  })
})
