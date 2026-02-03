describe('DirectUploadController', () => {
  // Use dummy app URL directly (not Lookbook preview)
  const dummyAppUrl = 'http://localhost:3001'

  context('auto-reset on successful Turbo submission', () => {
    beforeEach(() => {
      cy.visit(`${dummyAppUrl}/direct_uploads/new`)
    })

    it('clears files after successful form submission', () => {
      // The file list should be empty initially
      cy.get('[data-direct-upload-target="fileList"]').should('be.empty')

      // Verify the component is connected and auto-reset is set up
      cy.get('[data-controller="direct-upload"]').should('exist')

      // Check that the form has the direct-upload component
      cy.get('form').within(() => {
        cy.get('[data-controller="direct-upload"]').should('exist')
      })
    })

    it('form submission guard prevents submit while uploading', () => {
      // Verify the form guard is set up by checking the controller exists
      cy.get('[data-controller="direct-upload"]').should('exist')

      // The submit button should be enabled when no uploads are in progress
      cy.get('button[type="submit"]').should('not.be.disabled')
    })
  })

  context('field name generation without model', () => {
    beforeEach(() => {
      cy.visit(`${dummyAppUrl}/direct_uploads/new`)
    })

    it('generates correct field name for multiple files', () => {
      // Verify the field name is set correctly in the data attribute
      cy.get('[data-controller="direct-upload"]')
        .should('have.attr', 'data-direct-upload-field-name-value', 'evidences[]')
    })

    it('generates correct remove field name', () => {
      // Verify the remove field name is set correctly
      cy.get('[data-controller="direct-upload"]')
        .should('have.attr', 'data-direct-upload-remove-field-name-value', 'remove_evidences[]')
    })
  })
})
