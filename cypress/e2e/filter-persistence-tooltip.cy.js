// The bookmark that remembers filters is the last control of a DataTable toolbar with nothing
// else declared after it. Its tooltip used to be daisyUI's: a `::before` laid out under the
// button even while hidden, so with the button at the row's edge that invisible box pushed
// past the scroll container — measured on this preview at 812px, the page scrolled to 901
// with nothing visible past 812 (#1392). It is a Bali::Tooltip now, which only exists while
// open; these pin that, and that the balloon still follows the state.
const preview = '/bali/data_table/with_filter_persistence'
const button = '[data-action="filter-persistence#toggle"]'
const balloon = '[data-tippy-root]'
const storageKey = 'bali_filter_persist_lookbook_data_table_persistence'

const settled = () =>
  cy.get('[data-controller~="toolbar-overflow"]').should('not.have.attr', 'data-toolbar-overflow-settling')

describe('Filter persistence toggle: its tooltip', () => {
  // Where the overflow showed: the narrowest viewport that still keeps the bookmark in the
  // row, found by giving back the row's free space at 1280px. 4px of slack so the ⋯ valve
  // does not trip on a rounding.
  it('adds no horizontal scroll with the bookmark against the toolbar edge', () => {
    cy.viewport(1280, 800)
    cy.visit(preview)
    settled()

    cy.get(button).then($button => {
      const row = $button[0].closest('[data-controller~="toolbar-overflow"]')
      const free = row.getBoundingClientRect().right - $button[0].getBoundingClientRect().right

      cy.viewport(Math.ceil(1280 - free) + 4, 800)
    })

    cy.get(button).should($button => {
      const row = $button[0].closest('[data-controller~="toolbar-overflow"]')
      const menu = row.querySelector('[data-toolbar-overflow-target="menu"]')

      expect(menu.contains($button[0]), 'still in the row, not in the ⋯').to.equal(false)
      expect(row.getBoundingClientRect().right - $button[0].getBoundingClientRect().right,
        'against the edge').to.be.within(0, 8)
    })

    cy.document().should(doc => {
      const { scrollWidth, clientWidth } = doc.documentElement
      expect(scrollWidth, 'the page does not scroll sideways').to.equal(clientWidth)
    })
  })

  // The toolbar's overflow controller re-appends every item when it connects, and the
  // tooltip's connect awaits tippy's import: both connects of the moved node resumed and
  // built a tippy each — two balloons on top of each other.
  it('opens a single balloon with the text of the current state', () => {
    cy.visit(preview)
    settled()

    cy.get(button).focus()
    cy.get(balloon).should('have.length', 1)
      .and('contain', 'Filters are not saved. Click to enable.')
  })

  // The other half of that guard: a node moved AFTER its balloon was built — here, into the ⋯
  // when the row narrows — must build a new one, not keep pointing at the destroyed one.
  it('opens again after the ⋯ takes the bookmark', () => {
    cy.viewport(1280, 800)
    cy.visit(preview)
    settled()
    cy.get(button).focus()
    cy.get(balloon).should('have.length', 1)
    cy.get(button).blur()

    cy.viewport(700, 800)
    cy.get('[data-toolbar-overflow-target="menu"]').find(button).should('exist')
    cy.get('[data-toolbar-overflow-target="overflow"] [aria-label]').first().click()

    cy.get(button).focus()
    cy.get(balloon).should('have.length', 1)
      .and('contain', 'Filters are not saved. Click to enable.')
  })

  // The server renders the state its cookie says; connect() flips it to what this browser
  // stored, and the balloon was built from what the server sent.
  it('follows the state connect() reads from localStorage', () => {
    cy.visit(preview, {
      onBeforeLoad: win => win.localStorage.setItem(storageKey, 'true')
    })
    settled()

    cy.get(button).should('have.attr', 'aria-pressed', 'true').focus()
    cy.get(balloon).should('contain', 'Filters are being saved. Click to disable.')
  })

  // A balloon already built when the state changes. Turbo.visit is stubbed so the page stays.
  it('takes the new text when the bookmark is clicked', () => {
    cy.visit(preview)
    settled()
    cy.window().then(win => { win.Turbo = { visit: cy.stub().as('turboVisit') } })

    cy.get(button).focus()
    cy.get(balloon).should('contain', 'Filters are not saved. Click to enable.')

    cy.get(button).click()
    cy.get('@turboVisit').should('have.been.calledOnce')
    cy.get(button).blur().focus()
    cy.get(balloon).should('contain', 'Filters are being saved. Click to disable.')
  })
})
