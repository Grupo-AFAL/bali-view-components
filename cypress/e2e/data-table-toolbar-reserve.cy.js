// The toolbar the server sends is, by definition, the row with NOTHING collapsed: nobody can
// collapse it until the controller exists. Measured on /admin/studios, the page paints at
// 260ms and `connect()` does not run until 1189ms —how long it takes to execute a bundle of
// 4.8 MB—, so for a second four controls were visible and then disappeared all at once into
// the ⋯.
//
// Now the collapsibles arrive with their space RESERVED and unpainted, and the controller
// uncovers them when its first `apply()` finishes. `visibility: hidden` and not
// `display: none`: the box is kept, so the measurement that decides the collapse measures
// the same as it would without this.
//
// On why the page is /admin/studios and not a preview, see
// data-table-toolbar-alignment.cy.js.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const url = `${appOrigin}/admin/studios`

const ATTRIBUTE = 'data-toolbar-overflow-settling'
const toolbar = () => cy.get('[data-controller~="toolbar-overflow"]')

describe('DataTable: the toolbar reserves the space for what can collapse', () => {
  // On the raw HTML, which is what the browser paints before executing anything. No
  // timing: what is checked is the server's contract, not a race.
  it('sends it reserved from the server', () => {
    cy.request(url).its('body').then(html => {
      expect(html, 'the row is marked').to.include(ATTRIBUTE)
      // The `&` of the arbitrary variant comes out escaped in the attribute, so the search
      // is for the stretch that does not carry it.
      expect(html, 'and the utility that hides it').to.include(
        `[[${ATTRIBUTE}]_`
      )
      expect(html, 'with the way out for whoever does not run scripts').to.include('<noscript>')
    })
  })

  it('uncovers all of it once the controller has run', () => {
    cy.viewport(1900, 1000)
    cy.visit(url)
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')

    toolbar().should('not.have.attr', ATTRIBUTE)
    cy.get('[data-toolbar-overflow-target="item"]').each($item => {
      expect(window.getComputedStyle($item[0]).visibility, 'no control is left hidden')
        .to.equal('visible')
    })
  })

  // What separates this fix from a `display: none` that would break the measurement. It is
  // tested by putting the attribute back, because the real state lasts as long as the bundle
  // takes.
  it('reserves the box instead of taking it out of the layout', () => {
    cy.viewport(2600, 1000)
    cy.visit(url)
    cy.get('[data-controller~="toolbar-overflow"]').should('exist')
    // At this width the row fits whole, so the collapsibles stay in it.
    cy.get('[data-toolbar-overflow-target="menu"]').should($menu => {
      expect($menu[0].children.length, 'nothing collapsed at this width').to.equal(0)
    })

    cy.get('[data-toolbar-overflow-priority="30"]').then($item => {
      const before = Math.round($item[0].getBoundingClientRect().width)
      expect(before, 'the control measures something to begin with').to.be.greaterThan(0)

      cy.get('[data-controller~="toolbar-overflow"]').invoke('attr', ATTRIBUTE, '')
      cy.get('[data-toolbar-overflow-priority="30"]').should($other => {
        expect(window.getComputedStyle($other[0]).visibility).to.equal('hidden')
        expect(Math.round($other[0].getBoundingClientRect().width), 'and it keeps its box')
          .to.equal(before)
      })
    })
  })
})
