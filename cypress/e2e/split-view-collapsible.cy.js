// `collapsible: true`: the master alone until a detail arrives, the detail
// sliding in beside it, «Close» / Esc / «Back» giving the master the width
// back. Against the `collapsible` preview, whose rows load the detail through
// the Turbo Frame as any SplitView's do.
describe('SplitView collapsible', () => {
  const split = () => cy.get('.split-view-component--collapsible')
  const pane = () => cy.get('.split-view-detail-pane')
  const frame = () => cy.get('turbo-frame#split-view-detail')
  const row = (index) => cy.get('.split-view-item').eq(index)
  const masterWidth = () => cy.get('.split-view-master').invoke('outerWidth')

  const open = (index = 1) => {
    row(index).click()
    split().should('have.attr', 'data-split-state', 'open')
    cy.get('[data-testid="detail-title"]').should('be.visible')
  }

  context('from lg up', () => {
    beforeEach(() => {
      cy.viewport(1440, 900)
      cy.visit('/bali/split_view/collapsible')
      row(1).should('be.visible')
    })

    it('starts closed: the master takes the whole width and the pane is out of reach', () => {
      split().should('have.attr', 'data-split-state', 'closed')
      pane().should('have.prop', 'inert', true).and('have.attr', 'aria-hidden', 'true')
      split().invoke('outerWidth').then((width) => masterWidth().should('be.closeTo', width, 2))
    })

    it('opens on a row click, shrinks the master and focuses the detail', () => {
      cy.window().then((win) => {
        win.splitEvents = []
        win.document.addEventListener('split-view:open', () => win.splitEvents.push('open'))
      })
      open()
      pane().should('have.prop', 'inert', false).and('have.attr', 'aria-hidden', 'false')
      masterWidth().should('be.closeTo', 420, 2)
      cy.focused().should('have.attr', 'data-testid', 'detail-title')
      cy.window().its('splitEvents').should('deep.equal', ['open'])
    })

    it('closes with «Close»: empties the frame, clears the row and returns the focus to it', () => {
      cy.window().then((win) => {
        win.splitEvents = []
        win.document.addEventListener('split-view:close', () => win.splitEvents.push('close'))
      })
      open()
      cy.get('[data-testid="split-view-back"]').should('not.be.visible')
      cy.get('[data-testid="split-view-close"]').should('be.visible').click()
      split().should('have.attr', 'data-split-state', 'closed')
      frame().should('not.have.attr', 'src')
      frame().children().should('have.length', 0)
      cy.get('.split-view-row[aria-current]').should('not.exist')
      cy.focused().should('have.class', 'split-view-item')
      cy.window().its('splitEvents').should('deep.equal', ['close'])
      split().invoke('outerWidth').then((width) => masterWidth().should('be.closeTo', width, 2))
    })

    it('closes with Esc, and the same row opens it again', () => {
      open()
      cy.get('body').type('{esc}')
      split().should('have.attr', 'data-split-state', 'closed')
      frame().children().should('have.length', 0)
      open()
    })

    // The response is held until `release()`: what shows before it is the
    // loading state, not a detail that has already landed.
    const holdDetail = () => {
      const held = {}
      cy.intercept({ method: 'GET', pathname: '/split-view' }, (req) => new Promise((resolve) => {
        held.release = resolve
      }).then(() => req.continue())).as('detail')
      return held
    }

    it('opens at once with a loading state while the detail is fetched', () => {
      const held = holdDetail()
      row(1).click()
      // Shorter than the intercept's own timeout, so a pane that does not open fails here.
      cy.get('.split-view-component--collapsible', { timeout: 2000 }).should('have.attr', 'data-split-state', 'open')
      pane().should('have.attr', 'data-split-load', 'loading').and('have.attr', 'aria-busy', 'true')
      cy.get('[data-split-view-collapse-target="loading"]').should('be.visible')
        .and('contain', 'Loading…').closest('[role="status"]').should('exist')
      cy.get('[data-testid="split-view-close"]').should('be.visible')
      cy.get('[data-testid="detail-title"]').should('not.exist')
      cy.then(() => held.release())
      cy.wait('@detail')
      cy.get('[data-testid="detail-title"]').should('be.visible')
      pane().should('not.have.attr', 'data-split-load')
      cy.get('[data-split-view-collapse-target="loading"]').should('not.be.visible')
      cy.focused().should('have.attr', 'data-testid', 'detail-title')
    })

    it('discards the response that lands after «Close»', () => {
      const held = holdDetail()
      row(1).click()
      cy.get('.split-view-detail-pane', { timeout: 2000 }).should('have.attr', 'data-split-load', 'loading')
      cy.get('[data-testid="split-view-close"]').click()
      split().should('have.attr', 'data-split-state', 'closed')
      cy.then(() => held.release())
      cy.wait(800)
      split().should('have.attr', 'data-split-state', 'closed')
      cy.get('[data-testid="detail-title"]').should('not.exist')
      pane().should('not.have.attr', 'data-split-load')
    })

    it('shows the error with «Retry» when the detail fails, and retries it', () => {
      let fail = true
      cy.intercept({ method: 'GET', pathname: '/split-view' }, (req) => {
        if (fail) req.reply({ statusCode: 500, body: 'boom' })
        else req.continue()
      }).as('detail')
      row(1).click()
      cy.wait('@detail')
      split().should('have.attr', 'data-split-state', 'open')
      pane().should('have.attr', 'data-split-load', 'error')
      cy.get('[data-split-view-collapse-target="error"]').should('be.visible').and('have.attr', 'role', 'alert')
        .and('contain', 'The detail could not be loaded.')
      cy.get('[data-testid="split-view-close"]').should('be.visible')
      cy.then(() => { fail = false })
      cy.get('[data-testid="split-view-retry"]').click()
      cy.wait('@detail')
      cy.get('[data-testid="detail-title"]').should('be.visible')
      pane().should('not.have.attr', 'data-split-load')
      cy.get('[data-split-view-collapse-target="error"]').should('not.be.visible')
    })

    it('leaves Esc to an open dialog', () => {
      open()
      cy.document().then((doc) => {
        const dialog = doc.createElement('div')
        dialog.setAttribute('role', 'dialog')
        dialog.tabIndex = -1
        doc.body.append(dialog)
        dialog.focus()
      })
      cy.focused().type('{esc}')
      split().should('have.attr', 'data-split-state', 'open')
    })

    // A field lets go of its text, a listbox (an open SlimSelect) closes.
    // Counted on `split-view:close`: a pane closed by that Esc can open again
    // before an assertion on its state reads it.
    const countCloses = () => split().then(($split) => {
      $split[0].closes = 0
      $split[0].addEventListener('split-view:close', () => { $split[0].closes++ })
    })
    const closes = () => split().its('0.closes')

    ;[
      ['a text field', '<input type="text">'],
      ['a note being written', '<textarea></textarea>'],
      ['an editable region', '<div contenteditable="true"></div>'],
      ['an open listbox', '<div role="listbox" tabindex="-1"></div>']
    ].forEach(([what, html]) => {
      it(`leaves Esc to ${what} in the detail`, () => {
        open()
        countCloses()
        frame().then(($frame) => {
          $frame[0].insertAdjacentHTML('beforeend', html)
          $frame[0].lastElementChild.focus()
        })
        cy.focused().type('{esc}')
        closes().should('eq', 0)
        split().should('have.attr', 'data-split-state', 'open')
      })
    })

    // A widget mounted after the controller (the BPMN editor, cancelling
    // Connect) listens on document too, and takes the key with preventDefault.
    it('leaves Esc to a widget that took it on document', () => {
      open()
      countCloses()
      cy.document().then((doc) => {
        doc.addEventListener('keydown', (event) => { if (event.key === 'Escape') event.preventDefault() })
      })
      cy.focused().type('{esc}')
      closes().should('eq', 0)
      split().should('have.attr', 'data-split-state', 'open')
    })
  })

  it('is a full-screen sheet with «Back» below lg', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/split_view/collapsible')
    open()
    pane().should('have.css', 'position', 'fixed').and(($pane) => {
      const box = $pane[0].getBoundingClientRect()
      expect(box.left, 'left').to.be.closeTo(0, 1)
      expect(box.width, 'width').to.be.closeTo(390, 1)
    })
    cy.get('[data-testid="split-view-close"]').should('not.be.visible')
    cy.get('[data-testid="split-view-back"]').should('be.visible').click()
    split().should('have.attr', 'data-split-state', 'closed')
    pane().should('not.be.visible')
  })

  context('under prefers-reduced-motion', () => {
    const reducedMotion = (value) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setEmulatedMedia',
      params: { features: [{ name: 'prefers-reduced-motion', value }] }
    }))

    beforeEach(() => reducedMotion('reduce'))
    afterEach(() => reducedMotion(''))

    it('changes state without animating', () => {
      cy.viewport(1440, 900)
      cy.visit('/bali/split_view/collapsible')
      cy.window().should((win) => {
        expect(win.matchMedia('(prefers-reduced-motion: reduce)').matches, 'reduced motion emulated').to.equal(true)
      })
      split().should('have.css', 'transition-duration', '0s')
      pane().should('have.css', 'transition-duration', '0s')
      open()
      // At once: the 300 ms the animation would take is not waited for.
      masterWidth().should('be.closeTo', 420, 2)
      cy.get('[data-testid="split-view-close"]').click()
      frame().children({ timeout: 100 }).should('have.length', 0)
    })
  })
})

