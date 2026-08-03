// `box-shadow` no vuelve "none" cuando Tailwind lo apaga: vuelve la lista de capas que
// arma con sus custom properties, todas en cero. Compararla contra 'none' da un falso
// negativo, asi que se lee capa por capa: una capa pinta si su color no tiene alpha 0 y
// alguna de sus longitudes no es 0.
const capas = valor => (valor === 'none' ? [] : valor.split(/,\s*(?=rgba?\()/))

const pinta = valor =>
  capas(valor).some(
    capa => !/^rgba\(\s*\d+,\s*\d+,\s*\d+,\s*0\s*\)/.test(capa) && /[1-9]\d*px/.test(capa)
  )

const sombra = $n => window.getComputedStyle($n[0]).boxShadow

describe('Navbar: la sombra', () => {
  it('viene puesta, y desde la hoja en vez de una utilidad sobre el elemento', () => {
    cy.visit('/bali/navbar/default')

    cy.get('.navbar').should($n => {
      // El default es `.navbar { @apply shadow-sm }` en navbar/index.css. Tiene que vivir
      // ahi, dentro de @layer components, porque es el unico lugar donde la regla de
      // `.is-transparent` puede ganarle.
      expect($n[0].className, 'sin utilidad de sombra en el atributo').to.not.match(
        /\bshadow-(sm|md|none)\b/
      )
      expect(pinta(sombra($n)), 'la sombra se ve').to.equal(true)
    })
  })

  it('`shadow: false` la apaga desde @layer utilities', () => {
    cy.visit('/bali/navbar/default?shadow=false')

    cy.get('.navbar').should($n => {
      expect($n[0].className, 'lleva shadow-none').to.match(/\bshadow-none\b/)
      expect(pinta(sombra($n)), 'y no queda sombra').to.equal(false)
    })
  })

  // Lo que estaba roto sin que se notara: `.navbar.is-transparent { @apply shadow-none }`
  // vive en @layer components y perdia contra el `shadow-sm` que el propio componente se
  // ponia como utilidad. Medido antes del arreglo sobre este mismo preview, con
  // `is-transparent` en el elemento, box-shadow seguia en `0 1px 3px rgba(0,0,0,.1)`.
  it('un navbar transparente ya no la conserva, y ahora es transparente', () => {
    cy.visit('/bali/navbar/with_sidebar_burger?transparency=true')

    cy.get('.navbar').should('have.class', 'is-transparent')
    cy.get('.navbar').should($n => {
      const cs = window.getComputedStyle($n[0])

      expect(pinta(sombra($n)), 'sin sombra').to.equal(false)
      // El fondo perdía por lo mismo que la sombra, contra el `bg-base-100` que emitía el
      // preset de `color:` como utilidad. Medido antes: `oklch(1 0 0)`.
      expect(cs.backgroundColor, 'y sin fondo').to.match(/rgba\(0, 0, 0, 0\)|transparent/)
    })
  })

  // El preset sigue pintando cuando el navbar NO es transparente — es lo que la mudanza a
  // @layer components podría haber roto en silencio.
  it('el preset de color sigue pintando el navbar opaco', () => {
    cy.visit('/bali/navbar/default?color=primary')

    cy.get('.navbar').should($n => {
      expect($n[0].className, 'clase de Bali, no utilidad').to.match(/\bnavbar-primary\b/)
      expect(window.getComputedStyle($n[0]).backgroundColor).to.not.match(
        /rgba\(0, 0, 0, 0\)|transparent/
      )
    })
  })
})
