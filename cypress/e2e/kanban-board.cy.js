// Board-level Kanban anatomy (#643): a height-capped board scrolls per column,
// a :flow board scrolls horizontally, an empty column stays a visible drop
// target, and a cross-column drop still PATCHes the 1-based contract.
//
// The empty-column affordance is asserted by computed style, not by class —
// the rule lives in kanban/index.css and a class assertion would pass even if
// the sheet stopped being imported. "No affordance" computes as border-width
// 0px with style `solid` (Tailwind preflight's `border: 0 solid`), never as
// `none`, so the width is what tells the states apart.
//
// The drag is synthetic pointer events with pointerType 'touch': SortableJS
// binds `pointerdown` when PointerEvent exists, and the touch pointer type
// routes it into its fallback drag, which synthetic events can drive all the
// way to `onEnd`. Native HTML5 DnD (pointerType mouse) cannot be synthesized.
// Verified against real Chrome before being written down here.
describe('Kanban board', () => {
  // SortableJS arrives via dynamic import inside the controller's connect(),
  // so "the page rendered" does not mean "drag is wired". SortableJS stamps
  // its instance on the list element under an expando key that starts with
  // "Sortable" — polling for it is the only DOM-visible readiness signal.
  const waitForSortable = () => {
    cy.get('.kanban-column-list').first().should($el => {
      const keys = Object.keys($el[0])
      expect(keys.some(key => key.indexOf('Sortable') === 0), 'SortableJS initialized').to.eq(true)
    })
  }

  beforeEach(() => {
    cy.viewport(900, 600)
    cy.visit('/bali/kanban/scrollable_board')
    waitForSortable()
  })

  it('caps the board to the viewport and scrolls the long column internally', () => {
    // 12 cards in ~330px of board: the list must be the scroll container.
    cy.contains('.kanban-column', 'Backlog').find('.kanban-column-list').should($list => {
      const list = $list[0]
      expect(getComputedStyle(list).overflowY).to.eq('auto')
      expect(list.scrollHeight, 'list scrollHeight > clientHeight').to.be.greaterThan(list.clientHeight)
    })

    // ...and the page itself must not be what scrolls vertically.
    cy.window().then(win => {
      const doc = win.document.documentElement
      expect(doc.scrollHeight, 'page does not scroll').to.be.at.most(win.innerHeight + 1)
    })
  })

  it('lays :flow columns on one horizontally scrolling row', () => {
    cy.get('.kanban-component > div').first().should($board => {
      const board = $board[0]
      expect(getComputedStyle(board).display).to.eq('flex')
      expect(getComputedStyle(board).overflowX).to.eq('auto')
      // 5 fixed-width columns in a 900px viewport must overflow sideways.
      expect(board.scrollWidth, 'board scrollWidth > clientWidth').to.be.greaterThan(board.clientWidth)
    })

    cy.contains('.kanban-column', 'Backlog').should($col => {
      expect($col[0].getBoundingClientRect().width).to.be.closeTo(288, 2) // w-72
    })
  })

  it('shows a dashed drop affordance on the empty column, live via :has()', () => {
    cy.contains('.kanban-column', 'Done').find('.kanban-column-list').as('emptyList')

    cy.get('@emptyList').should($list => {
      const style = getComputedStyle($list[0])
      expect(style.borderTopStyle, 'dashed border').to.eq('dashed')
      expect(style.borderTopWidth, 'visible border').to.eq('1px')
      expect(parseFloat(style.minHeight), 'min-height floor').to.be.at.least(100)
    })

    // The affordance must react to the DOM, not to render time: give the list
    // a child (what SortableJS does when a drag hovers or a card lands) and it
    // must yield; empty it again and it must come back.
    cy.get('@emptyList').then($list => {
      const child = $list[0].ownerDocument.createElement('div')
      $list[0].appendChild(child)
    })
    cy.get('@emptyList').should($list => {
      expect(getComputedStyle($list[0]).borderTopWidth, 'affordance yields to content').to.eq('0px')
    })

    cy.get('@emptyList').then($list => { $list[0].firstElementChild.remove() })
    cy.get('@emptyList').should($list => {
      expect(getComputedStyle($list[0]).borderTopStyle).to.eq('dashed')
      expect(getComputedStyle($list[0]).borderTopWidth).to.eq('1px')
    })
  })

  it('PATCHes the 1-based position and target status when a card lands on an empty column', () => {
    // The fallback drag positions the ghost with document.elementFromPoint, so
    // source and target must both be inside the viewport — at 900px the 5th
    // column is off-screen and the drop lands back where it started.
    cy.viewport(1600, 700)
    cy.intercept('PATCH', '/tasks/*', { statusCode: 200, body: '' }).as('move')

    cy.window().then(win => {
      const card = win.document.querySelector('[data-sortable-update-url="/tasks/30"]')
      const target = win.document.querySelectorAll('.kanban-column')[4]
        .querySelector('.kanban-column-list')
      const sleep = ms => new win.Promise(resolve => win.setTimeout(resolve, ms))
      const pointer = (type, el, x, y) => {
        el.dispatchEvent(new win.PointerEvent(type, {
          bubbles: true,
          cancelable: true,
          pointerId: 1,
          pointerType: 'touch',
          isPrimary: true,
          clientX: x,
          clientY: y,
          button: 0,
          buttons: 1
        }))
      }
      const from = card.getBoundingClientRect()
      const to = target.getBoundingClientRect()

      pointer('pointerdown', card, from.x + from.width / 2, from.y + 15)
      return sleep(150)
        .then(() => {
          pointer('pointermove', win.document, from.x + from.width / 2 + 20, from.y + 60)
          return sleep(150)
        })
        .then(() => {
          pointer('pointermove', win.document, to.x + to.width / 2, to.y + 40)
          return sleep(200)
        })
        .then(() => {
          pointer('pointerup', win.document, to.x + to.width / 2, to.y + 40)
        })
    })

    cy.wait('@move').then(({ request }) => {
      expect(request.url).to.match(/\/tasks\/30$/)

      const body = typeof request.body === 'string'
        ? request.body
        : new TextDecoder().decode(request.body)
      // Multipart form-data: the value follows the field's blank line. The
      // first slot of an empty column is position 1 — a 0 here is the exact
      // off-by-one this spec pins down.
      expect(body).to.match(/name="task\[position\]"\r\n\r\n1\r\n/)
      expect(body).to.match(/name="task\[status\]"\r\n\r\ndone\r\n/)
    })

    // The card really moved...
    cy.contains('.kanban-column', 'Done').find('[data-sortable-update-url="/tasks/30"]')
      .should('exist')

    // ...and the drop is announced through the board's live region — the only
    // channel a screen reader has, since a drop moves the DOM and nothing else.
    cy.get('[data-kanban-target="liveRegion"]')
      .should('contain.text', 'moved to Done, position 1 of 1')
  })

  it('a disabled column keeps its cards', () => {
    // Same viewport note as above: the drag attempt is only honest if the
    // Blocked column and the target are actually on-screen.
    cy.viewport(1600, 700)
    cy.window().then(win => {
      const card = win.document.querySelector('[data-sortable-update-url="/tasks/40"]')
      const target = win.document.querySelectorAll('.kanban-column')[1]
        .querySelector('.kanban-column-list')
      const sleep = ms => new win.Promise(resolve => win.setTimeout(resolve, ms))
      const pointer = (type, el, x, y) => {
        el.dispatchEvent(new win.PointerEvent(type, {
          bubbles: true,
          cancelable: true,
          pointerId: 2,
          pointerType: 'touch',
          isPrimary: true,
          clientX: x,
          clientY: y,
          button: 0,
          buttons: 1
        }))
      }
      const from = card.getBoundingClientRect()
      const to = target.getBoundingClientRect()

      pointer('pointerdown', card, from.x + from.width / 2, from.y + 15)
      return sleep(150)
        .then(() => {
          pointer('pointermove', win.document, to.x + to.width / 2, to.y + 60)
          return sleep(200)
        })
        .then(() => {
          pointer('pointerup', win.document, to.x + to.width / 2, to.y + 60)
          return sleep(200)
        })
    })

    cy.contains('.kanban-column', 'Blocked').find('[data-sortable-update-url="/tasks/40"]')
      .should('exist')
  })
})
