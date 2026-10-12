import { paintedContrast } from '../support/painted_contrast'
import { eachTheme } from '../support/themes'

// #1385: the native input was `display: none`, so Tab never reached it and nothing on the page
// could open the file picker without a mouse. That Enter and Space then open it is measured in the
// PR — Cypress cannot observe the browser's file dialog.
describe('FileField from the keyboard', () => {
  const NON_TEXT = 3
  const input = () => cy.get('[data-controller~="file-input"] input[type="file"]')
  const cta = () => cy.get('[data-controller~="file-input"] label .btn')

  beforeEach(() => {
    cy.visit('/bali/form/file/default')
    input().should('have.attr', 'data-action', 'file-input#onChange')
  })

  it('is reached by Tab', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    cy.document().should((doc) => {
      expect(doc.activeElement.matches('input[type="file"]'), 'focus on the file input').to.equal(true)
    })
  })

  // The input is invisible, so the ring has to be the button's: daisyUI's `.btn:has(:focus-visible)`.
  it('rings the button while the input has keyboard focus, every theme', () => {
    cy.press(Cypress.Keyboard.Keys.TAB)
    eachTheme((theme) => {
      cy.document().should((doc) => {
        const button = doc.querySelector('[data-controller~="file-input"] label .btn')
        expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
        expect(getComputedStyle(button).outlineStyle, `${theme}: ring drawn`).to.equal('solid')
        expect(paintedContrast(button, { over: button.parentElement, property: 'outlineColor' }), theme)
          .to.be.at.least(NON_TEXT)
      })
    })
  })

  // `required` reaches the input now (#1125 dropped it while the input was `display: none`). The
  // browser anchors its message to the box of the control it focuses: on the 1px `sr-only` box
  // Chrome showed nothing, over the button it points at the button.
  it('reports a missing required file on the button', () => {
    input().should('have.attr', 'required')
    cy.get('form').then(($form) => {
      expect($form[0].reportValidity(), 'form is invalid').to.equal(false)
    })
    cy.document().should((doc) => {
      expect(doc.activeElement.matches('input[type="file"]'), 'focus on the file input').to.equal(true)
    })
    input().then(($input) => {
      cta().then(($cta) => {
        const box = $input[0].getBoundingClientRect()
        const button = $cta[0].getBoundingClientRect()
        // The input fills the button's padding box, 1px of border inside it on each side.
        expect(box.width, 'input width').to.be.closeTo(button.width, 2)
        expect(box.height, 'input height').to.be.closeTo(button.height, 2)
      })
    })
  })
})
