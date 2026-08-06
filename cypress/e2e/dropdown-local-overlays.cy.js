// `with_item(modal: { id:, local: true })` opens an overlay that is already rendered on
// the page — `modal#openLocal` dispatches the open event BY NAME and with no content, so
// the dialog keeps what the server rendered and nothing is fetched. The preview carries a
// second, decoy modal on purpose: the regression this file guards is #854, where an open
// event naming no overlay was answered by every overlay on the page, and the one nobody
// closed stayed `showModal()`-ed with the whole document inert behind it.
describe('Dropdown local overlay items', () => {
  const inTopLayer = win =>
    Array.from(win.document.querySelectorAll('dialog'))
      .filter(d => d.matches(':modal'))
      .map(d => d.id || '(anon)')

  beforeEach(() => {
    cy.visit('/bali/actions_dropdown/local_overlays')
  })

  const openMenu = () => cy.get('.dropdown [role="button"]').first().click()

  it('opens only the modal the item names, with its server-rendered content', () => {
    openMenu()
    cy.get('[data-modal-id="health-modal"]').click()

    cy.get('#health-modal').should('have.class', 'modal-open')
    cy.get('#health-modal').should('contain.text', 'Server-rendered content')
    cy.get('#decoy-modal').should('not.have.class', 'modal-open')
    cy.window().then(win => {
      // `:modal` and not class names: the class can be absent while the dialog still
      // holds the top layer, which is exactly the state that makes the page inert.
      expect(inTopLayer(win)).to.deep.equal(['health-modal'])
    })
  })

  it('closes with Escape and leaves nothing in the top layer', () => {
    openMenu()
    cy.get('[data-modal-id="health-modal"]').click()
    cy.get('#health-modal').should('have.class', 'modal-open')

    cy.get('body').type('{esc}')

    cy.get('#health-modal').should('not.have.class', 'modal-open')
    cy.window().should(win => {
      expect(inTopLayer(win)).to.deep.equal([])
    })

    // The page is interactive again: the menu opens a second time.
    openMenu()
    cy.get('[data-modal-id="health-modal"]').should('be.visible')
  })

  it('opens a local drawer by name the same way', () => {
    openMenu()
    cy.get('[data-drawer-id="notes-drawer"]').click()

    cy.get('#notes-drawer').should('have.class', 'drawer-open')
    cy.get('#notes-drawer').should('contain.text', 'Server-rendered drawer content')
    cy.window().then(win => {
      expect(inTopLayer(win)).to.deep.equal(['notes-drawer'])
    })
  })

  it('renders the POST item as a real form, out of the box tree', () => {
    openMenu()
    // `display: contents` takes the <form> out of the box tree; the button is the item.
    cy.get('li > form.contents').should('exist')
    cy.get('form.contents > button[type="submit"]').should('contain.text', 'Approve')
  })
})
