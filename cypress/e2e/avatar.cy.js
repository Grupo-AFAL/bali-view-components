import { paintedContrast } from '../support/painted_contrast'
import { eachTheme } from '../support/themes'

// #1041 — Avatar had no E2E spec. The component is mostly Ruby, but
// `Avatar::Upload` ships a controller with one job: show the file the user just
// picked, in the frame where the saved one is. The file input lives inside the
// camera <label>, invisible, so nothing about that path is visible from the
// markup alone.
describe('Avatar upload', () => {
  const NON_TEXT = 3
  const picture = () => cy.get('[data-avatar-target="output"]')
  const input = () => cy.get('[data-avatar-target="input"]')

  beforeEach(() => {
    cy.visit('/bali/avatar/with_upload', {
      onBeforeLoad (win) {
        cy.spy(win.URL, 'revokeObjectURL').as('revoke')
      }
    })
  })

  it('starts from the saved image', () => {
    picture().invoke('attr', 'src').should('include', 'avatar')
  })

  it('previews the chosen file in place', () => {
    // `force`: the input is deliberately invisible over the camera button.
    input().selectFile('cypress/fixtures/sample-image.png', { force: true })

    picture().invoke('attr', 'src').should('match', /^blob:/)
    // A portrait or landscape photo in a circular frame is distorted without it.
    picture().should('have.css', 'object-fit', 'cover')
  })

  it('releases the previous blob when a second file is chosen', () => {
    input().selectFile('cypress/fixtures/sample-image.png', { force: true })

    picture().invoke('attr', 'src').then((firstBlob) => {
      input().selectFile('cypress/fixtures/sample-image.png', { force: true })

      picture().invoke('attr', 'src').should('not.eq', firstBlob)
      cy.get('@revoke').should('have.been.calledOnceWith', firstBlob)
    })
  })

  // Turbo's snapshot for Back still points at the blob, so it is never revoked on disconnect; the
  // controller that connects to the snapshot owns it, and the next pick releases it.
  it('still shows the chosen file after a Turbo visit and Back, and releases it on the next pick', () => {
    input().selectFile('cypress/fixtures/sample-image.png', { force: true })
    picture().invoke('attr', 'src').should('match', /^blob:/)

    cy.window().then((win) => win.Turbo.visit('/lookbook/preview/bali/avatar/default'))
    cy.location('pathname').should('include', '/avatar/default')
    cy.go('back')
    cy.location('pathname').should('include', '/avatar/with_upload')

    picture().should(($img) => {
      expect($img.attr('src'), 'the restored picture').to.match(/^blob:/)
      expect($img[0].complete, 'image settled').to.equal(true)
      expect($img[0].naturalWidth, 'the restored picture loads').to.be.greaterThan(0)
    })

    picture().invoke('attr', 'src').then((restored) => {
      input().selectFile('cypress/fixtures/sample-image.png', { force: true })

      picture().invoke('attr', 'src').should('not.eq', restored)
      cy.get('@revoke').should('have.been.calledWith', restored)
    })
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

  // #1409: the input sat in a `div.hidden`, so Tab never reached it. That Enter and Space then
  // open the picker is measured in the PR — Cypress cannot observe the browser's file dialog.
  it('is reached by Tab', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    cy.document().should((doc) => {
      expect(doc.activeElement.matches('[data-avatar-target="input"]'), 'focus on the file input').to.equal(true)
    })
  })

  // The input is invisible, so the ring has to be the button's.
  it('rings the button while the input has keyboard focus, every theme', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    eachTheme((theme) => {
      cy.document().should((doc) => {
        const button = doc.querySelector('[data-avatar-target="input"]').closest('label').parentElement
        expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
        expect(getComputedStyle(button).outlineStyle, `${theme}: ring drawn`).to.equal('solid')
        expect(paintedContrast(button, { over: button.parentElement, property: 'outlineColor' }), theme)
          .to.be.at.least(NON_TEXT)
      })
    })
  })
})
