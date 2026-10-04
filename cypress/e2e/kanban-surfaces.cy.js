import { contrastRatio, paintedContrast, paintedLuminance } from '../support/painted_contrast'
import { hover, press, release, tap, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// The lane is a base-300 surface and the card the raised one. On the light themes the card's fill
// carries the step and its border all but matches the lane; on the dark ones the fill steps less
// and the border carries it.
describe('Kanban lanes and cards', () => {
  const STEP = 1.15
  const EDGE = 1.45
  const MARK = 1.2
  const OUTLINE = 1.5
  const FILL_CARRIES = ['light', 'afal', 'costa-norte']

  beforeEach(() => cy.viewport(1600, 900))
  afterEach(() => cy.then(unhover))

  const board = (preview, theme) => {
    cy.visit(`/bali/kanban/${preview}`)
    if (theme) cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }
  const column = (title) => cy.contains('.kanban-column', title)
  const firstCard = (title) => column(title).find('.kanban-card').first()

  // SortableJS arrives through a dynamic import and stamps its instance on the list under a key
  // that starts with "Sortable": the only sign in the DOM that a press will reach it.
  const waitForSortable = () => {
    cy.get('.kanban-column-list').first().should(($list) => {
      expect(Object.keys($list[0]).some(key => key.startsWith('Sortable')), 'SortableJS initialized').to.equal(true)
    })
  }

  const settled = (el) => expect(el.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
  const style = (el) => el.ownerDocument.defaultView.getComputedStyle(el)

  // A fill steps off what is under it, so the search for that ground starts at the parent.
  const lift = (el) => paintedContrast(el, { over: el.parentElement, property: 'backgroundColor' })
  const line = (el) => paintedContrast(el, { property: 'borderTopColor' })
  // Every background from the root down to `el`, painted in order: what shows through at `el`.
  const groundAt = (el) => {
    const layers = []
    for (let node = el; node; node = node.parentElement) layers.unshift(style(node).backgroundColor)
    return ['white', ...layers]
  }
  // The card's border paints over the card's own fill and is read against the lane beside it.
  const borderOnLane = (card) => {
    const doc = card.ownerDocument
    const lane = groundAt(card.parentElement)
    const { backgroundColor, borderTopColor } = style(card)
    return contrastRatio(paintedLuminance(doc, ...lane, backgroundColor, borderTopColor), paintedLuminance(doc, ...lane))
  }

  THEMES.forEach((theme) => {
    it(`steps the card off its lane on the ${theme} theme`, () => {
      board('scrollable_board', theme)
      firstCard('To Do').should(($card) => {
        settled($card[0])
        expect($card[0].matches(':hover'), 'at rest').to.equal(false)
        if (FILL_CARRIES.includes(theme)) {
          expect(lift($card[0]), `${theme}: the card's fill against its lane`).to.be.at.least(STEP)
        } else {
          expect(parseFloat(style($card[0]).borderTopWidth), 'border width').to.be.at.least(1)
          expect(borderOnLane($card[0]), `${theme}: the card's border against its lane`).to.be.at.least(EDGE)
        }
      })
    })

    // daisyUI's badge-ghost is base-200: on the base-300 lane the indicator, a pill with no
    // text, is all that tells the column's colour and it all but disappears.
    it(`shows the ghost indicator and the count on the lane on the ${theme} theme`, () => {
      board('scrollable_board', theme)
      column('Backlog').find('h3 .badge-ghost').should(($badges) => {
        settled($badges[0])
        expect($badges, 'the indicator and the count').to.have.length(2)
        $badges.each((_, badge) => {
          const what = badge.textContent.trim() ? 'the count' : 'the indicator'
          expect(lift(badge), `${theme}: ${what} against its lane`).to.be.at.least(MARK)
        })
      })
    })

    it(`outlines the empty column against its lane on the ${theme} theme`, () => {
      board('scrollable_board', theme)
      column('Done').find('.kanban-column-list').should(($list) => {
        settled($list[0])
        expect(style($list[0]).borderTopStyle, 'dashed').to.equal('dashed')
        expect(line($list[0]), `${theme}: the empty column's outline against its lane`).to.be.at.least(OUTLINE)
      })
    })

    it(`rules the footer off the lane on the ${theme} theme`, () => {
      board('with_footer', theme)
      cy.get('.kanban-column-footer').first().should(($footer) => {
        settled($footer[0])
        expect(parseFloat(style($footer[0]).borderTopWidth), 'rule width').to.be.at.least(1)
        expect(line($footer[0]), `${theme}: the footer's rule against its lane`).to.be.at.least(MARK)
      })
    })
  })

  const look = (el) => {
    const { borderTopColor, boxShadow, translate } = style(el)
    return { border: borderTopColor, shadow: boxShadow, translate }
  }

  // Rests the pointer on the card and hands `check` its look at rest and under the pointer.
  const underThePointer = (card, check) => {
    let atRest
    card().should(($card) => {
      settled($card[0])
      expect($card[0].matches(':hover'), 'at rest').to.equal(false)
      atRest = look($card[0])
    }).then(hover)
    card().should(($card) => {
      settled($card[0])
      expect($card[0].matches(':hover'), 'under the pointer').to.equal(true)
      check(look($card[0]), atRest, $card[0])
    })
  }

  it('lifts a card whose drop is saved under the pointer', () => {
    board('scrollable_board')
    underThePointer(() => firstCard('To Do'), (hovered, atRest, card) => {
      expect(hovered.border, 'border').not.to.equal(atRest.border)
      expect(hovered.shadow, 'shadow').not.to.equal(atRest.shadow)
      expect(hovered.translate, 'lift').to.equal('0px -1px')
      expect(borderOnLane(card), 'the border under the pointer against its lane').to.be.above(MARK)
    })
  })

  // A lift would promise a drop the board does not save.
  ;[
    ['a card without update_url', 'default', 'To Do'],
    ['a card of a disabled column', 'scrollable_board', 'Blocked']
  ].forEach(([what, preview, title]) => {
    it(`leaves ${what} as it is under the pointer`, () => {
      board(preview)
      underThePointer(() => firstCard(title), (hovered, atRest) => {
        expect(hovered, what).to.deep.equal(atRest)
      })
    })
  })

  it('drops the lift while SortableJS holds the card', () => {
    board('scrollable_board')
    waitForSortable()
    let atRest
    firstCard('To Do').should(($card) => {
      settled($card[0])
      atRest = look($card[0])
    }).then(hover)
    firstCard('To Do').should(($card) => {
      settled($card[0])
      expect(look($card[0]).translate, 'lifted under the pointer').to.equal('0px -1px')
    }).then(press)

    firstCard('To Do').should(($card) => {
      expect($card[0].classList.contains('sortable-chosen'), 'chosen by SortableJS').to.equal(true)
      settled($card[0])
      expect(look($card[0]), 'held').to.deep.equal(atRest)
    }).then(release)
    firstCard('To Do').should('not.have.class', 'sortable-chosen')
  })

  context('under prefers-reduced-motion', () => {
    const reducedMotion = (value) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setEmulatedMedia',
      params: { features: [{ name: 'prefers-reduced-motion', value }] }
    }))

    beforeEach(() => reducedMotion('reduce'))
    afterEach(() => reducedMotion(''))

    it('marks a card whose drop is saved under the pointer without moving it', () => {
      board('scrollable_board')
      cy.window().should((win) => {
        expect(win.matchMedia('(prefers-reduced-motion: reduce)').matches, 'reduced motion emulated').to.equal(true)
      })
      underThePointer(() => firstCard('To Do'), (hovered, atRest) => {
        expect(hovered.border, 'border').not.to.equal(atRest.border)
        expect(hovered.translate, 'no lift').to.equal(atRest.translate)
      })
    })
  })

  // Forced colours repaint the lane's fill as Canvas, the page's own colour, and draw every border
  // in CanvasText: the lane's transparent one is what still outlines it.
  context('under forced colours', () => {
    const forcedColors = (value) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setEmulatedMedia',
      params: { features: [{ name: 'forced-colors', value }] }
    }))

    beforeEach(() => forcedColors('active'))
    afterEach(() => forcedColors(''))

    it('still outlines the lane', () => {
      board('scrollable_board')
      cy.window().should((win) => {
        expect(win.matchMedia('(forced-colors: active)').matches, 'forced colours emulated').to.equal(true)
      })
      column('To Do').should(($column) => {
        const { backgroundColor, borderTopColor, borderTopWidth } = style($column[0])
        expect(parseFloat(borderTopWidth), 'the lane\'s border').to.be.at.least(1)
        expect(borderTopColor, 'drawn apart from the fill').not.to.equal(backgroundColor)
      })
    })
  })

  // With a touch pointer SortableJS drags a clone it hangs off <body>, outside the column, so the
  // card's look has to come from the card's own class.
  it('paints the touch-drag clone SortableJS hangs off <body> like the card', () => {
    cy.intercept('PATCH', '/tasks/*', { statusCode: 200, body: '' })
    board('scrollable_board')
    waitForSortable()
    let atRest, finish
    firstCard('To Do').then(($card) => {
      const { backgroundColor, borderTopColor, boxShadow } = style($card[0])
      atRest = { backgroundColor, borderTopColor, boxShadow }
    })

    cy.window().then((win) => {
      const card = win.document.querySelector('[data-sortable-update-url="/tasks/20"]')
      const sleep = ms => new win.Promise(resolve => win.setTimeout(resolve, ms))
      const pointer = (type, el, x, y) => el.dispatchEvent(new win.PointerEvent(type, {
        bubbles: true, cancelable: true, pointerId: 3, pointerType: 'touch', isPrimary: true, clientX: x, clientY: y, button: 0, buttons: 1
      }))
      const { x, y, width } = card.getBoundingClientRect()
      finish = () => pointer('pointerup', win.document, x + width / 2, y + 60)

      pointer('pointerdown', card, x + width / 2, y + 15)
      return sleep(150).then(() => {
        pointer('pointermove', win.document, x + width / 2 + 20, y + 60)
        return sleep(150)
      })
    })

    cy.get('body > .sortable-fallback').should(($clone) => {
      const { backgroundColor, borderTopColor, boxShadow } = style($clone[0])
      expect({ backgroundColor, borderTopColor, boxShadow }, 'the clone').to.deep.equal(atRest)
    }).then(() => finish())
  })

  // The list scrolls, and a scroll container clips what its children paint past its padding box:
  // the shadow of a card under the pointer, lifted a pixel.
  const reach = (card) => {
    const shadows = style(card).boxShadow.split(/,(?![^(]*\))/)
    return shadows.reduce((most, shadow) => {
      const [x, y, blur, spread = 0] = shadow.match(/-?[\d.]+px/g).map(parseFloat)
      return {
        top: Math.max(most.top, blur + spread - y),
        right: Math.max(most.right, blur + spread + x),
        bottom: Math.max(most.bottom, blur + spread + y),
        left: Math.max(most.left, blur + spread - x)
      }
    }, { top: 0, right: 0, bottom: 0, left: 0 })
  }
  const rectOf = (el) => el.getBoundingClientRect()
  const roomAround = (card) => {
    const list = rectOf(card.parentElement)
    const box = rectOf(card)
    return { top: box.top - list.top, right: list.right - box.right, bottom: list.bottom - box.bottom, left: box.left - list.left }
  }

  it('keeps room inside the list for the shadow of a card under the pointer', () => {
    board('scrollable_board')
    underThePointer(() => firstCard('To Do'), (hovered, atRest, card) => {
      const room = roomAround(card)
      const shadow = reach(card)
      expect(room.top, 'room above the first card').to.be.at.least(shadow.top)
      expect(room.left, 'room left of the card').to.be.at.least(shadow.left)
      expect(room.right, 'room right of the card').to.be.at.least(shadow.right)
    })

    // Only a full list scrolled to its end leaves no more than its padding below the last card.
    column('Backlog').find('.kanban-column-list').then(($list) => {
      expect($list[0].scrollHeight, 'a full list').to.be.above($list[0].clientHeight)
      $list[0].scrollTop = $list[0].scrollHeight
    })
    underThePointer(() => column('Backlog').find('.kanban-card').last(), (hovered, atRest, card) => {
      const list = card.parentElement
      expect(list.scrollTop + list.clientHeight, 'scrolled to its end').to.be.closeTo(list.scrollHeight, 1)
      expect(roomAround(card).bottom, 'room below the last card').to.be.at.least(reach(card).bottom)
    })
  })

  it('lines the cards, the empty column and the footer up with the header', () => {
    board('scrollable_board')
    column('To Do').should(($column) => {
      const header = rectOf($column[0].querySelector('h3'))
      $column.find('.kanban-card').each((_, card) => {
        expect(rectOf(card).left, 'card in line with the header, left').to.be.closeTo(header.left, 0.5)
        expect(rectOf(card).right, 'card in line with the header, right').to.be.closeTo(header.right, 0.5)
      })
    })
    column('Done').should(($column) => {
      const header = rectOf($column[0].querySelector('h3'))
      const outline = rectOf($column[0].querySelector('.kanban-column-list'))
      expect(outline.left, 'empty column outline in line with the header, left').to.be.closeTo(header.left, 0.5)
      expect(outline.right, 'empty column outline in line with the header, right').to.be.closeTo(header.right, 0.5)
    })

    board('with_footer')
    column('To Do').should(($column) => {
      const card = rectOf($column[0].querySelector('.kanban-card'))
      const footer = rectOf($column[0].querySelector('.kanban-column-footer'))
      expect(footer.left, 'footer in line with the cards, left').to.be.closeTo(card.left, 0.5)
      expect(footer.right, 'footer in line with the cards, right').to.be.closeTo(card.right, 0.5)
    })
  })

  // A tap leaves the card matching `:hover` until the next tap lands elsewhere. Last in the file:
  // once touch emulation is off, Chrome reports (hover: none) for the rest of the tab, reloads
  // included, and every hover() after it would throw.
  context('on a screen that cannot hover', () => {
    const touchScreen = (enabled) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setTouchEmulationEnabled',
      params: { enabled, maxTouchPoints: 1 }
    }))

    beforeEach(() => touchScreen(true))
    afterEach(() => touchScreen(false))

    it('leaves a tapped card as it is', () => {
      board('scrollable_board')
      waitForSortable()
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
})
