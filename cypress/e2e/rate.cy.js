// #1041 — Rate had no E2E spec and it is the riskiest of the batch: with
// `auto_submit` a click on a star PERSISTS. What travels to the server is not
// the star the user clicked — those radios are named `<attr>_display` and are
// decoration — but the hidden input the controller writes just before asking
// the form to submit. If the two ever drift apart the rating is silently
// dropped, and the page says nothing about it.
describe('Rate', () => {
  const stars = () => cy.get('[data-controller="rate"] input[data-rate]')
  const hiddenInput = () => cy.get('[data-rate-target="input"]')

  describe('auto submit', () => {
    beforeEach(() => {
      // The preview form is a GET to /lookbook, which redirects: stubbing the
      // response keeps the assertion on the request that was actually made.
      cy.intercept(/\/lookbook\?/, { statusCode: 200, body: 'submitted' }).as('submitted')
      cy.visit('/bali/rate/auto_submit')
    })

    it('submits the clicked rating under the model attribute', () => {
      cy.get('[data-rate="5"]').click()

      cy.wait('@submitted').its('request.url').should('include', 'movie%5Brating%5D=5')
    })

    it('sends the last star clicked, not the one the server rendered', () => {
      // The preview renders 3 as checked, so a submit carrying 3 would look
      // right while proving nothing.
      cy.get('[data-rate="1"]').click()

      cy.wait('@submitted').its('request.url').should('include', 'movie%5Brating%5D=1')
    })

    it('writes the value into the hidden input before submitting', () => {
      cy.visit('/bali/rate/auto_submit', {
        onBeforeLoad (win) {
          // Without this the page navigates away mid-assertion and the input
          // that carries the value is gone before it can be read.
          cy.stub(win.HTMLFormElement.prototype, 'requestSubmit').as('requestSubmit')
        }
      })

      hiddenInput().should('have.value', '3')
      cy.get('[data-rate="4"]').click()

      hiddenInput().should('have.value', '4')
      cy.get('@requestSubmit').should('have.been.calledOnce')
    })
  })

  describe('without auto submit', () => {
    it('leaves the radios as the form inputs and never submits on its own', () => {
      cy.intercept(/\/lookbook\?/, { statusCode: 200, body: 'submitted' }).as('submitted')
      cy.visit('/bali/rate/default')

      // No controller at all: nothing to fire, and the radios carry the
      // attribute name themselves.
      cy.get('[data-controller="rate"]').should('not.exist')
      cy.get('input[name="movie[rating]"]').should('have.length', 5)

      cy.get('#movie_rating_5').click()

      cy.get('#movie_rating_5').should('be.checked')
      cy.get('#movie_rating_3').should('not.be.checked')
      cy.get('@submitted.all').should('have.length', 0)
    })
  })

  describe('readonly', () => {
    it('is display only: nothing to click, nothing to submit', () => {
      cy.visit('/bali/rate/readonly')

      stars().should('have.length', 0)
      cy.get('.rating input[type="radio"]').should('have.length', 5).each(($input) => {
        cy.wrap($input).should('be.disabled')
        // No name either: dropped into a form, a readonly rating contributes
        // no parameter of its own.
        cy.wrap($input).should('not.have.attr', 'name')
      })

      cy.get('[data-controller="rate"]').should('not.exist')
      cy.get('[data-rate-target="input"]').should('not.exist')
    })
  })
})
