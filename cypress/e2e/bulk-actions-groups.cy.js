// Un solo `bulk-actions` para N listados: cada seleccionar-todo marca lo suyo y el contador
// sigue siendo uno, el total. Lo que el componente descarta —una instancia por grupo— daría
// N contadores y ningún total, y anidarlas dejaría a la barra de afuera sin ver las filas.
describe('BulkActionsController — selección por subgrupo', () => {
  const counter = '[data-bulk-actions-target="selectedCount"]'
  const tables = '.table-component'
  const rows = 'tbody tr[data-bulk-actions-target="item"]'
  const groupHeader = 'tr.bali-table-group-row'
  const selectAll = 'thead input[type="checkbox"]'

  describe('varias tablas bajo una sola barra', () => {
    beforeEach(() => {
      cy.visit('/bali/table/selectable_by_group')
    })

    it('acota el seleccionar-todo de cada tabla a sus propias filas', () => {
      cy.get(tables).eq(0).find(selectAll).check()

      cy.get(tables).eq(0).find(`${rows}.selected`).should('have.length', 3)
      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 0)
      cy.get(counter).should('have.text', '3')
    })

    it('suma las dos tablas en el MISMO contador', () => {
      cy.get(tables).eq(0).find(selectAll).check()
      cy.get(tables).eq(1).find(selectAll).check()

      cy.get(counter).should('have.text', '7')
      cy.get(`${rows}.selected`).should('have.length', 7)
    })

    it('acota el seleccionar-todo de un grupo a su corrida', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()

      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 2)
      cy.get(tables).eq(0).find(`${rows}.selected`).should('have.length', 0)
      cy.get(counter).should('have.text', '2')
    })

    // La fila lleva los dos ids —el de su tabla y el de su grupo—, así que el de arriba
    // sigue alcanzándola: sin eso, la cabecera de una tabla agrupada no marcaría nada.
    it('deja que la cabecera de la tabla alcance a sus grupos', () => {
      cy.get(tables).eq(1).find(selectAll).check()

      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 4)
      cy.get(tables).eq(1).find(`${groupHeader} input`).each(($input) => {
        expect($input[0].checked).to.eq(true)
      })
    })

    it('deja indeterminada la cabecera cuando solo un grupo está completo', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()

      cy.get(tables).eq(1).find(selectAll).should(($input) => {
        // La propiedad, no el atributo: `indeterminate` no existe como atributo HTML.
        expect($input[0].indeterminate).to.eq(true)
        expect($input[0].checked).to.eq(false)
      })
      cy.get(tables).eq(1).find(`${groupHeader} input`).eq(1).should(($input) => {
        expect($input[0].indeterminate).to.eq(false)
        expect($input[0].checked).to.eq(false)
      })
    })

    it('devuelve el estado del grupo al desmarcar una sola fila', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()
      cy.get(tables).eq(1).find(rows).first().find('input[type="checkbox"]').uncheck()

      cy.get(tables).eq(1).find(`${groupHeader} input`).first().should(($input) => {
        expect($input[0].checked).to.eq(false)
        expect($input[0].indeterminate).to.eq(true)
      })
      cy.get(counter).should('have.text', '1')
    })
  })

  describe('filas fuera de la selección', () => {
    beforeEach(() => {
      cy.visit('/bali/table/partially_selectable')
    })

    it('no deja que el seleccionar-todo alcance a las filas que se declararon fuera', () => {
      cy.get('tbody tr').should('have.length', 5)
      cy.get(rows).should('have.length', 3)

      cy.get(selectAll).check()

      cy.get(`${rows}.selected`).should('have.length', 3)
      cy.get(counter).should('have.text', '3')
      cy.get(selectAll).should(($input) => {
        expect($input[0].checked).to.eq(true)
        expect($input[0].indeterminate).to.eq(false)
      })
    })

    // La celda vacía es la que sostiene la alineación: sin ella, las columnas de esa fila
    // se corren una posición.
    it('conserva la celda de selección vacía en las filas que no participan', () => {
      cy.get('tbody tr').each(($row) => {
        expect($row.find('td')).to.have.length(4)
      })
      cy.get('tbody tr').not(rows).find('input[type="checkbox"]').should('have.length', 0)
    })
  })
})
