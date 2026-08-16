// #1041 — ImageField had no E2E spec. Everything it does happens between the
// file picker and the form submit: the preview the user sees is a blob URL the
// controller creates, and the "clear" it offers has to put back the placeholder
// AND empty the input, or the file the user just removed is still uploaded.
describe('ImageField', () => {
  const output = () => cy.get('[data-image-field-target="output"]')
  const input = () => cy.get('[data-image-field-target="input"]')
  // The input and the clear button only show on hover (`hidden group-hover:flex`),
  // and a Cypress hover is not a real one — the click is what is being tested.
  const force = { force: true }

  beforeEach(() => {
    cy.visit('/bali/image_field/with_input', {
      onBeforeLoad (win) {
        cy.spy(win.URL, 'revokeObjectURL').as('revoke')
      }
    })
  })

  it('shows the chosen file without leaving the page', () => {
    output().invoke('attr', 'src').should('match', /^data:image\/svg/)

    input().selectFile('cypress/fixtures/sample-image.png', force)

    output().invoke('attr', 'src').should('match', /^blob:/)
    // Without this the preview is letterboxed inside the square frame.
    output().should('have.css', 'object-fit', 'cover')
    cy.location('pathname').should('include', '/bali/image_field/with_input')
  })

  it('releases the previous blob when a second file is chosen', () => {
    input().selectFile('cypress/fixtures/sample-image.png', force)

    output().invoke('attr', 'src').then((firstBlob) => {
      input().selectFile('cypress/fixtures/sample-image.png', force)

      output().invoke('attr', 'src').should('not.eq', firstBlob)
      cy.get('@revoke').should('have.been.calledWith', firstBlob)
    })
  })

  it('clears back to the placeholder and empties the input', () => {
    input().selectFile('cypress/fixtures/sample-image.png', force)
    output().invoke('attr', 'src').should('match', /^blob:/)

    cy.get('[data-image-field-target="placeholder"]').invoke('attr', 'src').then((placeholder) => {
      cy.get('[data-action="image-field#clear"]').click(force)

      output().should('have.attr', 'src', placeholder)
    })

    // The half that is easy to forget: an input still holding the file would
    // upload it anyway on the next submit.
    input().should('have.value', '')
    cy.get('@revoke').should('have.been.called')
  })

  it('keeps working with a clear button supplied by the host', () => {
    cy.visit('/bali/image_field/with_custom_clear_button')

    input().selectFile('cypress/fixtures/sample-image.png', force)
    output().invoke('attr', 'src').should('match', /^blob:/)

    cy.get('[aria-label="Delete image"]').click(force)

    output().invoke('attr', 'src').should('match', /^data:image\/svg/)
    input().should('have.value', '')
  })
})
