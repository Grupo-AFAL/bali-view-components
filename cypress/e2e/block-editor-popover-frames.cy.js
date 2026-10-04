import { contrastRatio, paintedLuminance } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// One frame per popover of the BlockEditor. Bali used to draw its own around every Mantine popover
// and, around the file panel BlockNote already frames, that made two (#1313). The emoji picker of
// a comment reaction is emoji-mart's and has none: its edge against the page was a soft shadow,
// 1.00:1 on afal and 1.02 on afal-dark, so it draws a ring of its own (#1303).
describe('BlockEditor popover frames', () => {
  // The floor base-surface-steps.cy.js holds a panel's edge to: above a base-300 edge on afal.
  const EDGE = 1.25

  afterEach(() => cy.then(unhover))

  const settled = (doc) => expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
  const style = (el) => el.ownerDocument.defaultView.getComputedStyle(el)

  // Once a run has taken a failure screenshot, Electron leaves Mantine's fade-in at `opacity: 0`
  // (docs/reference/testing-traps.md).
  const withoutFade = (selector) => cy.document().then((doc) => {
    doc.head.insertAdjacentHTML('beforeend', `<style>${selector} { transition: none !important }</style>`)
  })

  // The ring is a box-shadow with no offset and no blur: its colour is read off the computed style
  // and painted over the page.
  const ringOnPage = (el) => {
    const doc = el.ownerDocument
    const page = style(doc.body).backgroundColor
    const ring = style(el).boxShadow.split(/,(?![^(]*\))/).find(shadow => /\s0px 0px 0px [1-9]/.test(shadow))
    if (!ring) return 1
    const colour = ring.trim().match(/^[a-z-]+\([^)]*\)/)[0]
    return contrastRatio(paintedLuminance(doc, page, colour), paintedLuminance(doc, page))
  }

  THEMES.forEach((theme) => {
    it(`draws the ring of a comment's emoji picker off the page on the ${theme} theme`, () => {
      cy.viewport(1280, 900)
      cy.visit('/bali/block_editor/with_comments')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
      withoutFade('.bn-emoji-picker-popover')
      cy.get('.bn-editor .bn-thread-mark').first().click()
      cy.get('[data-floating-ui-portal] .bn-thread .bn-thread-comment').first().then(hover)
      cy.get('[data-floating-ui-portal] .bn-thread [data-test="addreaction"]').first().click()

      cy.get('.bn-emoji-picker-popover').should('have.css', 'opacity', '1')
      cy.get('.bn-emoji-picker-popover em-emoji-picker').should(($picker) => {
        settled($picker[0].ownerDocument)
        expect(ringOnPage($picker[0]), `${theme}: the emoji picker's ring against the page`).to.be.above(EDGE)
      })
    })
  })

  // DocumentEditor's comments panel hangs outside `.block-editor-component`, which the rule is
  // scoped to; the picker a comment there opens is portaled back inside it, into the editor's
  // `.bn-root`. The preview's threads come from a database the seeds leave empty.
  it("draws the ring of the emoji picker opened from DocumentEditor's comments panel", () => {
    const timestamps = { created_at: '2026-08-02T17:43:55Z', updated_at: '2026-08-02T17:44:10Z' }
    cy.intercept('GET', /\/block_editor_comments(\?|$)/, {
      body: [{
        id: 1,
        resolved: false,
        metadata: {},
        ...timestamps,
        comments: [{
          id: 1,
          user_id: 'user-2',
          metadata: {},
          deleted_at: null,
          reactions: [],
          ...timestamps,
          body: [{ id: 'stub-comment-1', type: 'paragraph', props: {}, content: [{ type: 'text', text: 'Looks good to me', styles: {} }], children: [] }]
        }]
      }]
    }).as('threads')
    cy.viewport(1280, 900)
    cy.visit('/bali/document_editor/default')
    cy.wait('@threads')
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', 'afal'))
    withoutFade('.bn-emoji-picker-popover')
    cy.get('[data-action*="document-editor#toggleComments"]:visible').first().click()
    cy.get('[data-document-editor-target="commentsList"] .bn-thread-comment').first().then(hover)
    cy.get('[data-document-editor-target="commentsList"] [data-test="addreaction"]').first().click()

    cy.get('.bn-emoji-picker-popover').should('have.css', 'opacity', '1')
    cy.get('.bn-emoji-picker-popover em-emoji-picker').should(($picker) => {
      settled($picker[0].ownerDocument)
      expect(ringOnPage($picker[0]), "afal: the ring of DocumentEditor's emoji picker against the page").to.be.above(EDGE)
    })
  })

  it('leaves the file panel inside the one frame BlockNote draws', () => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/default')
    withoutFade('.bn-panel-popover')
    cy.get('.bn-editor').click().type('/image')
    cy.get('.bn-suggestion-menu').should('be.visible')
    cy.get('.bn-editor').type('{enter}')
    cy.get('.bn-panel [data-test="embed-tab"]').click()
    cy.location('origin').then((origin) => {
      cy.get('.bn-panel [data-test="embed-input"]').type(`${origin}/sample-image.png`)
    })
    cy.get('.bn-panel [data-test="embed-input-button"]').click()
    cy.get('.bn-editor img').first().click()
    cy.get('.bn-formatting-toolbar [data-test="replaceimage"]').click()

    cy.get('.bn-panel-popover').should('have.css', 'opacity', '1').should(($popover) => {
      expect(style($popover[0]).borderTopWidth, "the popover's border").to.equal('0px')
      expect(style($popover[0]).boxShadow, "the popover's shadow").to.equal('none')
      expect(parseFloat(style($popover[0].querySelector('.bn-panel')).borderTopWidth), "the panel's own frame")
        .to.be.at.least(1)
    })
  })
})
