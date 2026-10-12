// #1409 — the remove button is named by Bali's `file_input.remove`, which the FormBuilder writes on
// the field with its `%{name}` intact: the file name only exists in the browser.
describe('FileInput remove button', () => {
  it('is named in the page language', () => {
    cy.visit('/bali/form/file/multiple?locale=es')
    cy.get('input[type="file"]').selectFile(
      { contents: Cypress.Buffer.from('x'), fileName: 'contrato $&.pdf', mimeType: 'application/pdf' },
      { force: true } // the native input is invisible by design
    )

    // `$&` is what String#replace reads as "the match" when handed a string.
    cy.get('[data-action="file-input#removeFile"]')
      .should('have.attr', 'aria-label', 'Eliminar contrato $&.pdf')
  })
})
