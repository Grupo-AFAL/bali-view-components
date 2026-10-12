// #1375: the single-file name and the default text reached the page through `innerHTML` unescaped,
// and a file name may contain `<` and `>`. Each has to come out as the text it is.
describe('FileInput writes names as text', () => {
  const MARKUP = '<img src=x onerror="window.injected = true">'
  const value = () => cy.get('[data-file-input-target="value"]')

  const pickFile = name =>
    cy.get('input[type="file"]').selectFile(
      { contents: Cypress.Buffer.from('x'), fileName: name, mimeType: 'application/pdf' },
      { force: true } // the native input is invisible by design
    )

  const expectText = (text) => {
    value().should('contain.text', text)
    value().find('img').should('not.exist')
  }

  it('writes a single file name as text', () => {
    cy.visit('/bali/form/file/default')
    pickFile(`${MARKUP}.pdf`)
    expectText(`${MARKUP}.pdf`)
  })

  // A host's `non_selected_text:` — or a translation — written back once the last file is removed.
  it('writes the default text as text', () => {
    cy.visit('/bali/form/file/multiple')
    cy.get('[data-controller~="file-input"]')
      .invoke('attr', 'data-file-input-non-selected-text-value', `${MARKUP}none`)
    pickFile('contract.pdf')
    cy.get('[data-action="file-input#removeFile"]').click()
    expectText(`${MARKUP}none`)
  })

  // The guard, not a cover: the list `multiple: true` draws escaped its names before #1375 too.
  it('keeps listing several files with their names as text', () => {
    cy.visit('/bali/form/file/multiple')
    pickFile(`${MARKUP}.pdf`)
    expectText(`${MARKUP}.pdf`)
    cy.get('[data-action="file-input#removeFile"]').should('have.length', 1)
  })
})
