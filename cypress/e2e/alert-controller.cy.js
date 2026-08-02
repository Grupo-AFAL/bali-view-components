describe('AlertController', () => {
  context('auto-dismiss', () => {
    it('closes a toast on its own after `duration` and takes it out of the DOM', () => {
      cy.visit('/bali/toast_container/flash?duration=1000&position=bottom_end')

      cy.get('.toast-component').should('have.length', 4)
      cy.get('.toast-component', { timeout: 6000 }).should('not.exist')
    })

    it('leaves a toast alone when there is no duration', () => {
      cy.visit('/bali/toast/sticky')

      cy.get('.toast-component').should('have.length', 1)
      cy.wait(1500)
      cy.get('.toast-component').should('have.length', 1)
    })

    // The regression this whole controller was rewritten for. v2 added a class and
    // waited for `animationend` to remove the element, so an animation that never
    // ran — a host whose CSS did not carry the keyframes, a class the host
    // overrode with one it never styled, a background tab where Chrome freezes
    // animations — left the toast on screen forever. The removal is timed off the
    // element's own computed animation now, which is 0s when there is no animation.
    it('still leaves when the leaving class animates nothing', () => {
      cy.visit('/bali/toast/sticky')

      cy.get('.toast-component')
        .invoke('attr', 'data-alert-leaving-class', 'a-class-nobody-styled')
        .find('button[data-action="alert#dismiss"]')
        .click()

      cy.get('.toast-component').should('not.exist')
    })
  })

  context('the close button', () => {
    it('removes the alert', () => {
      cy.visit('/bali/alert/closable')

      cy.get('.alert-component').should('exist')
      cy.get('button[data-action="alert#dismiss"]').click()
      cy.get('.alert-component').should('not.exist')
    })

    it('is a real button, so it is reachable and operable from the keyboard', () => {
      cy.visit('/bali/alert/closable')

      cy.get('button[data-action="alert#dismiss"]')
        .should('match', 'button')
        .should('have.attr', 'type', 'button')
        .should('have.attr', 'aria-label', 'Close alert')
        .focus()
        .type('{enter}')

      cy.get('.alert-component').should('not.exist')
    })
  })

  context('dismiss_id', () => {
    const storageKey = 'bali:alert:dismissed:preview-welcome-banner'

    beforeEach(() => {
      cy.visit('/bali/alert/closable_persistent')
      cy.window().then(win => win.localStorage.removeItem(storageKey))
      cy.reload()
    })

    afterEach(() => {
      cy.window().then(win => win.localStorage.removeItem(storageKey))
    })

    it('remembers the dismissal', () => {
      cy.get('button[data-action="alert#dismiss"]').click()
      cy.window().its('localStorage').invoke('getItem', storageKey).should('equal', 'true')
    })

    it('stays hidden on the next page load', () => {
      cy.get('button[data-action="alert#dismiss"]').click()
      cy.reload()
      cy.get('.alert-component').should('not.be.visible')
    })

    it('comes back once the dismissal is forgotten', () => {
      cy.get('button[data-action="alert#dismiss"]').click()
      cy.reload()
      cy.window().then(win => win.localStorage.removeItem(storageKey))
      cy.reload()
      cy.get('.alert-component').should('be.visible')
    })
  })

  context('the leaving animation', () => {
    // daisyUI 5 emits `.toast > *` with an `animation` of its own inside
    // @layer utilities, and a layer beats specificity. The sheet that carries
    // these two classes is unlayered for exactly that reason.
    it('wins the cascade against daisyUI inside a container', () => {
      cy.visit('/bali/toast_container/flash?duration=0&position=bottom_end')

      cy.get('.toast-component').first().then($el => {
        expect(getComputedStyle($el[0]).animationName).to.equal('bali-toast-in')

        $el[0].classList.add('toast-leaving')
        expect(getComputedStyle($el[0]).animationName).to.equal('bali-toast-out')
      })
    })
  })
})
