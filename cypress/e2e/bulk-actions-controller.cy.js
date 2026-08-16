describe('BulkActionsController', () => {
  const container = '.data-table-component'
  const toolbar = '[data-bulk-actions-target="toolbar"]'
  const bar = '[data-bulk-actions-target="actionsContainer"]'
  const counter = '[data-bulk-actions-target="selectedCount"]'
  const selectAll = '[data-bulk-actions-target="selectAll"]'
  const rows = `${container} tbody tr[data-bulk-actions-target="item"]`

  beforeEach(() => {
    cy.visit('/bali/data_table/with_bulk_actions')
  })

  it('swaps the toolbar for the contextual bar when a row is selected', () => {
    cy.get(toolbar).should('not.have.class', 'hidden')
    cy.get(bar).should('have.class', 'hidden')

    cy.get(rows).first().find('input[type="checkbox"]').check()

    cy.get(toolbar).should('have.class', 'hidden')
    cy.get(bar).should('not.have.class', 'hidden')
    cy.get(counter).should('have.text', '1')
    cy.get('[data-bulk-actions-target="selectedLabelOne"]').should('not.have.class', 'hidden')
    cy.get('[data-bulk-actions-target="selectedLabelOther"]').should('have.class', 'hidden')
  })

  it('injects the selected ids into every action form', () => {
    cy.get(rows).eq(0).find('input[type="checkbox"]').check()
    cy.get(rows).eq(1).find('input[type="checkbox"]').check()

    cy.get(counter).should('have.text', '2')
    cy.get('[data-bulk-actions-target="selectedLabelOther"]').should('not.have.class', 'hidden')
    cy.get(`${bar} input[name="selected_ids"]`).first().should(($input) => {
      expect(JSON.parse($input.val())).to.have.length(2)
    })
  })

  it('selects and deselects the whole page from the header checkbox', () => {
    cy.get(rows).then(($rows) => {
      const total = $rows.length

      cy.get(selectAll).check()
      cy.get(counter).should('have.text', String(total))
      cy.get(`${rows}.selected`).should('have.length', total)

      cy.get(selectAll).uncheck()
      cy.get(counter).should('have.text', '0')
      cy.get(toolbar).should('not.have.class', 'hidden')
    })
  })

  it('leaves the header checkbox indeterminate on a partial selection', () => {
    cy.get(rows).first().find('input[type="checkbox"]').check()

    // La propiedad, no el atributo: `indeterminate` no existe como atributo HTML.
    cy.get(selectAll).should(($input) => {
      expect($input[0].indeterminate).to.eq(true)
      expect($input[0].checked).to.eq(false)
    })
  })

  it('restores the toolbar when the selection is cleared', () => {
    cy.get(rows).first().find('input[type="checkbox"]').check()
    cy.get(`${bar} button[data-action="bulk-actions#clear"]`).click()

    cy.get(counter).should('have.text', '0')
    cy.get(`${rows}.selected`).should('have.length', 0)
    cy.get(toolbar).should('not.have.class', 'hidden')
    cy.get(bar).should('have.class', 'hidden')
  })

  // El modo "actuar sobre los N filtrados": la barra lo ofrece solo cuando la selección ya
  // cubre la página entera y hay más resultados detrás.
  describe('select all filtered', () => {
    const offer = '[data-bulk-actions-target="selectAllOffer"]'
    const notice = '[data-bulk-actions-target="selectAllNotice"]'
    const flag = 'input[name="select_all_filtered"]'

    it('offers the whole result only once the page is fully selected', () => {
      cy.get(rows).first().find('input[type="checkbox"]').check()
      cy.get(offer).should('not.be.visible')

      cy.get(selectAll).check()
      cy.get(offer).should('be.visible')
      cy.get(notice).should('not.be.visible')
      // N es el total del listado, no el de la página.
      cy.get(rows).then(($rows) => {
        cy.get(offer).invoke('attr', 'data-total-count').then((total) => {
          expect(Number(total)).to.be.greaterThan($rows.length)
          cy.get(`${offer} button`).should('contain.text', total)
        })
      })
    })

    it('switches every action form to the whole result and empties the ids', () => {
      cy.get(selectAll).check()
      cy.get(`${offer} button`).click()

      cy.get(offer).should('not.be.visible')
      cy.get(notice).should('be.visible')
      cy.get(offer).invoke('attr', 'data-total-count').then((total) => {
        cy.get(counter).should('have.text', total)
      })

      cy.get(`${bar} ${flag}`).should('have.length.greaterThan', 1)
      cy.get(`${bar} ${flag}`).each(($input) => expect($input.val()).to.eq('true'))
      // Los ids salen VACÍOS: el servidor re-deriva el scope de los filtros del mismo POST.
      cy.get(`${bar} input[name="selected_ids"]`).each(($input) => {
        expect(JSON.parse($input.val())).to.have.length(0)
      })
    })

    // El cambio de modo no mueve el foco: si la live region solo dice el número, el usuario
    // de lector de pantalla oye "20 seleccionados" sin nada que le diga que la selección ya
    // no es la página que está mirando.
    it('announces the mode change, not just the new number', () => {
      const announcement = '[data-bulk-actions-target="announcement"]'

      cy.get(selectAll).check()
      cy.get(announcement).should('contain.text', 'selected')

      cy.get(`${offer} button`).click()
      cy.get(notice).invoke('text').then((noticeText) => {
        cy.get(announcement).should('have.text', noticeText.trim())
      })
    })

    it('leaves the mode when a row is unchecked, without disabling anything', () => {
      cy.get(selectAll).check()
      cy.get(`${offer} button`).click()
      cy.get(notice).should('be.visible')

      cy.get(rows).first().find('input[type="checkbox"]').should('not.be.disabled').uncheck()

      cy.get(notice).should('not.be.visible')
      cy.get(offer).should('not.be.visible')
      cy.get(`${bar} ${flag}`).each(($input) => expect($input.val()).to.eq('false'))
      cy.get(rows).then(($rows) => {
        cy.get(counter).should('have.text', String($rows.length - 1))
      })
    })

    it('leaves the mode when the selection is cleared', () => {
      cy.get(selectAll).check()
      cy.get(`${offer} button`).click()

      cy.get(`${bar} button[data-action="bulk-actions#clear"]`).click()

      cy.get(counter).should('have.text', '0')
      cy.get(bar).should('have.class', 'hidden')
      cy.get(toolbar).should('not.have.class', 'hidden')
    })
  })

  // El evento existe porque el `change` de la casilla NO cubre todos los caminos: doble
  // clic, ✕ y "todos los filtrados" escriben `checkbox.checked` por asignación, y asignar la
  // propiedad no dispara el evento nativo. Un consumidor enganchado a las casillas se
  // quedaba con su estado equivocado y en silencio.
  describe('bulk-actions:change', () => {
    const record = () => cy.window().then((win) => {
      win.selectionEvents = []
      win.addEventListener('bulk-actions:change', (event) => win.selectionEvents.push(event.detail))
    })

    it('anuncia la selección al marcar una fila', () => {
      record()
      cy.get(rows).first().find('input[type="checkbox"]').check()

      cy.window().its('selectionEvents').should((events) => {
        expect(events).to.have.length(1)
        expect(events[0].selectedIds).to.have.length(1)
        expect(events[0].count).to.eq(1)
        expect(events[0].selectAllFiltered).to.eq(false)
      })
    })

    it('anuncia también los caminos que no disparan el change de la casilla', () => {
      record()
      cy.get(rows).first().find('td').eq(1).dblclick()
      cy.window().its('selectionEvents').should('have.length', 1)

      cy.get(`${bar} button[data-action="bulk-actions#clear"]`).click()
      cy.window().its('selectionEvents').should((events) => {
        expect(events).to.have.length(2)
        expect(events[1].selectedIds).to.have.length(0)
      })
    })

    it('anuncia el modo "todos los filtrados", que no tiene ids que anunciar', () => {
      cy.get(selectAll).check()
      record()
      cy.get('[data-bulk-actions-target="selectAllOffer"] button').click()

      cy.window().its('selectionEvents').should((events) => {
        const last = events[events.length - 1]
        expect(last.selectAllFiltered).to.eq(true)
        expect(last.count).to.be.greaterThan(last.selectedIds.length)
      })
    })
  })

  it('selects a row on double click and keeps its checkbox in sync', () => {
    cy.get(rows).first().find('td').eq(1).dblclick()
    cy.get(counter).should('have.text', '1')
    cy.get(rows).first().find('input[type="checkbox"]').should('be.checked')

    cy.get(rows).first().find('td').eq(1).dblclick()
    cy.get(counter).should('have.text', '0')
    cy.get(rows).first().find('input[type="checkbox"]').should('not.be.checked')
  })
})
