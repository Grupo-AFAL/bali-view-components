// #1041 — ImageField had no E2E spec. Everything it does happens between the
// file picker and the form submit: the preview the user sees is a blob URL the
// controller creates, and the "clear" it offers has to put back the placeholder
// AND empty the input, or the file the user just removed is still uploaded.
import { paintedContrast } from '../support/painted_contrast'
import { eachTheme } from '../support/themes'

describe('ImageField', () => {
  const NON_TEXT = 3
  const output = () => cy.get('[data-image-field-target="output"]')
  const input = () => cy.get('[data-image-field-target="input"]')
  // The input is invisible over the overlay and the clear button until hover or keyboard
  // focus, and a Cypress hover is not a real one — the click is what is being tested.
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

  // Turbo restores Back from a snapshot taken before the controller disconnects, so that snapshot
  // still points at the blob: revoked on disconnect, it came back as a broken image with the
  // file still on the input.
  it('still shows the chosen file after a Turbo visit and Back', () => {
    input().selectFile('cypress/fixtures/sample-image.png', force)
    output().invoke('attr', 'src').should('match', /^blob:/)

    cy.window().then((win) => win.Turbo.visit('/lookbook/preview/bali/image_field/default'))
    cy.location('pathname').should('include', '/image_field/default')
    cy.go('back')
    cy.location('pathname').should('include', '/image_field/with_input')

    output().should(($img) => {
      expect($img.attr('src'), 'the restored preview').to.match(/^blob:/)
      expect($img[0].complete, 'image settled').to.equal(true)
      expect($img[0].naturalWidth, 'the restored preview loads').to.be.greaterThan(0)
    })
  })

  it('keeps working with a clear button supplied by the host', () => {
    cy.visit('/bali/image_field/with_custom_clear_button')

    input().selectFile('cypress/fixtures/sample-image.png', force)
    output().invoke('attr', 'src').should('match', /^blob:/)

    cy.get('[aria-label="Delete image"]').click(force)

    output().invoke('attr', 'src').should('match', /^data:image\/svg/)
    input().should('have.value', '')
  })

  // #1409: the input was `hidden`, so Tab never reached it. That Enter and Space then open the
  // picker is measured in the PR — Cypress cannot observe the browser's file dialog.
  it('is reached by Tab', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    cy.document().should((doc) => {
      expect(doc.activeElement.matches('[data-image-field-target="input"]'), 'focus on the file input').to.equal(true)
    })
  })

  // The input is invisible, so the ring has to be the overlay's, around the image.
  it('rings the image while the input has keyboard focus, every theme', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    eachTheme((theme) => {
      cy.document().should((doc) => {
        const overlay = doc.querySelector('[data-image-field-target="input"]').closest('label')
        expect(getComputedStyle(overlay).outlineStyle, `${theme}: ring drawn`).to.equal('solid')
        expect(paintedContrast(overlay, { over: overlay.parentElement, property: 'outlineColor' }), theme)
          .to.be.at.least(NON_TEXT)
      })
    })
  })

  // The clear button was `display: none` until hover, so Tab went past it.
  it('reaches the clear button by Tab and clears with Enter', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    input().selectFile('cypress/fixtures/sample-image.png', force)
    output().invoke('attr', 'src').should('match', /^blob:/)

    cy.press(Cypress.Keyboard.Keys.TAB)
    cy.document().should((doc) => {
      expect(doc.activeElement.matches('[data-action="image-field#clear"]'), 'focus on the clear button').to.equal(true)
    })
    cy.focused().type('{enter}')

    output().invoke('attr', 'src').should('match', /^data:image\/svg/)
    input().should('have.value', '')
  })
})
