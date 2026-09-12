// The bubble markup Bali::Chat::Message::Component emits, which is what a
// `turbo_stream.append 'chat-messages'` drops into the scroll region. Inserting it
// by hand exercises the same MutationObserver a real stream would.
const incomingMessage = body => `
  <div class="chat chat-start">
    <div class="chat-header">Assistant</div>
    <div class="chat-bubble max-w-[82%]">${body}</div>
  </div>
`

const metrics = element => ({
  scrollTop: element.scrollTop,
  scrollHeight: element.scrollHeight,
  clientHeight: element.clientHeight,
  distanceFromBottom: element.scrollHeight - element.scrollTop - element.clientHeight
})

const append = (element, body) => {
  element.insertAdjacentHTML('beforeend', incomingMessage(body))
}

describe('ChatController', () => {
  const messages = () => cy.get('#chat-messages')

  beforeEach(() => {
    cy.visit('/bali/chat/default')
    // Everything below is about scrolling, so a conversation that fits in the box
    // would make all of it pass for the wrong reason.
    messages().then($el => {
      const { scrollHeight, clientHeight } = metrics($el[0])
      expect(scrollHeight, 'preview conversation must overflow its container')
        .to.be.greaterThan(clientHeight)
    })
  })

  context('on connect', () => {
    it('opens at the latest message, not at the top of the history', () => {
      messages().then($el => {
        const { scrollTop, distanceFromBottom } = metrics($el[0])
        expect(scrollTop).to.be.greaterThan(0)
        expect(distanceFromBottom).to.be.lessThan(2)
      })
    })
  })

  context('when a message is appended', () => {
    it('follows the conversation down for a reader who was already at the bottom', () => {
      messages().then($el => {
        const before = metrics($el[0])

        append($el[0], 'A newly arrived answer, long enough to change the scroll height.')

        // The observer runs on a microtask, so the DOM is already taller here while
        // scrollTop has not moved yet — which is exactly the state that makes a
        // naive at-bottom check read as "scrolled up".
        cy.wrap($el[0]).should(element => {
          const after = metrics(element)
          expect(after.scrollHeight).to.be.greaterThan(before.scrollHeight)
          expect(after.scrollTop).to.be.greaterThan(before.scrollTop)
          expect(after.distanceFromBottom).to.be.lessThan(2)
        })
      })
    })

    it('leaves the scrollbar alone for a reader who scrolled up into the history', () => {
      messages().scrollTo('top')
      // Let the `scroll` event reach the controller: the decision to follow or not
      // is taken from the position recorded by that event, never measured after the
      // append.
      cy.wait(250)

      messages().then($el => {
        const before = metrics($el[0])
        expect(before.scrollTop).to.equal(0)

        append($el[0], 'An answer that arrives while the reader is up in the history.')

        cy.wait(250)
        cy.wrap($el[0]).should(element => {
          const after = metrics(element)
          expect(after.scrollHeight).to.be.greaterThan(before.scrollHeight)
          expect(after.scrollTop, 'the reader keeps their place').to.equal(0)
        })
      })
    })

    it('follows again once the reader returns to the bottom', () => {
      messages().scrollTo('top')
      cy.wait(250)
      messages().scrollTo('bottom')
      cy.wait(250)

      messages().then($el => {
        const before = metrics($el[0])

        append($el[0], 'An answer arriving after the reader caught up with the conversation.')

        cy.wrap($el[0]).should(element => {
          const after = metrics(element)
          expect(after.scrollTop).to.be.greaterThan(before.scrollTop)
          expect(after.distanceFromBottom).to.be.lessThan(2)
        })
      })
    })
  })

  context('the typing indicator', () => {
    // Visibility, not presence: the node is in the DOM the whole time — that is the
    // point of it — so asserting on its existence would pass in both states.
    it('is in the DOM but not shown until something starts typing', () => {
      cy.get('#chat-typing-indicator').should('exist').and('not.be.visible')
    })

    it('is shown and hidden again through the container controller', () => {
      cy.contains('button', 'Send').click()
      cy.get('#chat-typing-indicator').should('be.visible')

      cy.contains('button', 'Stop typing').click()
      cy.get('#chat-typing-indicator').should('not.be.visible')
      cy.get('#chat-typing-indicator').should('exist')
    })

    it('brings the reader back down when they send from up in the history', () => {
      messages().scrollTo('top')
      cy.wait(250)

      cy.contains('button', 'Send').click()

      messages().should(element => {
        expect(metrics(element[0]).distanceFromBottom).to.be.lessThan(2)
      })
    })
  })
})
