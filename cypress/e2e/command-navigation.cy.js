// The palette of the side menu preview's navigation, where Projects, Inbox and Users are
// `frequent: true`. Groups and rows are read by the `hidden` class the controller toggles.
const shown = ($elements, selector) =>
  $elements.not('.hidden').map((_, element) => element.querySelector(selector).textContent.trim()).get()

describe('Command palette drawn from a navigation', () => {
  beforeEach(() => {
    cy.visit('/bali/command/from_navigation')
    cy.get('.bali-command-trigger').click()
    cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')
  })

  it('opens on the frequent pages alone', () => {
    cy.get('[data-command-target="group"]').should($groups => {
      expect(shown($groups, '.cmd-group')).to.deep.equal(['Frequent'])
    })
    cy.get('.cmd-row').should($rows => {
      expect(shown($rows, '.cmd-row-title')).to.deep.equal(['Projects', 'Inbox', 'Users'])
    })
  })

  it('lists the pages as you type, and a frequent page once', () => {
    cy.get('[data-command-target="input"]').type('Projects')

    cy.get('[data-command-target="group"]').should($groups => {
      expect(shown($groups, '.cmd-group')).to.deep.equal(['Pages'])
    })
    cy.get('.cmd-row').should($rows => {
      expect(shown($rows, '.cmd-row-title')).to.deep.equal(['Projects'])
      expect($rows.not('.hidden').attr('data-mode')).to.equal('searchable')
    })
  })
})
