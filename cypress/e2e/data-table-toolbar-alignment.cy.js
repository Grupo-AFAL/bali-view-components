// The `SimpleFilters` block carries the label ABOVE each control, so it is twice as tall as
// any single-line neighbour, and wraps to two rows when the row gets tight. With the toolbar
// centered, everything sharing the row with it aligned against the block's CENTER instead of
// against its line of controls: measured on /admin/studios at 1900px, the ⋯ at y=226 and the
// Filter button —which lives on the last line of that block— at y=264, 38px below.
//
// The page is `/admin/studios` and not a preview because both things have to be there at
// once: `SimpleFilters` and collapsible controls that fill the ⋯. The preview
// `data_table/with_simple_filters` has the first and not the second, so the ⋯ does not even
// render there. The origin is derived from `baseUrl` instead of written out: a literal
// `http://localhost:3001` ignores CYPRESS_BASE_URL and silently tests another checkout's
// server when the suite runs from a worktree.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const studios = () => cy.visit(`${appOrigin}/admin/studios`)

const filtersRow = () => cy.get('.data-table-component form > div').first()
const bottom = el => Math.round(el.getBoundingClientRect().bottom)

describe('DataTable: the toolbar row aligns on its line of controls', () => {
  it('rests the ⋯ on the same line as the filter button', () => {
    cy.viewport(1900, 1000)
    studios()

    // The valve is late: the controls that overflow the row grow AFTER the first layout
    // (SlimSelect replaces its select, flatpickr mounts its own), so the ⋯ is not there
    // at mount.
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')

    cy.get('.data-table-component form button[type="submit"]').first().then($submit => {
      cy.get('[data-toolbar-overflow-target="overflow"] .btn').first().then($dots => {
        expect(bottom($dots[0]) - bottom($submit[0]), 'vertical difference').to.equal(0)
      })
    })
  })

  // Aligning the ROW fixes one level and leaves the other: the groups that make it up align
  // their own children too, and the only one holding the tall block centered them against it.
  // Measured with the row aligned but the groups centered, at 2600px: "Views" and the
  // persistence marker at 0 from the Filter button, but "Group by" and "Columns" 11px above.
  it('leaves ALL the toolbar controls on the same line', () => {
    cy.viewport(2600, 1000) // width to spare: nothing collapses and the filters row does not wrap
    studios()
    cy.get('[data-controller~="toolbar-overflow"]').should('exist')
    cy.get('[data-toolbar-overflow-target="menu"]').should($m => {
      expect($m[0].children.length, 'nothing collapsed at this width').to.equal(0)
    })

    cy.get('.data-table-component form button[type="submit"]').first().then($submit => {
      const line = bottom($submit[0])

      cy.get('[data-controller~="toolbar-overflow"] [aria-label]').each($control => {
        const el = $control[0]
        if (el.getBoundingClientRect().height === 0) return // inside a closed dropdown
        if ($submit[0].contains(el) || el.contains($submit[0])) return

        expect(bottom(el), `${el.getAttribute('aria-label')} on the line of controls`)
          .to.equal(line)
      })
    })
  })

  // The 4px of padding dropped to get that alignment were the place of the last control's
  // focus ring: the row was a scroll container at ALL widths (`overflow-x-auto` with no
  // condition) and a scroll container clips at its padding box. Above the breakpoint the row
  // wraps and never scrolls, so the overflow goes back to `visible` and there is nothing
  // left to clip.
  it('does not turn the row into a scroll container where it does not scroll', () => {
    cy.viewport(1900, 1000)
    studios()

    filtersRow().should($row => {
      const cs = window.getComputedStyle($row[0])
      expect(cs.overflowX, 'no scroll container').to.equal('visible')
      expect(cs.overflowY).to.equal('visible')
    })
  })

  // Below the breakpoint nothing changes: there the row DOES scroll horizontally and the gap
  // underneath is its scrollbar's.
  it('keeps the horizontal scroll of the filters on a phone', () => {
    cy.viewport(375, 800)
    studios()

    filtersRow().should($row => {
      const cs = window.getComputedStyle($row[0])
      expect(cs.overflowX).to.equal('auto')
      expect(parseFloat(cs.paddingBottom), 'the scrollbar gap is still there').to.be.greaterThan(0)
      expect($row[0].scrollWidth, 'and there is somewhere to scroll').to.be.greaterThan(
        $row[0].clientWidth
      )
    })
  })
})
