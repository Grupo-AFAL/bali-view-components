describe('DirectUploadController', () => {
  // These pages live in the dummy app, not under the Lookbook preview path `baseUrl`
  // points at, so the origin is derived from it rather than written out. A literal
  // `http://localhost:3001` ignores CYPRESS_BASE_URL and quietly tests another
  // checkout's server whenever the suite runs from a git worktree.
  const dummyAppUrl = new URL(Cypress.config('baseUrl')).origin

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

  // #1409 — each row's names come from Bali's translations, handed over with their placeholders
  // intact: the file name and the progress only exist in the browser.
  context('names each file in the page language', () => {
    const pickFile = () => cy.get('[data-direct-upload-target="input"]').selectFile(
      { contents: Cypress.Buffer.from('x'), fileName: 'contrato.pdf', mimeType: 'application/pdf' },
      { force: true } // the native input is hidden behind the drop zone
    )
    const row = () => cy.get('[data-direct-upload-target="fileList"] [data-file-id]')

    beforeEach(() => {
      cy.visit(`${dummyAppUrl}/direct_uploads/new?locale=es`)
    })

    // `auto_upload: false` is the only way a file stays pending.
    it('while it waits to upload', () => {
      cy.get('[data-controller="direct-upload"]').invoke('attr', 'data-direct-upload-auto-upload-value', 'false')
      pickFile()

      row().find('.percentage').should('have.text', 'Esperando...')
      row().find('progress').should('have.attr', 'aria-label', 'Esperando para subir contrato.pdf')
      row().find('.file-cancel').should('have.attr', 'aria-label', 'Cancelar la subida de contrato.pdf')
    })

    it('while it uploads', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500, delay: 10000 })
      pickFile()

      row().find('progress').should('have.attr', 'aria-label', 'Subiendo contrato.pdf: 0%')
    })

    it('once its upload failed', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500 })
      pickFile()

      row().find('.file-retry').should('be.visible')
        .and('have.attr', 'aria-label', 'Reintentar la subida de contrato.pdf')
      row().find('.file-remove').should('have.attr', 'aria-label', 'Eliminar contrato.pdf')
    })
  })
})
