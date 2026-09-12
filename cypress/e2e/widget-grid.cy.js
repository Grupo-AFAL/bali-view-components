// Covers both Stimulus controllers behind the bento dashboard —
// `bali-widget-grid` (drag/keyboard reorder, resize, remove, persist) and
// `bali-widget-grid-edit-mode` (enter/leave, URL, Escape, Back) — driven through the Lookbook
// preview at /bali/widget_grid/default, the only surface Bali has for a
// controller with no jsdom unit runner behind it.
describe('widget grid', () => {
  beforeEach(() => {
    // The size picker only renders `lg:` and up (below that, all three sizes
    // look identical, per widget/component.html.erb) — Cypress's default
    // viewport (1000px) is under the 1024px `lg` breakpoint, so every test
    // that touches edit chrome needs a viewport at or above it. Tall, too:
    // the fallback drag below resolves its drop target with
    // `elementFromPoint`, which only sees what is actually in the viewport —
    // measured against this preview's four cards + add tile, 1500px is enough
    // that nothing falls below the fold and no test needs to scroll.
    cy.viewport(1400, 1500)
    cy.intercept('PATCH', '/widget_layout').as('save')
    cy.visit('/bali/widget_grid/default')
  })

  const enterEditMode = () => cy.get('[data-action="bali-widget-grid-edit-mode#enter"]').click()

  // `@rails/request.js` sends the layout as `multipart/form-data` (it's a
  // FormData body), not `application/x-www-form-urlencoded` — so
  // `URLSearchParams` cannot parse `interception.request.body` correctly.
  // Same shape of fix as kanban-board.cy.js's multipart regex, generalised to
  // pull every occurrence of a repeated field out of the raw multipart text.
  const submittedKeys = (interception) =>
    [...String(interception.request.body).matchAll(/name="widgets\[\]\[key\]"\r\n\r\n([^\r\n]*)\r\n/g)]
      .map(([, value]) => value)

  // Same shape as `submittedKeys`, for the paired `widgets[][size]` field. Each
  // card appends its key and then its size (see `writeSequence`), so the two
  // arrays line up positionally — `submittedSizes(...)[submittedKeys(...).indexOf(key)]`
  // is the size that key was submitted with. A substring check on the raw body
  // can't tell "the right value under the right field name" from "these letters
  // appear somewhere" — it would pass just as well if the field were renamed.
  const submittedSizes = (interception) =>
    [...String(interception.request.body).matchAll(/name="widgets\[\]\[size\]"\r\n\r\n([^\r\n]*)\r\n/g)]
      .map(([, value]) => value)

  // SortableJS arrives via dynamic import inside the controller's connect(), so
  // "the page rendered" does not mean "drag is wired" — see kanban-board.cy.js.
  const waitForSortable = () => {
    cy.get('.bali-widget-grid').should($el => {
      const keys = Object.keys($el[0])
      expect(keys.some(key => key.indexOf('Sortable') === 0), 'SortableJS initialized').to.eq(true)
    })
  }

  it('renders one card per widget with its declared size', () => {
    cy.get('.bali-widget-grid > [data-widget-key]').should('have.length', 4)
    cy.get('[data-widget-key="overdue_counts"]').should('have.attr', 'data-size', 'small')
    cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'medium')
    cy.get('[data-widget-key="expiring_stock"]').should('have.attr', 'data-size', 'large')
    cy.get('[data-widget-key="cost_spikes"]').should('have.attr', 'data-size', 'large')
  })

  it('hides the edit chrome until edit mode is entered', () => {
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] .handle').should('be.visible')
  })

  it('remembers edit mode in the URL and leaves it on Back', () => {
    enterEditMode()
    cy.location('search').should('contain', 'editing')
    cy.go('back')
    cy.location('search').should('not.contain', 'editing')
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
  })

  // Extra assertion #2 (from code review): EditModeController#push calls raw
  // `window.history.pushState` rather than routing through Turbo's history —
  // unlike modal/index.js, which does that deliberately via
  // `window.Turbo.session.history.push`. A class-flip and a full document load
  // both end up "not editing" and both clear the query string, so the assertion
  // above cannot tell them apart. Stamping a marker on `window` before Back and
  // requiring it to SURVIVE does: a HARD navigation tears down and re-executes
  // every script, which destroys the JS realm and wipes any property a test set
  // on the old `window` — a class-flip cannot fake that survival.
  //
  // Measured, not assumed: this preview's layout loads Turbo Drive, and Turbo
  // binds its OWN `popstate` listener. Because `push()` never tells Turbo about
  // this history entry, Turbo doesn't recognise it on the way back and fires a
  // "restoration visit" — a real `GET` to this same URL — confirmed with a
  // network spy while writing this spec. That visit swaps `<body>`, which is
  // genuinely wasteful, but it is NOT a hard reload: `window` survives, so
  // EditModeController's own `popstate` handler (which runs synchronously,
  // independent of Turbo) is what actually leaves edit mode. That is the
  // distinction this test can honestly make and the one asserted below — see
  // the report for the network round-trip as a separate, real finding.
  it('leaves edit mode on Back via history, not a full page navigation', () => {
    enterEditMode()
    cy.location('search').should('contain', 'editing')

    cy.window().then((win) => { win.__cySurvivesBack = true })

    cy.go('back')

    cy.location('search').should('not.contain', 'editing')
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
    // The one signal a hard reload cannot fake: the JS realm is still the one
    // that was standing before Back, not a freshly booted one.
    cy.window().should('have.prop', '__cySurvivesBack', true)
  })

  // The param is a Stimulus value, not a hardcoded `editing`. A component has no
  // business claiming a bare, generic name from inside a host's URL — a host may
  // already use it for something of their own.
  it('remembers the mode under a configurable param', () => {
    cy.get('[data-controller*="bali-widget-grid-edit-mode"]')
      .should('have.attr', 'data-bali-widget-grid-edit-mode-param-value', 'editing')
  })

  it('leaves edit mode on Escape', () => {
    enterEditMode()
    cy.get('body').type('{esc}')
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
  })

  it('moves a card with the arrow keys and saves the new order', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle').focus().type('{rightarrow}')

    cy.wait('@save').then((interception) => {
      expect(submittedKeys(interception)[1]).to.equal('overdue_counts')
    })
    // Focus follows the card, not the index — the DOM move blurs the button.
    cy.focused().closest('[data-widget-key]').should('have.attr', 'data-widget-key', 'overdue_counts')
  })

  it('announces the move for screen readers', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle').focus().type('{rightarrow}')
    cy.get('[role="status"]').should('contain', 'position 2 of 4')
  })

  it('resizes a card immediately and saves the size', () => {
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="large"]').click()

    cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'large')
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="large"]')
      .should('have.attr', 'aria-checked', 'true')
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="medium"]')
      .should('have.attr', 'aria-checked', 'false')

    cy.wait('@save').then((interception) => {
      // Positional, by name — proves `low_stock_items` specifically was
      // submitted as `large` under the `widgets[][size]` field, not merely that
      // the word "large" appears somewhere in the body (a raw substring check
      // would pass even if the field were mis-named, e.g. `widgets[][sizes]`).
      const keys = submittedKeys(interception)
      const sizes = submittedSizes(interception)
      expect(sizes[keys.indexOf('low_stock_items')]).to.equal('large')
    })
  })

  // THE LADDER. The card must show the same fact at every size and give it more
  // context as it grows — never change subject. A component test sees one size
  // at a time; only driving the picker shows the regions appear and disappear as
  // the canvas changes, which IS the ladder.
  describe('the size ladder', () => {
    // `low_stock_items` is the metric specimen: a count, a trend and a series.
    const card = '[data-widget-key="low_stock_items"]'
    const sizeTo = (size) => cy.get(`${card} [data-widget-size="${size}"]`).click()

    it('keeps the headline at every size', () => {
      enterEditMode()

      for (const size of ['small', 'medium', 'large']) {
        sizeTo(size)
        cy.get(card).should('have.attr', 'data-size', size)
        // The regression the ladder exists to fix: the headline used to appear
        // at `small` and nowhere else.
        cy.get(card).should('contain', '6')
      }
    })

    // GROWING is the gesture the ladder exists for, and it needs a host that
    // answers the resize with a stream — the Lookbook stub answers 204, so this
    // lives against the real dashboard in `widget-grid-resize.cy.js`.
    it('gains a chart from medium up and drops it at small', () => {
      enterEditMode()

      // NOT `not.exist`: resizing writes one attribute and the interior is
      // server-rendered, so the canvas is still in the DOM until the next load.
      // CSS hides it, which is what a ~215px tile can actually honour — see the
      // note at the bottom of `widget/index.css`.
      sizeTo('small')
      cy.get(`${card} canvas.chart`).should('not.be.visible')

      sizeTo('medium')
      cy.get(`${card} canvas.chart`).should('exist')

      sizeTo('large')
      cy.get(`${card} canvas.chart`).should('exist')
    })

    // `expiring_stock` is the pre-ladder specimen — count and items only, the
    // shape every widget written before this change has. It must still render
    // at every size, with the context region simply absent.
    it('renders a widget with no ladder data at every size, without a chart', () => {
      enterEditMode()
      const plain = '[data-widget-key="expiring_stock"]'

      for (const size of ['small', 'medium', 'large']) {
        cy.get(`${plain} [data-widget-size="${size}"]`).click()
        cy.get(plain).should('have.attr', 'data-size', size)
        cy.get(`${plain} canvas.chart`).should('not.exist')
        cy.get(plain).should('contain', '9')
      }
    })
  })

  // The size picker claims `role="radiogroup"`, and the point of the upgrade is
  // that it HONOURS the pattern rather than merely announcing it: one tab stop,
  // arrows within it, selection following focus.
  describe('the size picker as a radiogroup', () => {
    const picker = '[data-widget-key="low_stock_items"] [role="radiogroup"]'

    it('carries one tab stop on the checked size, not three', () => {
      enterEditMode()

      cy.get(`${picker} [aria-checked="true"]`).should('have.attr', 'tabindex', '0')
      cy.get(`${picker} [aria-checked="false"]`)
        .should('have.length', 2)
        .each(($button) => expect($button.attr('tabindex')).to.equal('-1'))
    })

    it('moves selection with the arrow keys and saves the size it lands on', () => {
      enterEditMode()
      // `low_stock_items` is declared `medium`, so one step right is `large`.
      cy.get(`${picker} [aria-checked="true"]`).focus().type('{rightarrow}')

      cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'large')
      cy.get(`${picker} [data-widget-size="large"]`)
        .should('have.attr', 'aria-checked', 'true')
        .and('have.attr', 'tabindex', '0')
        .and('be.focused')

      cy.wait('@save').then((interception) => {
        const keys = submittedKeys(interception)
        expect(submittedSizes(interception)[keys.indexOf('low_stock_items')]).to.equal('large')
      })
    })

    // Selection following focus is only an improvement if it SAYS so: a screen
    // reader user arrowing through sizes otherwise gets four silent focus moves
    // and a dashboard that quietly relaid itself out four times.
    it('announces the size it lands on', () => {
      enterEditMode()
      cy.get(`${picker} [aria-checked="true"]`).focus().type('{rightarrow}')

      cy.get('[role="status"]').should('contain', 'Large')
    })

    // Wrapping is what makes a four-item ring feel closed rather than clamped.
    it('wraps from the last size back to the first', () => {
      enterEditMode()
      cy.get(`${picker} [data-widget-size="large"]`).click()
      cy.get(`${picker} [data-widget-size="large"]`).focus().type('{rightarrow}')

      cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'small')
    })

    it('jumps to the ends with Home and End', () => {
      enterEditMode()
      cy.get(`${picker} [aria-checked="true"]`).focus().type('{end}')
      cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'large')

      cy.get(`${picker} [aria-checked="true"]`).type('{home}')
      cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'small')
    })

    // The card's own arrow-key reorder listens on `.handle`. Arrowing inside the
    // picker must size the card, never move it — otherwise choosing a size would
    // silently rearrange the dashboard.
    it('does not reorder the card while arrowing through sizes', () => {
      enterEditMode()
      cy.get('.bali-widget-grid [data-widget-key]').first()
        .should('have.attr', 'data-widget-key', 'overdue_counts')

      cy.get(`${picker} [aria-checked="true"]`).focus().type('{rightarrow}')

      cy.get('.bali-widget-grid [data-widget-key]').first()
        .should('have.attr', 'data-widget-key', 'overdue_counts')
    })
  })

  it('removes a card, moves focus to a neighbour, and saves the rest', () => {
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-action="bali-widget-grid#remove"]').click()

    cy.get('[data-widget-key="low_stock_items"]').should('not.exist')
    cy.focused().should('have.class', 'handle')

    cy.wait('@save').then((interception) => {
      expect(submittedKeys(interception)).to.not.include('low_stock_items')
      expect(submittedKeys(interception)).to.have.length(3)
    })
  })

  // `move` announces "position X of Y". Removing announces the same running
  // total, which is the gesture where it matters most: there is one fewer card
  // to count and no visual grid for a screen-reader user to glance at.
  it('announces how many widgets are left after a removal', () => {
    enterEditMode()
    // Four specimens in the preview, so removing one leaves three.
    cy.get('[data-widget-key="low_stock_items"] [data-action="bali-widget-grid#remove"]').click()

    cy.get('[role="status"]').should('contain', '3 widgets remaining')
  })

  it('announces the singular when one widget is left', () => {
    enterEditMode()
    const remove = (key) =>
      cy.get(`[data-widget-key="${key}"] [data-action="bali-widget-grid#remove"]`).click()

    // Four specimens, so it takes three removals to leave exactly one.
    remove('low_stock_items')
    remove('expiring_stock')
    remove('cost_spikes')

    cy.get('[role="status"]').should('contain', '1 widget remaining')
    cy.get('[role="status"]').should('not.contain', '1 widgets')
  })

  // Emptying the grid means "never chose", so the server restores the defaults
  // and the controller reloads for them. Announcing "0 widgets remaining" would
  // name a state the user is about to not be in.
  it('announces the restore rather than a count of zero on the last removal', () => {
    enterEditMode()
    const remove = (key) =>
      cy.get(`[data-widget-key="${key}"] [data-action="bali-widget-grid#remove"]`).click()

    remove('low_stock_items')
    remove('expiring_stock')
    remove('cost_spikes')
    remove('overdue_counts')

    cy.get('[role="status"]').should('contain', 'restoring your default widgets')
    cy.get('[role="status"]').should('not.contain', '0 widgets')
  })

  it('collapses a held arrow key into one write', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle')
      .focus()
      .type('{rightarrow}{rightarrow}{rightarrow}')

    cy.wait('@save')
    // The debounce's trailing edge means the three presses are one PATCH; give
    // any second one time to arrive before asserting it did not.
    cy.wait(500)
    cy.get('@save.all').should('have.length', 1)
  })

  it('announces a failure rather than swallowing it', () => {
    cy.intercept('PATCH', '/widget_layout', { statusCode: 500, body: {} }).as('failedSave')
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="large"]').click()

    cy.wait('@failedSave')
    cy.get('[role="status"]').should('contain', "Couldn't save your changes")
  })

  // A 500 exercises `send`'s `if (!response.ok)` branch — `patch()` still
  // RESOLVES, just with `response.ok === false`. That never touches the
  // `catch`. `enqueue`'s own comment leans on "nothing rejects today, because
  // `send` try/catches and always resolves a boolean" as a load-bearing
  // invariant — this is the case that actually exercises it: a request that
  // never gets a response at all, which is what makes `patch()` REJECT.
  it('announces a failure when the request itself fails, not just a bad response', () => {
    cy.intercept('PATCH', '/widget_layout', { forceNetworkError: true }).as('networkError')
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="large"]').click()

    cy.wait('@networkError')
    cy.get('[role="status"]').should('contain', "Couldn't save your changes")
  })

  // Extra assertions #1 and #3 (from code review): drag is the one gesture
  // nobody had verified end-to-end, and the "+" tile shares the SortableList
  // with the cards, so a card dropped last could strand it mid-grid.
  //
  // `Bali::SortableList` does not set `forceFallback: true`, so on desktop
  // Chrome a MOUSE drag uses the native HTML5 DnD API, which neither a
  // mousedown/mousemove sequence nor synthetic dragstart/dragover/drop events
  // can drive (see cypress/e2e/sortable-list.cy.js, which documents the same
  // limitation for plain SortableList and deliberately does not attempt it).
  //
  // SortableJS binds `pointerdown` when `PointerEvent` exists, and a TOUCH
  // pointer routes into its JS fallback drag regardless of `forceFallback` —
  // that path synthetic PointerEvents CAN drive all the way to `onEnd`.
  // cypress/e2e/kanban-board.cy.js verified the same technique against real
  // Chrome and left the note this borrows. Reused here rather than invented,
  // since it is the one mechanism in this repo already proven to work.
  describe('dragging a card by its handle (touch-fallback pointer events)', () => {
    beforeEach(() => {
      enterEditMode()
      waitForSortable()
    })

    it('reorders the grid and persists the new sequence, without stranding the add tile', () => {
      cy.get('.bali-widget-grid > [data-widget-key]').then($before => {
        const before = [...$before].map(el => el.dataset.widgetKey)
        expect(before[0], 'sanity: starts first').to.equal('overdue_counts')

        cy.window().then(win => {
          const handle = win.document.querySelector('[data-widget-key="overdue_counts"] .handle')
          const target = win.document.querySelector('[data-widget-key="cost_spikes"]')
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
          const from = handle.getBoundingClientRect()
          const to = target.getBoundingClientRect()

          pointer('pointerdown', handle, from.x + from.width / 2, from.y + from.height / 2)
          return sleep(150)
            .then(() => {
              pointer('pointermove', win.document, from.x + 30, from.y + 10)
              return sleep(150)
            })
            .then(() => {
              // The right two-thirds of the last card — past SortableJS's
              // 0.65 swap threshold — so the drop lands AFTER it, not before.
              pointer('pointermove', win.document, to.x + to.width * 0.85, to.y + to.height / 2)
              return sleep(200)
            })
            .then(() => {
              pointer('pointerup', win.document, to.x + to.width * 0.85, to.y + to.height / 2)
            })
        })
      })

      // The card actually moved: it is no longer first, and the DOM order —
      // which is exactly what `writeSequence` reads — reflects the drop.
      cy.get('.bali-widget-grid > [data-widget-key]').then($after => {
        const after = [...$after].map(el => el.dataset.widgetKey)
        expect(after, 'order changed').to.not.deep.equal([
          'overdue_counts', 'low_stock_items', 'expiring_stock', 'cost_spikes'
        ])
        expect(after, 'still all four widgets').to.have.members([
          'overdue_counts', 'low_stock_items', 'expiring_stock', 'cost_spikes'
        ])
        // Dropped on the right 85% of the last card, past the swap threshold,
        // so it lands AFTER `cost_spikes` — at the back, not just "somewhere".
        expect(after[0], 'overdue_counts moved off the front').to.not.equal('overdue_counts')
        expect(after[after.length - 1], 'overdue_counts landed at the back').to.equal('overdue_counts')
      })

      // The reorder actually persisted: one PATCH, carrying the DOM's new order.
      cy.wait('@save').then((interception) => {
        cy.get('.bali-widget-grid > [data-widget-key]').then($cards => {
          const domOrder = [...$cards].map(el => el.dataset.widgetKey)
          expect(submittedKeys(interception)).to.deep.equal(domOrder)
        })
      })

      // Extra assertion #3: the "+" tile shares this SortableList and carries
      // no `.handle`, so nothing stops a card from landing after it — it is
      // pinned last only by `order: 9999` in widget_grid/index.css. Read the
      // COMPUTED style (proves the stylesheet is actually wired up) and the
      // rendered position (proves the pin actually wins visually), not the
      // class name alone.
      cy.get('.bali-widget-add-tile').should($tile => {
        expect(getComputedStyle($tile[0]).order, 'add tile pinned by CSS order').to.eq('9999')
      })
      cy.get('.bali-widget-grid > [data-widget-key]').last().then($lastCard => {
        cy.get('.bali-widget-add-tile').then($tile => {
          const cardRect = $lastCard[0].getBoundingClientRect()
          const tileRect = $tile[0].getBoundingClientRect()
          // Same row-ish, tile strictly to the right (or below, if wrapped) of
          // the last card — i.e. visually after it, not stranded mid-grid.
          const visuallyAfter = tileRect.top > cardRect.top ||
            (tileRect.top === cardRect.top && tileRect.left > cardRect.left)
          expect(visuallyAfter, 'add tile renders after the last card').to.eq(true)
        })
      })
    })
  })
})
