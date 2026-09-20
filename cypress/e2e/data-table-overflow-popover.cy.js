// The ⋯ is a popover: opening one of its children cannot change its size. It did, because
// the menu container forced `position: static` on every `.dropdown-content` inside it,
// a decision taken back when the ⋯ WAS the mobile mode. Since #842 the valve trips at
// any width, so that rule applied on desktop too: measured on /admin/studios at 1900px,
// the ⋯ panel went from 320x176 to 320x338 when Views was opened.
//
// On why the page is /admin/studios and not a preview, see
// data-table-toolbar-alignment.cy.js.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const studios = () => cy.visit(`${appOrigin}/admin/studios`)

const overflowTrigger = () => cy.get('[data-toolbar-overflow-target="overflow"] .btn').first()
const firstChild = () =>
  cy.get('[data-toolbar-overflow-target="menu"] .dropdown').first().find('.btn').first()
const childContent = () =>
  cy.get('[data-toolbar-overflow-target="menu"] .dropdown .dropdown-content').first()

const box = el => {
  const b = el.getBoundingClientRect()
  return { w: Math.round(b.width), h: Math.round(b.height) }
}

describe('DataTable: the ⋯ popover', () => {
  it('does not change size when one of its children is opened', () => {
    cy.viewport(1900, 1000)
    studios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    overflowTrigger().click()
    cy.get('[data-toolbar-overflow-target="menu"]').should('be.visible')

    cy.get('[data-toolbar-overflow-target="menu"]').then($menu => {
      const panel = $menu[0].closest('.dropdown-content')
      const before = box(panel)

      firstChild().click()
      childContent()
        .should('be.visible')
        .then($sub => {
          expect(window.getComputedStyle($sub[0]).position, 'the child floats').to.equal('absolute')
          expect(box(panel), 'and the container did not move').to.deep.equal(before)
        })
    })
  })

  // #1080: floating is not enough, it has to float ABOVE the content band. The ⋯ panel
  // has its own stacking context (absolute + z-index), so an absolute child inside it
  // paints above the table — unless an ancestor with `overflow` CLIPS it, which is what
  // the menu container's `overflow-y-auto` did. Clipped, only an edge of the panel showed
  // and `elementFromPoint` at its center returned a `<td>`: the control was unusable at
  // exactly the widths where the ⋯ is the only way out. Measured with hit-testing and not
  // with classes because the symptom is one of painting.
  it('keeps the child panel clickable above the table', () => {
    cy.viewport(1440, 900)
    studios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    overflowTrigger().click()
    firstChild().click()

    childContent()
      .should('be.visible')
      .then($sub => {
        const panel = $sub[0]
        const b = panel.getBoundingClientRect()
        const points = [
          ['at the top', b.top + 4],
          ['in the middle', b.top + b.height / 2],
          ['at the bottom', b.bottom - 4]
        ]

        points.forEach(([where, y]) => {
          const topmost = panel.ownerDocument.elementFromPoint(b.left + b.width / 2, y)
          expect(panel.contains(topmost), `${where} the panel receives the click`).to.equal(true)
        })
      })
  })

  // On a phone stacking in flow is still the sensible thing, and it is the reason the rule
  // exists: nested and absolute children position against the container and leave the
  // viewport (measured: left -115px at 375px).
  it('keeps the children stacked in flow on a phone, without overflowing', () => {
    cy.viewport(375, 800)
    studios()
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')
    overflowTrigger().click()
    firstChild().click()

    childContent().should($sub => {
      expect(window.getComputedStyle($sub[0]).position).to.equal('static')

      const b = $sub[0].getBoundingClientRect()
      expect(b.left, 'does not overflow on the left').to.be.at.least(0)
      expect(b.right, 'nor on the right').to.be.at.most(375)
    })
  })
})
