import { paintedContrast } from '../support/painted_contrast'

// What WorkflowSteps and Timeline mute — the steps still to come, the date line,
// a timeline's timestamp and its pending heading — is `base-content` at an alpha,
// composited over the surface it lands on. Shipped at `/40`, `/50` and `/60`, it
// measured 2.33–4.47:1 against AA's 4.5 (#1233, #1234), and no one theme showed
// all of it: `light` passed the timeline's `/60` and `dark` the date's `/50`.
// Hence all five themes, and the base-200 cards of the progress preview, where
// only the labels are measured: a glyph there paints on its marker's `::before`
// disc, which `paintedContrast` cannot see.
//
// Titles and glyphs are collected by their base-content grey: the current
// step's `primary` pair is the theme's own, not measured against AA here (#1221).
describe('muted text contrast in WorkflowSteps and Timeline', () => {
  const AA = 4.5
  const THEMES = ['light', 'dark', 'afal', 'afal-dark', 'costa-norte']
  const GREY = '[class*="text-base-content/"]'

  // preview → [what, selector, how many the preview renders]
  const PREVIEWS = {
    'workflow_steps/default': [
      ['title', '.workflow-step-title', 7],
      ['grey circle', `.workflow-step-circle${GREY}`, 2],
      ['assignee', '.workflow-step-assignee', 5],
      ['date', '.workflow-step-date', 4],
      ['comment', '.workflow-step-comment', 4]
    ],
    'workflow_steps/progress': [
      ['label', `.workflow-steps-progress-rail .workflow-step-title${GREY}`, 21],
      ['grey glyph', `:not(.card) > .workflow-steps-progress-rail .workflow-step-circle${GREY}`, 8]
    ],
    'timeline/states': [
      ['timestamp', 'li > .timeline-end:not(.timeline-content-box)', 4],
      ['pending heading', `.timeline-content-box > p${GREY}`, 1]
    ],
    'timeline/tracking': [
      ['timestamp', '.timeline-content-box > p.font-semibold + p', 3],
      ['pending heading', `.timeline-content-box > p.font-semibold${GREY}`, 2]
    ]
  }

  Object.entries(PREVIEWS).forEach(([preview, targets]) => {
    THEMES.forEach((theme) => {
      it(`reads the muted text of ${preview} at AA on the ${theme} theme`, () => {
        cy.visit(`/bali/${preview}`)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get('body').should(($body) => {
          expect($body[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)

          targets.forEach(([what, selector, count]) => {
            const elements = [...$body[0].querySelectorAll(selector)]
            expect(elements, `${preview}: every ${what}`).to.have.length(count)
            elements.forEach((el) => {
              const text = el.textContent.trim()
              expect(paintedContrast(el), `${theme}: ${what} ${text ? `"${text}"` : '(a dash)'}`).to.be.at.least(AA)
            })
          })
        })
      })
    })
  })

  it('keeps the compact timestamp no larger than the heading above it', () => {
    cy.visit('/bali/timeline/tracking')

    cy.get('.timeline-content-box > p.font-semibold + p').should(($stamps) => {
      expect($stamps, 'compact timestamps').to.have.length(3)
      $stamps.each((_, stamp) => {
        const size = el => parseFloat(el.ownerDocument.defaultView.getComputedStyle(el).fontSize)
        expect(size(stamp), `"${stamp.textContent.trim()}"`).to.be.at.most(size(stamp.previousElementSibling))
      })
    })
  })
})
