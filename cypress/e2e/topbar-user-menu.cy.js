import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// Bali::Topbar::UserMenu is a preset of Bali::Dropdown, so the point of this file is not
// to re-test the menu mechanics (dropdown-controller.cy.js owns those) but to prove the
// preset actually inherits them — the hand-rolled `<details class="dropdown">` it replaces
// had no keyboard, no Escape and no aria-expanded at all — plus what the preset adds: the
// presentational identity header, the sign-out `button_to` form, and a trigger and header
// that hold a long identity at any width.
describe('Topbar::UserMenu', () => {
  const userMenu = '.bali-topbar-user-menu'
  const trigger = '[data-dropdown-target="trigger"]'
  const menu = '[data-dropdown-target="menu"]'

  const press = (key) => cy.focused().trigger('keydown', { key, bubbles: true, force: true })

  // `display` and not `not.be.visible`: see docs/reference/testing-traps.md.
  const expectClosed = ($menu) => {
    expect($menu[0].ownerDocument.defaultView.getComputedStyle($menu[0]).display).to.equal('none')
  }

  beforeEach(() => {
    cy.visit('/bali/topbar/user_menu')
  })

  it('inherits the dropdown keyboard: open, arrows over menuitems only, Escape', () => {
    cy.get(userMenu).first().find(trigger).as('t')
    cy.get('@t').should('have.attr', 'aria-expanded', 'false')

    cy.get('@t').focus()
    cy.get('@t').should('have.attr', 'aria-expanded', 'false')

    // The name/email header is role="presentation": the first ArrowDown must land on
    // the first actionable item, not on the identity block.
    press('ArrowDown')
    cy.focused().should('have.attr', 'role', 'menuitem').and('contain', 'Profile')
    cy.get(userMenu).first().find(menu).should('be.visible')
    cy.get('@t').should('have.attr', 'aria-expanded', 'true')

    press('Escape')
    cy.focused().should('have.attr', 'data-dropdown-target', 'trigger')
    cy.get(userMenu).first().find(menu).should(expectClosed)
    cy.get('@t').should('have.attr', 'aria-expanded', 'false')
  })

  it('shows the identity header outside the menuitem list', () => {
    cy.get(userMenu).first().within(() => {
      cy.get('.bali-topbar-user-menu-header')
        .should('have.attr', 'role', 'presentation')
        .and('contain', 'Ana García López')
        .and('contain', 'ana@example.com')
    })
  })

  it('renders sign out as a real delete form, reachable with the arrows', () => {
    cy.get(userMenu).first().within(() => {
      cy.get('form input[name="_method"]').should('have.value', 'delete')
      cy.get('form button.bali-topbar-sign-out[role="menuitem"]').should('contain', 'Sign out')
    })

    cy.get(userMenu).first().find(trigger).focus()
    press('ArrowUp') // wraps to the last item, which must be sign out
    cy.focused().should('have.class', 'bali-topbar-sign-out')
  })

  it('renders no sign-out item when `sign_out:` was not given', () => {
    cy.get(userMenu).eq(2).within(() => {
      cy.get('.bali-topbar-sign-out').should('not.exist')
      cy.get('form').should('not.exist')
    })
  })

  const expectClippedWithin = (el, right) => {
    const style = el.ownerDocument.defaultView.getComputedStyle(el)
    expect(el.getBoundingClientRect().right, 'right edge').to.be.at.most(right)
    expect(el.scrollWidth, 'text width over box width').to.be.greaterThan(el.clientWidth)
    expect(style.overflowX, 'overflow-x').to.equal('hidden')
    expect(style.textOverflow, 'text-overflow').to.equal('ellipsis')
  }

  describe('with a long name and email', () => {
    const longMenu = () => cy.contains(userMenu, 'María Fernanda')

    it('caps the name in the trigger at 12rem, with an ellipsis', () => {
      cy.viewport(1280, 800)
      longMenu().find(trigger).contains('span', 'María Fernanda').should(($name) => {
        const name = $name[0]
        expect(name.getBoundingClientRect().width, 'name width').to.be.closeTo(192, 0.5)
        expectClippedWithin(name, name.closest(trigger).getBoundingClientRect().right)
      })
    })

    ;[320, 390, 1280].forEach((width) => {
      it(`wraps both header lines inside the panel at ${width}px`, () => {
        cy.viewport(width, 800)
        longMenu().find(trigger).click()
        longMenu().find(menu).should(($menu) => {
          expect($menu[0].getAnimations({ subtree: true })).to.have.length(0)
          const panelRight = $menu[0].getBoundingClientRect().right
          const header = $menu.find('.bali-topbar-user-menu-header')[0]
          const lines = $menu.find('.bali-topbar-user-menu-header > span').toArray()
          expect(lines).to.have.length(2)
          const underText = header.getBoundingClientRect().bottom - lines[1].getBoundingClientRect().bottom
          const paddingBottom = parseFloat(header.ownerDocument.defaultView.getComputedStyle(header).paddingBottom)
          expect(underText, 'header height under the email').to.be.closeTo(paddingBottom, 0.5)
          lines.forEach((line) => {
            const text = line.ownerDocument.createRange()
            text.selectNodeContents(line)
            const rects = [...text.getClientRects()]
            const textRight = Math.max(...rects.map((r) => r.right))
            expect(textRight, `${line.textContent} right edge`).to.be.at.most(line.getBoundingClientRect().right)
            expect(line.getBoundingClientRect().right, 'line right edge').to.be.at.most(panelRight)
            expect(new Set(rects.map((r) => Math.round(r.top))).size, 'lines of text').to.be.greaterThan(1)
          })
        })
      })
    })
  })

  // `app_layout/with_topbar` is the arrangement an app ships: hamburger, palette, two actions.
  it('fits its trigger inside a 320px topbar, and keeps the chevron inside it from sm up', () => {
    const chevron = `${userMenu} ${trigger} > .icon-component`
    const display = ($el) => $el[0].ownerDocument.defaultView.getComputedStyle($el[0]).display
    const contentRight = (el) => {
      const right = el.getBoundingClientRect().right
      return right - parseFloat(el.ownerDocument.defaultView.getComputedStyle(el).paddingRight)
    }

    cy.viewport(320, 640)
    cy.visit('/bali/app_layout/with_topbar')
    cy.get(`${userMenu} ${trigger}`).should(($t) => {
      expect($t[0].getBoundingClientRect().right).to.be.at.most(contentRight($t[0].closest('.bali-topbar')))
    })
    cy.get(chevron).should(($c) => expect(display($c)).to.equal('none'))

    cy.viewport(640, 640)
    cy.get(chevron).should(($c) => {
      expect(display($c)).not.to.equal('none')
      const triggerRight = $c[0].closest(trigger).getBoundingClientRect().right
      expect($c[0].getBoundingClientRect().right, 'chevron right edge').to.be.at.most(triggerRight)
    })
  })

  // With a third action the search well held at its 99px min-content and pushed the trigger
  // to x=321, 17px past the topbar's content edge: the search zone is the one that yields.
  it('fits its trigger inside a 320px topbar with a third action', () => {
    cy.viewport(320, 640)
    cy.visit('/bali/app_layout/with_topbar')
    cy.get('.bali-topbar .btn[aria-label="Help"]').then(($help) => {
      $help[0].after($help[0].cloneNode(true))
    })

    cy.get(`${userMenu} ${trigger}`).should(($t) => {
      const bar = $t[0].closest('.bali-topbar')
      expect(bar.querySelectorAll('.btn[aria-label="Help"]'), 'three actions').to.have.length(2)
      const contentRight = bar.getBoundingClientRect().right - parseFloat(getComputedStyle(bar).paddingRight)
      expect($t[0].getBoundingClientRect().right, 'trigger right edge').to.be.at.most(contentRight)
    })
    cy.get('.bali-command-trigger').should(($well) => {
      expect($well[0].scrollWidth, 'the label stays inside the search well').to.be.at.most($well[0].clientWidth)
    })
  })

  // daisyUI marks a focused `.menu` item with a 10% tint alone, 1.21–1.34:1 against the panel,
  // and the sign-out `button_to`, out of its reach, kept the browser's ring.
  THEMES.forEach((theme) => {
    it(`rings the item the keyboard is on at 3:1, ${theme} theme`, () => {
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
      cy.get(userMenu).first().find(trigger).focus()
      press('ArrowDown')
      cy.focused().should('contain', 'Profile')

      cy.get(userMenu).first().find(`${menu} [role^="menuitem"]`).should('have.length', 4).each(($item) => {
        cy.wrap($item).focus()
        cy.document().should((doc) => {
          expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
          const item = doc.activeElement
          const label = `${theme}: ${item.textContent.trim()}`
          expect(item.matches(':focus-visible'), `${label} has keyboard focus`).to.equal(true)
          expect(getComputedStyle(item).outlineStyle, `${label} ring drawn`).to.equal('solid')
          // Inset: the ring sits on the item's tint and borders the panel.
          expect(paintedContrast(item, { property: 'outlineColor' }), `${label} on its tint`).to.be.at.least(3)
          expect(paintedContrast(item, { over: item.closest(menu), property: 'outlineColor' }), `${label} on the panel`)
            .to.be.at.least(3)
        })
      })
    })
  })
})
