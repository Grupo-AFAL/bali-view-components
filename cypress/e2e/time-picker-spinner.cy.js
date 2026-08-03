// La hora, los minutos y los segundos son `input[type=number]`. Chrome dejo de honrar
// `appearance: textfield` para ese tipo de input, asi que sobre el campo que tiene el mouse
// encima dibuja SU spinner ademas de las flechas que flatpickr pinta en `.numInputWrapper`:
// dos pares en la misma columna, y el nativo —mas grande, mas oscuro, con su propia pista
// gris— montado sobre el unico de los dos que esta conectado al valor del calendario.
//
// La comprobacion se hace sobre el CSSOM y no sobre estilos computados a proposito:
// `getComputedStyle(input, '::-webkit-inner-spin-button').appearance` devuelve el valor del
// input, no el del pseudo — medido, sigue diciendo `textfield` con la regla aplicada y las
// flechas ya desarmadas. Leer las reglas comprueba lo que si se puede comprobar sin ojos:
// que la declaracion llega al navegador a traves del build y que nada posterior la revierte.
const reglasDeSpinner = doc =>
  [...doc.styleSheets]
    .flatMap(hoja => {
      try {
        return [...hoja.cssRules]
      } catch {
        return [] // hoja de otro origen
      }
    })
    .filter(
      regla =>
        regla.selectorText &&
        /\.flatpickr-time input::-webkit-(inner|outer)-spin-button/.test(regla.selectorText)
    )

describe('Time picker: el spinner nativo', () => {
  beforeEach(() => {
    cy.visit('/bali/form/time/default')
    // `.flatpickr-input` es el campo real, y flatpickr lo vuelve `type=hidden` al montar
    // su altInput. El que se ve, y el que abre el calendario, es el altInput.
    cy.get('input.input:visible').click()
    cy.get('.flatpickr-time input.flatpickr-minute').should('be.visible')
  })

  it('queda desarmado en los tres campos de la fila', () => {
    cy.document().then(doc => {
      const reglas = reglasDeSpinner(doc)

      expect(reglas.length, 'la hoja embarca la regla').to.be.greaterThan(0)
      reglas.forEach(regla => {
        const valor = regla.style.appearance || regla.style.webkitAppearance
        expect(valor, `${regla.selectorText} lo apaga`).to.equal('none')
      })
    })
  })

  it('las flechas que quedan son las de flatpickr, una por columna', () => {
    cy.get('.flatpickr-time .numInputWrapper').each($wrapper => {
      const flechas = $wrapper[0].querySelectorAll('span.arrowUp, span.arrowDown')
      expect(flechas.length, 'un par por columna').to.equal(2)
    })
  })
})
