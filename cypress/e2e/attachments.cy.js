// What the list promises a host and only a browser sees: the stream that removes the last file
// brings up the empty text (`hidden only:block`), and a long name truncates inside its chip.
describe('Attachments', () => {
  const items = () => cy.get('.attachments-component > li[id^="attachment_"]')
  const emptyText = () => cy.get('.attachments-component > .attachments-empty')
  const remove = target => cy.window().then(win => {
    win.Turbo.renderStreamMessage(`<turbo-stream action="remove" target="${target}"></turbo-stream>`)
  })

  beforeEach(() => cy.visit('/bali/attachments/default'))

  it('shows the empty text once a stream removes the last file', () => {
    emptyText().should('not.be.visible')

    items().then($items => [...$items].forEach(item => remove(item.id)))

    items().should('not.exist')
    emptyText().should('be.visible').and('contain.text', 'No attachments')
  })

  it('truncates a long name inside a chip no wider than 16rem, at phone width', () => {
    cy.viewport(375, 800)

    cy.contains('.attachments-component a.btn', 'Q3 budget').should(($chip) => {
      expect($chip[0].getBoundingClientRect().width).to.be.at.most(256)
      const name = $chip[0].querySelector('.truncate')
      expect(name.scrollWidth, 'the name overflows its box').to.be.greaterThan(name.clientWidth)
    })
  })
})
