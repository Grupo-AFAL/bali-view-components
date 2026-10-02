import { THEMES } from '../support/themes'
import { paintedLuminance } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

// The point of the merge: the SAME controller drives the menu in both modes. In popover
// mode the menu is moved into a tippy popper on `<body>`, so every "is this mine?" question
// the controller asks — `this.element.contains`, the nested-dropdown guard, the item list —
// has to look in two places. Before, popover mode rendered a HoverCard around a string copy
// of the list and had no keyboard at all.
describe('DropdownController', () => {
  const cssDropdown = '[data-dropdown-popover-value="false"]'
  const popoverDropdown = '[data-dropdown-popover-value="true"]'
  const trigger = '[data-dropdown-target="trigger"]'
  const menu = '[data-dropdown-target="menu"]'

  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })

  // `display` and not `not.be.visible`: see docs/reference/testing-traps.md.
  const expectClosed = ($menu) => {
    expect($menu[0].ownerDocument.defaultView.getComputedStyle($menu[0]).display).to.equal('none')
  }

  context('CSS mode', () => {
    beforeEach(() => {
      cy.visit('/bali/dropdown/basic')
    })

    // #1231: daisyUI opens the CSS dropdown from `:focus-within`, so Tab alone unfolded it and
    // the Enter meant to open it closed it.
    it('does not open on focus', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()

      cy.get(cssDropdown).first().find(menu).should(expectClosed)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    // A Turbo morph that rewrites `class` takes `dropdown-close` with it, and `:focus-within`
    // opened the menu on focus again — #1231 back, now with `aria-expanded="false"`.
    it('does not open on focus after its classes are rewritten', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').then(($d) => $d[0].classList.remove('dropdown-close'))

      cy.get('@dropdown').find(trigger).focus()

      cy.get('@dropdown').find(menu).should(expectClosed)
    })

    ;['Enter', ' '].forEach((key) => {
      it(`opens on ${JSON.stringify(key)} and moves the focus to the first item`, () => {
        cy.get(cssDropdown).first().find(trigger).as('t')
        cy.get('@t').focus()

        press(key)

        cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Item 1')
        cy.get('@t').should('have.attr', 'aria-expanded', 'true')
      })
    })

    // The second click lands on the wrapper: daisyUI gives an open trigger
    // `pointer-events: none`. Clicked through Cypress's hit test, not forced onto the trigger.
    it('opens on a click and closes on a second one, keeping the focus on the trigger', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').find(trigger).as('t')

      cy.get('@t').click()
      cy.get('@dropdown').find(menu).should('be.visible')
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      cy.get('@dropdown').click('topLeft')
      cy.get('@dropdown').find(menu).should(expectClosed)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
    })

    // A Turbo morph that rewrites `class` takes `dropdown-close` away with everything else, and
    // read as "open" by `:focus-within`, the first click closed a menu nobody could see.
    it('opens on the first click after its classes are rewritten', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').then(($d) => $d[0].classList.remove('dropdown-close'))

      cy.get('@dropdown').find(trigger).click()

      cy.get('@dropdown').find(trigger).should('have.attr', 'aria-expanded', 'true')
      cy.get('@dropdown').should('have.class', 'dropdown-open')
    })

    // With `:focus-within` the menu was open from the `mousedown`, and the rich text editor's
    // link panel focuses its input from a click action on the trigger.
    it('is open by the time a click action on the trigger runs', () => {
      cy.get(cssDropdown).first().as('dropdown')
      cy.get('@dropdown').find(trigger).then(($t) => {
        const panel = $t[0].parentElement.querySelector(menu)
        $t[0].addEventListener('click', () => {
          $t[0].dataset.menuDisplay = $t[0].ownerDocument.defaultView.getComputedStyle(panel).display
        })
      })

      cy.get('@dropdown').find(trigger).click()

      cy.get('@dropdown').find(trigger).should(($t) => {
        expect($t[0].dataset.menuDisplay, 'menu display seen by the click action')
          .to.exist.and.not.equal('none')
      })
    })

    it('closes when the focus leaves it', () => {
      cy.get(cssDropdown).first().find(trigger).focus()
      press('Enter')
      cy.focused().should('contain', 'Item 1')

      cy.get('.dropdown-hover').find(trigger).focus()

      cy.get(cssDropdown).first().find(menu).should(expectClosed)
      cy.get(cssDropdown).first().find(trigger).should('have.attr', 'aria-expanded', 'false')
    })

    it('walks the items with the arrow keys', () => {
      cy.get(cssDropdown).first().find(trigger).focus()

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Item 1')

      press('ArrowDown')
      cy.focused().should('contain', 'Item 2')

      press('ArrowUp')
      cy.focused().should('contain', 'Item 1')
    })

    // Escape used to close the menu and then hand focus back to the trigger, which
    // re-opened it on the same frame through daisyUI's `:focus-within`. daisyUI's own
    // `.dropdown-close` is what makes the close stick without blurring the reader out.
    it('closes on Escape, keeps the focus on the trigger, and stays closed', () => {
      cy.get(cssDropdown).first().find(trigger).as('t')
      cy.get('@t').focus()
      press('ArrowDown')
      cy.focused().should('contain', 'Item 1')

      press('Escape')

      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
      cy.get(cssDropdown).first().find(menu).should(expectClosed)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    it('reopens with ArrowDown after an Escape', () => {
      cy.get(cssDropdown).first().find(trigger).focus()
      press('Escape')
      press('ArrowDown')

      cy.focused().should('contain', 'Item 1')
      cy.get(cssDropdown).first().find(trigger).should('have.attr', 'aria-expanded', 'true')
    })

    // A hover dropdown was the one shape with no controller at all, so its trigger reported
    // "collapsed" with the menu on screen and no key did anything.
    it('gives a hoverable dropdown the same keyboard', () => {
      cy.get('.dropdown-hover').find(trigger).as('t')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')

      cy.get('@t').focus()
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem')
    })

    // Enter sets `dropdown-open` on a hover dropdown too, and leaving it only dropped
    // `dropdown-close`, so the menu stayed open behind the reader.
    it('closes a hoverable dropdown opened with Enter once the focus leaves it', () => {
      cy.get('.dropdown-hover').find(trigger).focus()
      press('Enter')
      cy.focused().should('have.attr', 'role', 'menuitem')

      cy.get(cssDropdown).first().find(trigger).focus()

      cy.get('.dropdown-hover').find(menu).should(expectClosed)
      cy.get('.dropdown-hover').find(trigger).should('have.attr', 'aria-expanded', 'false')
    })
  })

  // Turbo caches the page with the menu as it was. Chromium blurs a focused node when Turbo
  // removes it, which closed the menu before the snapshot was taken; Firefox does not, and
  // Back brought it back open. Opened here with a click that moves no focus, so the
  // snapshot keeps it open in any browser.
  context('Turbo cache', () => {
    const appOrigin = new URL(Cypress.config('baseUrl')).origin
    const userMenu = '.bali-topbar-user-menu'

    it('comes back closed from a snapshot taken with the menu open', () => {
      cy.visit(`${appOrigin}/admin`)
      cy.window().then((win) => {
        win.notReloaded = true
        win.document.addEventListener('turbo:before-render', (event) => {
          win.restoredClasses = event.detail.newBody.querySelector(userMenu).className
        })
      })
      cy.get(`${userMenu} ${trigger}`).then(($t) => $t[0].click())
      cy.get(userMenu).should('have.class', 'dropdown-open')

      cy.window().then((win) => win.Turbo.visit('/admin/settings'))
      cy.location('pathname').should('eq', '/admin/settings')
      cy.go('back')
      cy.location('pathname').should('eq', '/admin')

      cy.window().its('notReloaded').should('eq', true)
      cy.window().its('restoredClasses').should('contain', 'dropdown-open')
      cy.get(`${userMenu} ${menu}`).should(expectClosed)
      cy.get(`${userMenu} ${trigger}`).should('have.attr', 'aria-expanded', 'false')
    })
  })

  context('popover mode', () => {
    beforeEach(() => {
      cy.visit('/bali/dropdown/basic')
      // tippy is a dynamic import; the menu leaves the wrapper once it resolves.
      cy.get(popoverDropdown).find(menu).should('not.exist')
    })

    it('moves the rendered menu rather than copying it', () => {
      cy.get(`[data-tippy-root] ${menu}`).should('have.length', 0)
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]').find(menu).should('exist')
      // One menu on the page, not an original plus a copy.
      cy.get(menu).filter(':visible').should('have.length', 1)
      cy.get(popoverDropdown).find(menu).should('not.exist')
    })

    it('keeps the menu semantics it was rendered with', () => {
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]')
        .find('[role="menu"]')
        .should('have.attr', 'aria-label', 'Dropdown menu')
      cy.get('[data-tippy-root]').find('[role="menuitem"]').should('have.length.at.least', 2)
    })

    it('syncs aria-expanded with the popper', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')

      cy.get('@t').click()
      cy.get('@t').should('have.attr', 'aria-expanded', 'true')

      // Not a second click on the trigger: the open panel covers it, which is exactly what
      // Cypress's actionability check is for. A click anywhere else is the way out.
      cy.get('body').click(5, 5)
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.get('[data-tippy-root]').should('not.exist')
    })

    it('opens with ArrowDown and walks the items inside the popper', () => {
      cy.get(popoverDropdown).find(trigger).focus()

      press('ArrowDown')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')

      press('ArrowDown')
      cy.focused().should('contain', 'Export')

      press('ArrowUp')
      cy.focused().should('contain', 'Edit')
    })

    it('opens on Enter and on Space with the focus on the first item', () => {
      cy.get(popoverDropdown).find(trigger).focus()
      press('Enter')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')

      press('Escape')
      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')

      press(' ')
      cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Edit')
    })

    // The popper hangs at the end of `<body>`, so the browser's Tab out of it went to the
    // wrong place. Handed back to the trigger, the browser's own Tab carries on from there.
    it('closes on Tab from inside the popper and hands the focus to the trigger', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').focus()
      press('Enter')
      cy.focused().should('contain', 'Edit')

      press('Tab')

      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
      cy.get('[data-tippy-root]').should('not.exist')
    })

    // Focus-out was ignored in popover mode, so Tab away left the popper up.
    it('closes when the focus leaves it', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').focus()
      press('Enter')
      cy.focused().should('contain', 'Edit')

      cy.get(cssDropdown).first().find(trigger).focus()

      cy.get('[data-tippy-root]').should('not.exist')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
    })

    // Same wrapper press as in the CSS mode: with focus-out now closing the popper, a blur on
    // that press closed it and the click reopened it.
    it('closes on a second click on its trigger', () => {
      cy.get(popoverDropdown).as('dropdown')
      cy.get('@dropdown').find(trigger).click()
      cy.get('[data-tippy-root]').should('exist')

      cy.get('@dropdown').click('topLeft')

      cy.get('[data-tippy-root]').should('not.exist')
      cy.get('@dropdown').find(trigger).should('have.attr', 'aria-expanded', 'false')
    })

    it('closes on Escape from inside the popper and returns the focus to the trigger', () => {
      cy.get(popoverDropdown).find(trigger).as('t')
      cy.get('@t').focus()
      press('ArrowDown')
      cy.focused().should('contain', 'Edit')

      press('Escape')

      cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
      cy.get('@t').should('have.attr', 'aria-expanded', 'false')
      cy.get('[data-tippy-root]').should('not.exist')
    })

    // The whole reason `popover:` exists. `overflow-x-auto` clips on both axes — CSS turns
    // the other one into `auto` as soon as one of them is not `visible` — so a menu taller
    // than its row is cut off in the flow.
    it('escapes the clipping ancestor', () => {
      cy.get(popoverDropdown).find(trigger).click()

      cy.get('[data-tippy-root]').should(($popper) => {
        expect($popper[0].parentElement.tagName).to.eq('BODY')
      })

      cy.get(popoverDropdown).closest('.overflow-x-auto').then(($box) => {
        cy.get('[data-tippy-root]').should(($popper) => {
          const popper = $popper[0].getBoundingClientRect()
          const box = $box[0].getBoundingClientRect()
          const contained = popper.top >= box.top && popper.bottom <= box.bottom &&
                            popper.left >= box.left && popper.right <= box.right
          expect(contained, 'menu rect fits inside the scroll box').to.eq(false)
        })
      })
    })
  })

  // #1231: daisyUI anchors the panel to one edge of the trigger and never looks at the screen.
  // The page ⋯ is `align: :end`; below `sm` its row wraps and the trigger lands at the left of
  // it (IndexPage) or mid-row (ShowPage, after three actions), where its w-80 menu opened at
  // x = −216 and x = −120.
  context('inside the viewport', () => {
    const pageMenu = '[data-controller~="export-links"]'

    // 5px from each edge, less half a pixel for subpixel layout.
    const expectOnScreen = ($menu) => {
      expect($menu[0].getAnimations({ subtree: true })).to.have.length(0)
      const { left, right } = $menu[0].getBoundingClientRect()
      const width = $menu[0].ownerDocument.documentElement.clientWidth
      expect(left, 'left edge').to.be.at.least(4.5)
      expect(right, 'right edge').to.be.at.most(width - 4.5)
    }

    ;[390, 1280].forEach((width) => {
      context(`at ${width}px`, () => {
        beforeEach(() => cy.viewport(width, 800))

        ;[
          ['/bali/index_page/with_secondary_actions', 'IndexPage'],
          ['/bali/show_page/with_secondary_actions', 'ShowPage']
        ].forEach(([path, page]) => {
          it(`opens the ${page} ⋯ menu on screen`, () => {
            cy.visit(path)
            cy.get(`${pageMenu} ${trigger}`).click()

            cy.get(`${pageMenu} ${menu}`).should('be.visible').and(expectOnScreen)
          })
        })

        ;['#viewport-edge-end', '#viewport-edge-start'].forEach((dropdown) => {
          it(`opens ${dropdown} on screen`, () => {
            cy.visit('/bali/dropdown/alignments')
            cy.get(`${dropdown} ${trigger}`).click()

            cy.get(`${dropdown} ${menu}`).should('be.visible').and(expectOnScreen)
          })
        })
      })
    })
  })

  // The panel is base-100 like the page under it, so its only edge was the shadow, which a dark
  // theme swallows: panel and page measured 1.00:1. The border is what a reader sees end where
  // the menu ends.
  context('panel edge', () => {
    afterEach(() => { unhover() })

    const edgeContrast = (panel) => {
      const doc = panel.ownerDocument
      const style = (el) => doc.defaultView.getComputedStyle(el)
      const page = style(doc.body).backgroundColor
      const [hi, lo] = [paintedLuminance(doc, page, style(panel).borderTopColor), paintedLuminance(doc, page)]
        .sort((a, b) => b - a)
      return (hi + 0.05) / (lo + 0.05)
    }

    THEMES.forEach((theme) => {
      it(`draws an edge the page does not swallow on the ${theme} theme`, () => {
        cy.visit('/bali/dropdown/basic')
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
        cy.get(cssDropdown).first().find(trigger).click()

        cy.get(cssDropdown).first().find(menu).should(($menu) => {
          const style = $menu[0].ownerDocument.defaultView.getComputedStyle($menu[0])
          expect(parseFloat(style.borderTopWidth), 'border width').to.be.at.least(1)
          expect(edgeContrast($menu[0]), `${theme}: edge against the page`).to.be.above(1.2)
        })
      })
    })

    // Its items share `.menu .menu-item:hover` with the SideMenu: base-200 stepped down on
    // the dark themes and the hovered item read 1.05:1 against the panel.
    THEMES.forEach((theme) => {
      it(`shows the hovered item against the panel on the ${theme} theme`, () => {
        cy.visit('/bali/dropdown/basic')
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
        cy.get(cssDropdown).first().find(trigger).click()
        cy.get(cssDropdown).first().find(`${menu} .menu-item`).first().then(hover)

        cy.get(cssDropdown).first().find(menu).should(($menu) => {
          const doc = $menu[0].ownerDocument
          const style = (el) => doc.defaultView.getComputedStyle(el)
          const item = $menu[0].querySelector('.menu-item:hover')
          expect(item, 'an item under the pointer').to.not.equal(null)

          const panel = style($menu[0]).backgroundColor
          const [hi, lo] = [paintedLuminance(doc, panel, style(item).backgroundColor), paintedLuminance(doc, panel)]
            .sort((a, b) => b - a)
          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
          expect((hi + 0.05) / (lo + 0.05), `${theme}: hovered item against the panel`).to.be.at.least(1.15)
        })
      })
    })
  })
})