// `master_width: :equal` and `height: :screen | "<length>"`, with the
// collapsible detail open.
describe('SplitView height and width options', () => {
  const split = () => cy.get('.split-view-component')
  const box = (selector) => cy.get(selector).then(($el) => $el[0].getBoundingClientRect())
  const openFirst = () => {
    cy.get('.split-view-item').eq(1).click()
    split().should('have.attr', 'data-split-state', 'open')
    cy.wait(400) // the 300 ms slide, and the hold after it
  }
  const sameWidths = () => box('.split-view-master').then((master) => {
    box('.split-view-detail-pane').then((detail) => {
      expect(detail.width, 'detail width').to.be.closeTo(master.width, 1)
    })
  })

  beforeEach(() => cy.viewport(1440, 900))

  it('makes the two columns the same width with :equal, open and after opening again', () => {
    cy.visit('/bali/split_view/collapsible?master_width=equal')
    openFirst()
    sameWidths()
    cy.get('[data-testid="split-view-close"]').click()
    split().should('have.attr', 'data-split-state', 'closed')
    openFirst()
    sameWidths()
  })

  // The host's room below the split (its page's bottom padding), set once on
  // the page and inherited.
  it('stops --bali-split-bottom above the bottom of the viewport with :screen', () => {
    cy.visit('/bali/split_view/collapsible?height=screen')
    cy.document().then((doc) => doc.documentElement.style.setProperty('--bali-split-bottom', '24px'))
    cy.window().should((win) => {
      const bottom = win.document.querySelector('.split-view-component').getBoundingClientRect().bottom
      expect(bottom, 'bottom').to.be.closeTo(win.innerHeight - 24, 2)
    })
  })

  it('fills to the bottom of the viewport with :screen, and follows a resize', () => {
    cy.visit('/bali/split_view/collapsible?height=screen')
    cy.window().then((win) => {
      box('.split-view-component').its('bottom').should('be.closeTo', win.innerHeight, 2)
    })
    cy.viewport(1440, 700)
    cy.window().should((win) => {
      const bottom = win.document.querySelector('.split-view-component').getBoundingClientRect().bottom
      expect(bottom, 'bottom after the resize').to.be.closeTo(win.innerHeight, 2)
    })
    openFirst()
    box('.split-view-detail-pane').then((pane) => {
      box('.split-view-component').then((container) => expect(pane.height, 'detail height').to.be.closeTo(container.height, 1))
    })
  })

  it('keeps --bali-split-min-h on a short viewport', () => {
    cy.viewport(1440, 400)
    cy.visit('/bali/split_view/collapsible?height=screen')
    box('.split-view-component').its('height').should('be.closeTo', 448, 1) // 28rem
  })

  it('takes a fixed height', () => {
    cy.visit('/bali/split_view/collapsible?height=640px')
    box('.split-view-component').its('height').should('be.closeTo', 640, 1)
  })
})
