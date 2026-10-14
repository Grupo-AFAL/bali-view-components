// `height: :full` against its documented pairing, an AppLayout with `viewport_locked: true`.
// Like SplitView's (split-view-full-height.cy.js) it is `height: 100%` and a flex chain, so
// the result is the only thing worth measuring.
describe('ShowPage height: :full', () => {
  const PREVIEW = '/bali/show_page/full_height/default'
  const LONG_TITLE =
    'Discovery interview with the operations team about the weekly progress report the steering committee reads every Tuesday'

  const rect = $el => $el[0].getBoundingClientRect()

  // Measured against `<main>`, the bounded box, and not the body container: a container that
  // grows with its content wraps the body too, and the assertion would pass while the page
  // scrolls. What is left under the body is the container's padding.
  const expectBodyToReachTheBottom = () => {
    cy.get('.app-layout-body-container').then(($container) => {
      const padding = parseFloat(getComputedStyle($container[0]).paddingBottom)
      cy.get('main').then(($main) => {
        cy.get('.show-page-component > :last-child').then(($body) => {
          expect(rect($main).bottom - padding - rect($body).bottom, 'body to the bottom of main')
            .to.be.closeTo(0, 1)
        })
      })
    })
  }

  const gapUnderHeader = () =>
    cy.get('.show-page-component > .page-header-component').then(($header) =>
      cy.get('.show-page-component > :last-child').then(($body) =>
        rect($body).top - rect($header).bottom
      )
    )

  beforeEach(() => {
    cy.viewport(1280, 800)
  })

  it('fills what the header leaves of the locked viewport', () => {
    cy.visit(PREVIEW)
    cy.get('.show-page-component').should('have.class', 'show-page-component--full')

    expectBodyToReachTheBottom()
    cy.get('.show-page-component > :last-child').then(($body) => {
      cy.get('.bali-chat').then(($chat) => {
        expect(rect($chat).bottom, 'the chat fills the body').to.be.closeTo(rect($body).bottom, 1)
      })
    })
    cy.get('main').then(($main) => {
      expect($main[0].scrollHeight, 'the page does not scroll').to.be.at.most($main[0].clientHeight + 1)
    })
    cy.get('#interview-messages').then(($messages) => {
      expect($messages[0].scrollHeight, 'the conversation scrolls inside the chat')
        .to.be.greaterThan($messages[0].clientHeight + 100)
    })
  })

  it('still fills when the title wraps', () => {
    cy.visit(`${PREVIEW}?title=${encodeURIComponent(LONG_TITLE)}`)
    cy.get('.page-header-component .title').then(($title) => {
      const lineHeight = parseFloat(getComputedStyle($title[0]).lineHeight)
      expect(Math.round(rect($title).height / lineHeight), 'title lines').to.be.at.least(2)
    })

    expectBodyToReachTheBottom()
  })

  // A flex column does not collapse margins: without the header giving up its `mb-4`, the gap
  // measured 40px against the 24 of the same page at `height: :content`.
  it('keeps the gap under the header of the default height', () => {
    cy.visit(`${PREVIEW}?height=content`)
    gapUnderHeader().then((contentGap) => {
      cy.visit(PREVIEW)
      gapUnderHeader().then((fullGap) => {
        expect(fullGap, 'gap under the header').to.be.closeTo(contentGap, 0.5)
      })
    })
  })

  it('leaves AppLayout alone around a page at the default height', () => {
    cy.visit(`${PREVIEW}?height=content`)
    cy.get('body').should('have.class', 'app-layout--viewport-locked')

    cy.get('main').should('have.css', 'display', 'block')
    cy.get('.app-layout-body-container').should('have.css', 'flex-grow', '0')
  })

  // A flex item with auto margins does not stretch: `:contained` centers the container with
  // `mx-auto`, and before `width: 100%` it shrank to its content.
  it('keeps a contained body container as wide as its max-width', () => {
    cy.viewport(1440, 800)
    cy.visit(`${PREVIEW}?body_container=contained`)

    cy.get('.app-layout-body-container').then(($container) => {
      expect(rect($container).width, 'container width')
        .to.be.closeTo(parseFloat(getComputedStyle($container[0]).maxWidth), 1)
      cy.get('main').then(($main) => {
        expect(rect($container).left - rect($main).left, 'centred')
          .to.be.closeTo(rect($main).right - rect($container).right, 1)
      })
    })
    expectBodyToReachTheBottom()
  })

  // The AppLayout pair is shared with SplitView (app_layout/index.css), so relaxing its `>`
  // shows up here as well as in split-view-full-height.cy.js.
  it('stops applying when the page is not a direct child', () => {
    cy.visit(PREVIEW)
    cy.get('main').should('have.css', 'display', 'flex')

    cy.document().then((doc) => {
      const page = doc.querySelector('.show-page-component')
      const wrapper = doc.createElement('div')
      page.parentElement.appendChild(wrapper)
      wrapper.appendChild(page)
    })

    cy.get('main').should('have.css', 'display', 'block')
    cy.get('.app-layout-body-container').should('have.css', 'flex-grow', '0')
  })

  it('fills nothing without a bounded ancestor', () => {
    cy.visit(`${PREVIEW}?viewport_locked=false`)
    cy.get('body').should('not.have.class', 'app-layout--viewport-locked')

    cy.get('#interview-messages').then(($messages) => {
      expect($messages[0].scrollHeight, 'the chat grows with the conversation')
        .to.be.at.most($messages[0].clientHeight + 1)
    })
    cy.document().then((doc) => {
      expect(doc.documentElement.scrollHeight, 'the page scrolls instead')
        .to.be.greaterThan(doc.documentElement.clientHeight)
    })
  })

  it('does nothing below lg', () => {
    cy.viewport(375, 800)
    cy.visit(PREVIEW)

    cy.get('.show-page-component').should('have.css', 'display', 'block')
    cy.get('.show-page-component > .page-header-component').should('have.css', 'margin-bottom', '16px')
    cy.get('#interview-messages').then(($messages) => {
      expect($messages[0].scrollHeight, 'the chat grows with the conversation')
        .to.be.at.most($messages[0].clientHeight + 1)
    })
  })
})
