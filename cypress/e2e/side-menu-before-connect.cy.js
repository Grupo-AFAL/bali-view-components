// The sidebar as the server renders it, with no controller to correct it: before the bundle
// arrives, and after a Turbo morph refresh. A pinned sidebar is the app's navigation in both —
// gobierno-corporativo ships 6.3 MB of bundle over the wire, one cold download measured at
// 41 s, and afal-apps morphs four of its pages on every refresh.
const PREVIEW = '/bali/app_layout/default'
const PREVIEW_WITH_OPEN_GROUP = '/bali/side_menu/ecommerce'
const SIDEBAR = '.side-menu-component'
const LINK = `${SIDEBAR} .sidebar-menu a[href]`
const GROUP_CONTENT = `${SIDEBAR} input[type="checkbox"]:checked ~ .collapse-content`
const DAISYUI_FALLBACK =
  '.collapse:not(td,tr,colgroup):not(.collapse-close)>:where(input:is([type=checkbox],[type=radio]):checked~.collapse-content)'

const describeNode = node => `${node.tagName}.${node.className}`

const assertLinkTakesClicks = () => {
  cy.get(LINK).filter(':visible').first().then(($link) => {
    const link = $link[0]
    const rect = link.getBoundingClientRect()
    const hit = link.ownerDocument.elementFromPoint(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2
    )

    expect(link.contains(hit), `the click lands on ${describeNode(hit)}`).to.equal(true)
  })
}

describe('SideMenu before its controller connects', () => {
  beforeEach(() => {
    cy.intercept(
      { pathname: /\/assets\/application-[^/]+\.js$/ },
      { body: '', headers: { 'content-type': 'text/javascript' } }
    ).as('bundle')
  })

  const visitWithoutBundle = (preview = PREVIEW) => {
    cy.visit(preview)
    cy.wait('@bundle')
    cy.window().then(win => expect(win.Stimulus, 'Stimulus started').to.equal(undefined))
  }

  it('takes clicks at desktop widths', () => {
    cy.viewport(1280, 800)
    visitWithoutBundle()

    assertLinkTakesClicks()
  })

  // With an open group, under the rule daisyUI emits for a browser without
  // `content-visibility` (Safari before 18), copied from its compiled output: the group's
  // content declares `visibility: visible` itself, which a hidden ancestor does not stop.
  it('keeps the closed mobile drawer out of the tab order', () => {
    cy.viewport('iphone-x')
    visitWithoutBundle(PREVIEW_WITH_OPEN_GROUP)

    cy.document().then((doc) => {
      const fallback = doc.createElement('style')
      fallback.textContent = `${DAISYUI_FALLBACK}{visibility:visible}`
      doc.head.appendChild(fallback)
    })
    // `.collapse-content` transitions its own `visibility`, so the injected rule lands 0.2 s
    // later; in the real browser it is there from the first paint.
    cy.get(GROUP_CONTENT).should('have.css', 'visibility', 'visible')

    cy.document().then((doc) => {
      const controls = [...doc.querySelectorAll(`${SIDEBAR} a[href], ${SIDEBAR} button`)]
      const reachable = controls.filter((control) => {
        control.focus()
        return doc.activeElement === control
      })

      expect(reachable.map(describeNode), 'controls that take focus').to.deep.equal([])
    })
  })
})

describe('SideMenu after a Turbo morph refresh', () => {
  it('still takes clicks at desktop widths', () => {
    cy.viewport(1280, 800)
    cy.visit(PREVIEW)
    cy.get(SIDEBAR).should('not.have.attr', 'data-side-menu-booting')

    // Morph strips attributes the server did not render, so this one going is the sign the
    // refresh has been applied to the same element.
    cy.get(SIDEBAR).then(($nav) => {
      $nav[0].setAttribute('data-before-refresh', '')
      cy.wrap($nav[0]).as('navBefore')
    })
    cy.document().then((doc) => {
      doc.head.insertAdjacentHTML('beforeend', '<meta name="turbo-refresh-method" content="morph">')
    })
    cy.window().then(win => win.Turbo.session.refresh(win.location.href))

    cy.get(SIDEBAR).should('not.have.attr', 'data-before-refresh')
    cy.get('@navBefore').then(($before) => {
      cy.get(SIDEBAR).should(($nav) => expect($nav[0], 'morphed in place').to.equal($before[0]))
    })
    assertLinkTakesClicks()
  })
})
