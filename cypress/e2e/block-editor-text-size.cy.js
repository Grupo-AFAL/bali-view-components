// BlockNote declara el tamaño del cuerpo del editor UNA vez, en
// `.bn-editor.bn-default-styles`, y todo lo que dibuja adentro sale en `em` de ahí:
// los headings en 3em/2em/1.3em, y `font-size: inherit` para párrafos, items de lista
// y celdas. Por eso `size:` es una sola declaración y aun así mueve el documento
// entero en proporción.
//
// Lo que se mide acá es esa proporción, que es justo lo que se rompe en silencio:
// basta que alguien vuelva a fijar en `rem` uno de los valores que Bali pasó a `em`
// —el code block, la sangría anidada, la casilla del checklist— para que ese pedazo
// se quede quieto mientras el resto encoge, y nada falla hasta que alguien lo mira.
//
// `md` vale doble: además de escalar, tiene que dar EXACTAMENTE los px que BlockNote
// traía antes de que existiera `size:`. Si esta mitad se cae, el default cambió.
const preview = size =>
  `bali/block_editor/with_initial_content${size ? `?size=${size}` : ''}`

const px = valor => parseFloat(valor)

const medir = () => {
  const css = (selector, prop) =>
    cy.get(selector).first().then($el => px(getComputedStyle($el[0])[prop]))

  return {
    cuerpo: () => css('.bn-editor.bn-default-styles', 'fontSize'),
    parrafo: () => css('[data-content-type="paragraph"]', 'fontSize'),
    vineta: () => css('[data-content-type="bulletListItem"]', 'fontSize'),
    codigo: () => css('[data-content-type="codeBlock"] pre code', 'fontSize'),
    sangria: () => css('.bn-block-group .bn-block-group', 'marginLeft'),
    casilla: () => css('[data-content-type="checkListItem"] > div > input', 'height')
  }
}

// El editor es React montado por Stimulus: hay que esperar a que exista el contenido,
// no solo el contenedor, o se mide el div vacío que el servidor mandó.
const abrir = size => {
  cy.visit(preview(size))
  cy.get('.bn-editor.bn-default-styles').should('exist')
  cy.get('[data-content-type="paragraph"]').should('exist')
}

describe('BlockEditor: `size:` escala el documento entero', () => {
  it('en `md` deja intactas las medidas que traía BlockNote', () => {
    abrir('md')

    cy.get('.block-editor-component').should('have.class', 'block-editor-size-md')

    const m = medir()
    m.cuerpo().should('eq', 16)
    m.codigo().should('eq', 14)
    m.sangria().should('eq', 24)
    m.casilla().should('eq', 24)
  })

  it('es el default cuando nadie pasa `size:`', () => {
    abrir(null)

    cy.get('.block-editor-component').should('have.class', 'block-editor-size-md')
    medir().cuerpo().should('eq', 16)
  })

  const escalas = [
    { size: 'xs', factor: 0.75 },
    { size: 'sm', factor: 0.875 },
    { size: 'lg', factor: 1.125 }
  ]

  escalas.forEach(({ size, factor }) => {
    it(`en \`${size}\` mueve texto y geometría por el mismo factor`, () => {
      abrir(size)

      cy.get('.block-editor-component').should('have.class', `block-editor-size-${size}`)

      const m = medir()
      m.cuerpo().should('eq', 16 * factor)
      m.parrafo().should('eq', 16 * factor)
      m.vineta().should('eq', 16 * factor)
      m.codigo().should('eq', 14 * factor)
      m.sangria().should('eq', 24 * factor)
      m.casilla().should('eq', 24 * factor)
    })
  })

  // Los menús y la barra son UI, no contenido: encogerlos por debajo de su área de
  // toque no es lo que pidió un campo compacto. Se mide el `h2`, que sí es contenido,
  // contra la relación 2em que BlockNote le da -- si alguien mete el tamaño en la
  // rampa de headings en vez de en el cuerpo, esta proporción se rompe.
  it('mantiene la rampa de headings proporcional al cuerpo', () => {
    abrir('xs')

    const m = medir()
    m.cuerpo().then(cuerpo => {
      cy.get('[data-content-type="heading"][data-level="2"]')
        .first()
        .then($h2 => {
          expect(px(getComputedStyle($h2[0]).fontSize)).to.eq(cuerpo * 2)
        })
    })
  })
})
