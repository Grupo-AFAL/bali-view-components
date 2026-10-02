import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The text a component mutes is `base-content` at an alpha, composited over the
// surface it lands on. Shipped at `/40`, `/50` and `/60`, it measured as low as
// 2.33:1 against AA's 4.5 (#1233, #1234, #1248), and no one theme showed all of
// it: `light` passed the timeline's `/60` and `dark` the date's `/50`. Hence every
// theme, and the base-200 cards of the progress preview, where only the labels are
// measured as text: a glyph there paints on its marker's `::before` disc, which this
// guard does not hand to `paintedContrast` (the outline guard below does, as `under`).
// StatCard's cells include an emphasised one, whose primary tint took `/60` down
// to 3.83:1 on `afal`.
//
// Titles and glyphs are collected by their base-content grey: the current
// step's `primary` pair is the theme's own, not measured against AA here (#1221).
describe('muted text contrast', () => {
  const AA = 4.5
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
    ],
    // The third subtitle wraps a `text-info` paragraph: its grey paints no glyph.
    'list/default': [
      ['subtitle', `.list-row ${GREY}:not(:has([class*="text-"]))`, 2]
    ],
    'page_header/with_subtitle_as_param': [
      ['subtitle', '.page-header-component .subtitle', 1]
    ],
    'form/file/default': [
      ['file name', '[data-file-input-target="value"]', 1]
    ],
    'form/range/with_ticks': [
      ['tick', `input.range ~ ${GREY} > span`, 11]
    ],
    'stat_card/cells_in_card': [
      ['label', 'p:has(+ p.text-3xl)', 6],
      ['note', 'p.text-3xl + p', 6]
    ]
  }

  Object.entries(PREVIEWS).forEach(([preview, targets]) => {
    THEMES.forEach((theme) => {
      it(`reads the muted text of ${preview} at AA on the ${theme} theme`, () => {
        cy.visit(`/bali/${preview}`)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get('body').should(($body) => {
          expect($body[0].ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)

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

// The outline of a step still to come and the line into it, in the progress
// shape. Neither is text, but that shape's whole answer is the line, so WCAG
// 1.4.11 wants 3:1 against what they are drawn on (#1249). The line runs over
// the page or the card. The outline sits on its marker's `::before` disc, which
// stays base-100 inside a base-200 card that does not hand its surface over, so
// it is painted over the disc and measured against the disc and the card both:
// at `/50` it painted 2.77:1 there on `afal`, and the line 2.96 over the card.
describe('muted outline and line contrast in WorkflowSteps :progress', () => {
  const NON_TEXT = 3
  const disc = el => el.ownerDocument.defaultView.getComputedStyle(el.parentElement, '::before').backgroundColor

  // [what, selector, how many the preview renders, how it is drawn]
  const TARGETS = [
    ['outline', '.workflow-step-circle[class*="border-base-content/"]', 10,
      el => ({ property: 'borderTopColor', under: disc(el) })],
    ['line', '.workflow-step-connector[class*="bg-base-content/"]', 7,
      el => ({ property: 'backgroundColor', over: el.parentElement })]
  ]

  THEMES.forEach((theme) => {
    it(`draws the grey outline and line at 3:1 on the ${theme} theme`, () => {
      cy.visit('/bali/workflow_steps/progress')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.workflow-steps-progress-rail').should(($shapes) => {
        expect($shapes[0].ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)

        TARGETS.forEach(([what, selector, count, drawn]) => {
          const elements = $shapes.find(selector).toArray()
          expect(elements, `every grey ${what}`).to.have.length(count)
          elements.forEach((el) => {
            const step = el.closest('.workflow-step').querySelector('.workflow-step-title').textContent.trim()
            const ground = el.closest('.card') ? 'card' : 'page'
            expect(paintedContrast(el, drawn(el)), `${theme}: ${what} of "${step}" on the ${ground}`).to.be.at.least(NON_TEXT)
          })
        })
      })
    })
  })
})
