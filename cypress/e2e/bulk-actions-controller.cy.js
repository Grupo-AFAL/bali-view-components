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

    // The property, not the attribute: `indeterminate` does not exist as an HTML attribute.
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

  // The "act on the N filtered" mode: the bar only offers it once the selection already
  // covers the whole page and there are more results behind it.
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
      // N is the total of the listing, not the total of the page.
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
      // The ids come out EMPTY: the server re-derives the scope from the filters in the same POST.
      cy.get(`${bar} input[name="selected_ids"]`).each(($input) => {
        expect(JSON.parse($input.val())).to.have.length(0)
      })
    })

    // The mode change does not move focus: if the live region only says the number, the
    // screen reader user hears "20 selected" with nothing telling them that the selection is
    // no longer the page they are looking at.
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

  // The event exists because the checkbox `change` does NOT cover every path: double click,
  // ✕ and "select all filtered" write `checkbox.checked` by assignment, and assigning the
  // property does not fire the native event. A consumer hooked to the checkboxes was left
  // with the wrong state, and silently.
  describe('bulk-actions:change', () => {
    const record = () => cy.window().then((win) => {
      win.selectionEvents = []
      win.addEventListener('bulk-actions:change', (event) => win.selectionEvents.push(event.detail))
    })

    it('announces the selection when a row is checked', () => {
      record()
      cy.get(rows).first().find('input[type="checkbox"]').check()

      cy.window().its('selectionEvents').should((events) => {
        expect(events).to.have.length(1)
        expect(events[0].selectedIds).to.have.length(1)
        expect(events[0].count).to.eq(1)
        expect(events[0].selectAllFiltered).to.eq(false)
      })
    })

    it('also announces the paths that do not fire the checkbox change', () => {
      record()
      cy.get(rows).first().find('td').eq(1).dblclick()
      cy.window().its('selectionEvents').should('have.length', 1)

      cy.get(`${bar} button[data-action="bulk-actions#clear"]`).click()
      cy.window().its('selectionEvents').should((events) => {
        expect(events).to.have.length(2)
        expect(events[1].selectedIds).to.have.length(0)
      })
    })

    it('announces the "select all filtered" mode, which has no ids to announce', () => {
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
