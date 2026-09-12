// #1041 — Avatar had no E2E spec. The component is mostly Ruby, but
// `Avatar::Upload` ships a controller with one job: show the file the user just
// picked, in the frame where the saved one is. The file input lives inside a
// <label> and is `hidden`, so nothing about that path is visible from the
// markup alone.
describe('Avatar upload', () => {
  const picture = () => cy.get('[data-avatar-target="output"]')
  const input = () => cy.get('[data-avatar-target="input"]')

  beforeEach(() => {
    cy.visit('/bali/avatar/with_upload')
  })

  it('starts from the saved image', () => {
    picture().invoke('attr', 'src').should('include', 'avatar')
  })

  it('previews the chosen file in place', () => {
    // `force`: the input is deliberately hidden behind the camera label.
    input().selectFile('cypress/fixtures/sample-image.png', { force: true })

    picture().invoke('attr', 'src').should('match', /^blob:/)
    // A portrait or landscape photo in a circular frame is distorted without it.
    picture().should('have.css', 'object-fit', 'cover')
  })

  it('leaves the file on the input for the form to submit', () => {
    input().selectFile('cypress/fixtures/sample-image.png', { force: true })

    // The controller only paints the preview; the upload is still the form's.
    input().should(($input) => {
      expect($input[0].files).to.have.length(1)
      expect($input[0].files[0].name).to.eq('sample-image.png')
    })
    cy.get('form').should('have.attr', 'enctype', 'multipart/form-data')
  })
})
