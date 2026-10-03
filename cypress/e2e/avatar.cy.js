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

  // The button sits on the picture's corner, so its tint has to be painted over something
  // opaque: straight on the picture, the photo showed through it.
  it('paints the upload button opaque over the picture', () => {
    cy.get('label:has([data-avatar-target="input"])').should(($label) => {
      const doc = $label[0].ownerDocument
      const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 }).getContext('2d')
      ctx.fillStyle = doc.defaultView.getComputedStyle($label[0].parentElement).backgroundColor
      ctx.fillRect(0, 0, 1, 1)
      expect(ctx.getImageData(0, 0, 1, 1).data[3], 'alpha of the fill under the tint').to.equal(255)
    })
  })
})
