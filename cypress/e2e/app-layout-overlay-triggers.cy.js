// #1268 — a `drawer: true` / `modal: true` trigger needs the `drawer` / `modal` controller
// on an ancestor, and two places on an AppLayout page are outside <main>: the chrome slots,
// and the menu of a `popover: true` dropdown, which tippy moves to the end of <body> when it
// opens. With no controller above it Stimulus binds nothing, and the link (`data-turbo="false"`)
// navigates the whole page to its href. Lookbook's own layout puts both controllers on
// <body>, which is why only a preview under `app_layout_preview` shows it.
const PREVIEW = '/bali/app_layout/overlay_triggers'
const popover = '[data-dropdown-popover-value="true"]'

// One callback, so the page that navigated away fails on the path rather than on a missing
// panel, and a panel that never opened cannot pass on the path alone.
const expectOpenOnThePreview = (panelId, text) => {
  cy.document().should((doc) => {
    expect(doc.location.pathname, 'still on the preview').to.include(PREVIEW)
    const panel = doc.getElementById(panelId)
    expect(panel && panel.matches(':modal'), `#${panelId} is open`).to.equal(true)
    expect(panel.textContent, 'the fetched content').to.include(text)
  })
}

describe('AppLayout overlay triggers outside <main> (#1268)', () => {
  beforeEach(() => {
    cy.visit(PREVIEW)
    // tippy is a dynamic import; the menu leaves the wrapper once it resolves.
    cy.get(`${popover} [data-dropdown-target="menu"]`).should('not.exist')
  })

  const clickMenuItem = (name) => {
    cy.get(`${popover} [data-dropdown-target="trigger"]`).click()
    cy.get('[data-tippy-root]').contains('a', name).as('item')
    cy.get('@item').should(($a) => expect($a[0].closest('main'), 'the item is outside <main>').to.equal(null))
    cy.get('@item').click()
  }

  it('a drawer: true item in a popover menu opens the shared drawer', () => {
    clickMenuItem('Open in drawer')

    expectOpenOnThePreview('main-drawer', 'John Doe')
  })

  it('a modal: true item in a popover menu opens the shared modal', () => {
    clickMenuItem('Open in modal')

    expectOpenOnThePreview('main-modal', 'Welcome!')
  })

  it('a drawer: true trigger in the topbar slot opens the shared drawer', () => {
    cy.get('[data-testid="topbar-drawer-trigger"]')
      .should(($a) => expect($a[0].closest('main'), 'the trigger is outside <main>').to.equal(null))
      .click()

    expectOpenOnThePreview('main-drawer', 'John Doe')
  })
})
