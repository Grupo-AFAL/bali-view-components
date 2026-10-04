import { tap } from '../support/tap'

// A tap leaves the card matching `:hover` until the next tap lands elsewhere. Its own spec: once
// touch emulation has been on, Chrome reports (hover: none) for the rest of the tab, reloads
// included, and a hover() after it throws.
describe('Kanban cards on a screen that cannot hover', () => {
  const touchScreen = (enabled) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
    command: 'Emulation.setTouchEmulationEnabled',
    params: { enabled, maxTouchPoints: 1 }
  }))

  beforeEach(() => {
    cy.viewport(1600, 900)
    touchScreen(true)
  })
  afterEach(() => touchScreen(false))

  const firstCard = (title) => cy.contains('.kanban-column', title).find('.kanban-card').first()
  const settled = (el) => expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  const look = (el) => {
    const { borderTopColor, boxShadow, translate } = el.ownerDocument.defaultView.getComputedStyle(el)
    return { border: borderTopColor, shadow: boxShadow, translate }
  }

  it('leaves a tapped card as it is', () => {
    cy.visit('/bali/kanban/scrollable_board')
    // SortableJS stamps its instance on the list under a key that starts with "Sortable": the only
    // sign in the DOM that the tap will reach it.
    cy.get('.kanban-column-list').first().should(($list) => {
      expect(Object.keys($list[0]).some(key => key.startsWith('Sortable')), 'SortableJS initialized').to.equal(true)
    })
    cy.window().should((win) => {
      expect(win.matchMedia('(hover: none)').matches, 'a screen that cannot hover').to.equal(true)
    })
    let atRest
    firstCard('To Do').should(($card) => {
      settled($card[0])
      atRest = look($card[0])
    }).then(tap)

    firstCard('To Do').should(($card) => {
      expect($card[0].matches(':hover'), 'the tap left :hover on the card').to.equal(true)
      expect($card[0].classList.contains('sortable-chosen'), 'let go by SortableJS').to.equal(false)
      settled($card[0])
      expect(look($card[0]), 'tapped').to.deep.equal(atRest)
    })
  })
})
