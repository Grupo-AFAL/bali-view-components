// The column selector hides cells BY INDEX, and three `Bali::Table` rows carry no cell per
// column: the group band (one `td` with `colspan`, preceded by the select-all cell when the
// table is `selectable:`), the empty state (another one covering the whole table) and the
// `tfoot` totals row. The index used to reach them and wipe the wrong cell — the band with the
// fold button inside it, the "no results" message, or the total of the column next to it
// (#1144).
describe('DataTable column selector on a grouped table', () => {
  const grouped = '#grouped-columns'
  const selectable = '#selectable-columns'
  const empty = '#empty-columns'
  const band = 'tr.bali-table-group-row'
  const trigger = `${band} button[data-table-groups-target="trigger"]`
  const rows = 'tbody tr[data-table-groups-target="row"]'

  // `force`: daisyUI's `:focus-within` is what opens the dropdown panel, so the checkbox is not
  // actionable with the menu closed. What matters here is the `change` it fires.
  const hideColumn = (listing, index) =>
    cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="${index}"]`)
      .uncheck({ force: true })

  beforeEach(() => {
    cy.visit('/bali/data_table/with_column_selector')
  })

  it('hides the column without taking the group bands with it', () => {
    cy.get(`${grouped} ${band}`).should('have.length', 3)

    hideColumn(grouped, 0)

    cy.get(`${grouped} thead th`).eq(0).should('not.be.visible')
    cy.get(`${grouped} ${rows}`).first().find('td').eq(0).should('not.be.visible')

    // The band is untouched: its cell spans all four columns, so index 0 does not name it.
    cy.get(`${grouped} ${band}`).should('have.length', 3).each(($row) => {
      cy.wrap($row).find('td').should('be.visible')
    })
    cy.get(`${grouped} ${trigger}`).should('have.length', 3).and('be.visible')
  })

  // The serious case: with the band folded, its button is the ONLY thing that can bring those
  // rows back. Hiding it left them unreachable without a page reload.
  it('keeps the band that is born folded expandable', () => {
    hideColumn(grouped, 0)

    cy.get(`${grouped} ${trigger}[aria-expanded="false"]`).should('have.length', 1).then(($trigger) => {
      const groupRows = `${grouped} ${rows}[data-group-token="${$trigger.attr('data-group-token')}"]`

      cy.get(groupRows).should('have.length', 2).and('not.be.visible')

      cy.wrap($trigger).click()
      cy.wrap($trigger).should('have.attr', 'aria-expanded', 'true')
      cy.get(groupRows).should('be.visible')
    })
  })

  // `selectable: true` + groups is the hosts' composition (gobierno-corporativo). The band then
  // carries TWO cells — the group's select-all and the band itself — and the index that lands on
  // the band is 1, not 0: the data columns start after the selection column, which is also a
  // `thead th`.
  it('hides the right column when the table is selectable', () => {
    cy.get(`${selectable} ${band}`).should('have.length', 3)
    cy.get(`${selectable} ${band}`).first().find('td').should('have.length', 2)

    hideColumn(selectable, 1)

    // Index 1 = "Initiative", not the selection column.
    cy.get(`${selectable} thead th`).eq(0).should('be.visible')
    cy.get(`${selectable} thead th`).eq(1).should('not.be.visible')
    cy.get(`${selectable} ${rows}`).first().find('td').eq(0).should('be.visible')
    cy.get(`${selectable} ${rows}`).first().find('td').eq(1).should('not.be.visible')

    // The band's two cells are still there: the select-all one (column 0, which nobody hid) and
    // the band itself, which spans the four data columns.
    cy.get(`${selectable} ${band}`).each(($row) => {
      cy.wrap($row).find('td').should('have.length', 2).and('be.visible')
    })
    cy.get(`${selectable} ${trigger}`).should('have.length', 3).and('be.visible')
    cy.get(`${selectable} ${band} input[type="checkbox"]`).should('have.length', 3).and('be.visible')
  })

  // The `tfoot` totals row is the other row with `colspan`, and the selector walks it on its own.
  // Its first cell spans two columns, so the "Leader" summary (index 2) is the SECOND cell: by
  // raw index it used to hide the one next to it.
  it('hides the tfoot cell that belongs to the column', () => {
    cy.get(`${grouped} tfoot td`).should('have.length', 3)

    hideColumn(grouped, 2)

    cy.get(`${grouped} thead th`).eq(2).should('not.be.visible')
    cy.get(`${grouped} tfoot td`).eq(0).should('be.visible').and('contain', 'iniciativas')
    cy.get(`${grouped} tfoot td`).eq(1).should('not.be.visible')
    cy.get(`${grouped} tfoot td`).eq(2).should('be.visible').and('contain', 'cuadrantes')
  })

  // And the `colspan` cell of that same `tfoot` does not go with any of the columns it spans.
  it('does not remove the tfoot cell with colspan', () => {
    hideColumn(grouped, 0)

    cy.get(`${grouped} tfoot td`).eq(0).should('be.visible').and('contain', 'iniciativas')
    cy.get(`${grouped} tfoot td`).eq(1).should('be.visible')
    cy.get(`${grouped} tfoot td`).eq(2).should('be.visible')
  })

  // The preview's last listing has no rows. Its `<tr>` carries no class of its own, so a per-row
  // guard (`tr:not(.bali-table-group-row)`) would have left it broken all the same.
  it('does not remove the empty state of a listing with no results', () => {
    hideColumn(empty, 0)

    cy.get(`${empty} thead th`).eq(0).should('not.be.visible')
    cy.get(`${empty} td.empty-table`).should('be.visible').and('not.have.text', '')
  })
})
