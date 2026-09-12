// #1041 — DocumentPage had no E2E spec. Its controller is small but it is the
// only thing standing between the reader and the document: both side panels are
// shown by a Stimulus value, and the toggle in the app bar has to end up
// agreeing with the panel it controls, in both directions.
describe('DocumentPage panels', () => {
  const tocPanel = () => cy.get('[data-document-page-target="tocPanel"]')
  const tocToggle = () => cy.get('[data-document-page-target="tocToggle"]')
  const metadataPanel = () => cy.get('[data-document-page-target="metadataPanel"]')
  const metadataToggle = () => cy.get('[data-document-page-target="metadataToggle"]')

  beforeEach(() => {
    cy.visit('/bali/document_page/with_panels')
  })

  it('starts with both panels open and both toggles pressed', () => {
    tocPanel().should('be.visible')
    tocToggle().should('have.class', 'btn-active')
    metadataPanel().should('be.visible')
    metadataToggle().should('have.class', 'btn-active')
  })

  it('closes and reopens the table of contents', () => {
    tocToggle().click()

    tocPanel().should('not.be.visible')
    tocToggle().should('not.have.class', 'btn-active')

    tocToggle().click()

    tocPanel().should('be.visible')
    tocToggle().should('have.class', 'btn-active')
  })

  it('closes and reopens the metadata panel', () => {
    metadataToggle().click()

    metadataPanel().should('not.be.visible')
    metadataToggle().should('not.have.class', 'btn-active')

    metadataToggle().click()

    metadataPanel().should('be.visible')
    metadataToggle().should('have.class', 'btn-active')
  })

  it('keeps the two panels independent', () => {
    tocToggle().click()

    tocPanel().should('not.be.visible')
    metadataPanel().should('be.visible')
    metadataToggle().should('have.class', 'btn-active')
  })

  it('leaves the document itself alone', () => {
    tocToggle().click()
    metadataToggle().click()

    // Closing the panels widens the reading column; it must not unmount what
    // is in it.
    cy.get('[data-controller="block-editor"]').should('exist')
  })
})
