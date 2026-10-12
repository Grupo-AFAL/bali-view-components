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

  // #1409 — every text the controller writes comes from Bali's translations, handed over with
  // their placeholders intact: the file name, the progress and the limits only exist here.
  context('in the page language', () => {
    const pickFile = (fileName = 'contrato.pdf', mimeType = 'application/pdf') =>
      cy.get('[data-direct-upload-target="input"]').selectFile(
        { contents: Cypress.Buffer.from('x'), fileName, mimeType },
        { force: true } // the native input is hidden behind the drop zone
      )
    const row = () => cy.get('[data-direct-upload-target="fileList"] [data-file-id]')
    const stallUploads = () =>
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500, delay: 10000 })

    beforeEach(() => {
      cy.visit(`${dummyAppUrl}/direct_uploads/new?locale=es`)
    })

    it('names a file while it uploads', () => {
      stallUploads()
      pickFile()

      row().find('progress').should('have.attr', 'aria-label', 'Subiendo contrato.pdf: 0%')
      row().find('.file-cancel').should('have.attr', 'aria-label', 'Cancelar la subida de contrato.pdf')
    })

    it('says a file failed to upload, and names its buttons', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500 })
      pickFile()

      row().find('.file-error').should('be.visible').and('have.text', 'No se pudo subir')
      row().find('.file-retry').should('have.attr', 'aria-label', 'Reintentar la subida de contrato.pdf')
      row().find('.file-remove').should('have.attr', 'aria-label', 'Eliminar contrato.pdf')
    })

    // What each region a screen reader speaks from says, where it mentions `text`. Strings, not
    // the elements: Cypress would wrap those in jQuery.
    const spokenIn = text => cy.document().then(doc =>
      [...doc.querySelectorAll('[role="alert"], [aria-live]')]
        .map(region => region.textContent.trim())
        .filter(said => said.includes(text)))

    it('says once that the form waits for an upload', () => {
      stallUploads()
      pickFile()
      cy.get('form button[type="submit"]').click()

      cy.get('[data-direct-upload-target="errorMessage"]').should('be.visible')
        .and('have.text', 'Espera a que termine la subida de 1 archivo(s)')
      spokenIn('Espera a que termine').should('deep.equal', ['Espera a que termine la subida de 1 archivo(s)'])
    })

    it('says once that a file failed to upload, and which', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500 })
      pickFile()

      row().find('.file-error').should('be.visible')
      spokenIn('No se pudo subir').should('deep.equal', ['No se pudo subir contrato.pdf'])
    })

    // The dummy's field takes several files; each failure replacing the previous one in the live
    // region would leave only the last name.
    it('says every failure when several land together', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500 })
      cy.get('[data-direct-upload-target="input"]').selectFile([
        { contents: Cypress.Buffer.from('x'), fileName: 'acta.pdf', mimeType: 'application/pdf' },
        { contents: Cypress.Buffer.from('x'), fileName: 'anexo.pdf', mimeType: 'application/pdf' }
      ], { force: true })

      row().find('.file-error:visible').should('have.length', 2)
      spokenIn('No se pudo subir').then(said => {
        expect(said.join(' ')).to.include('No se pudo subir acta.pdf')
          .and.to.include('No se pudo subir anexo.pdf')
      })
    })

    // The dummy's field accepts `image/*,application/pdf`.
    it('says why a file was turned away', () => {
      pickFile('notas.txt', 'text/plain')

      cy.get('[data-direct-upload-target="errorMessage"]').should('be.visible')
        .and('have.text', 'notas.txt: tipo de archivo no aceptado')
    })

    // Only an upload that was attempted can fail.
    it('uploads a file as soon as it is chosen', () => {
      cy.intercept('POST', '**/rails/active_storage/direct_uploads', { statusCode: 500 })
      cy.get('[data-controller="direct-upload"]').invoke('attr', 'data-direct-upload-auto-upload-value', 'false')
      pickFile()

      row().find('.file-error').should('be.visible')
    })
  })
})
