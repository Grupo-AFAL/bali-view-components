// The two things a chat composer does that a plain form does not. Both go through a real
// submit: the preview posts to a route that answers an empty Turbo Stream, so the page stays
// put and `turbo:submit-end` is dispatched for real — which is the whole point, since Turbo
// dispatches it ON the form and a listener anywhere inside never sees it.
describe('Chat composer', () => {
  const field = () => cy.get('.bali-chat-composer textarea')
  const send = () => cy.get('.bali-chat-composer button[type="submit"]')

  beforeEach(() => {
    cy.visit('/bali/chat/default')
  })

  it('clears the field once the message went through', () => {
    field().type('mensaje por clic')
    send().click()

    field().should('have.value', '')
  })

  it('sends on Enter and clears', () => {
    field().type('mensaje por enter{enter}')

    field().should('have.value', '')
  })

  it('writes a newline on Shift+Enter instead of sending', () => {
    field().type('primer renglón{shift+enter}segundo')

    field().should('have.value', 'primer renglón\nsegundo')
  })

  // A send the server turned down — a rate limit, a validation — leaves the text where it is.
  // Clearing unconditionally throws away what the person would have to type again.
  it('leaves the text alone when the send was rejected', () => {
    field().type('lo que el servidor rechazó')
    cy.get('.bali-chat-composer').closest('form').then($form => {
      $form[0].addEventListener('submit', event => event.preventDefault())
      $form[0].dispatchEvent(new CustomEvent('turbo:submit-end', {
        bubbles: true, detail: { success: false }
      }))
    })

    field().should('have.value', 'lo que el servidor rechazó')
  })

  // The reset does not fire `input`, so a field that sizes itself off the value has to be told.
  it('brings the grown field back down with the clear', () => {
    let empty
    field().then($f => { empty = $f[0].getBoundingClientRect().height })
    field().type('un renglón{shift+enter}otro{shift+enter}otro más{shift+enter}y otro')
    field().should($f => expect($f[0].getBoundingClientRect().height).to.be.greaterThan(empty))

    send().click()

    field().should($f => expect($f[0].getBoundingClientRect().height).to.equal(empty))
  })

  it('puts the caret back in the field', () => {
    field().type('otro mensaje')
    send().click()

    field().should('have.value', '')
    cy.focused().should('match', 'textarea')
  })
})
