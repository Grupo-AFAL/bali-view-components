import { contrastRatio, luminance, paintedPixel } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// A bar's label lies partly over its progress, which paints the bar's colour solid, and partly
// over the bar's 16% tint of it. In base-content all over, the label of a complete bar read
// 1.82:1 on afal-dark (#1303). The label now paints with a two-stop gradient clipped to its text:
// the part over the progress in the fill's `content` ink, the rest in base-content.
// `paintedContrast` reads `color`, which is transparent here, so the ink is read off the stops.
describe('Gantt bar label over its progress', () => {
  const AA = 4.5
  const MODES = ['Status', 'Owner', 'Group', 'Priority']
  const COLOUR = /(?:rgba?|oklch|oklab|lab|lch|color)\([^()]*\)/g

  it('reads every label at AA over its progress and over the rest of the bar, on every theme', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    THEMES.forEach((theme) => {
      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))

      MODES.forEach((mode) => {
        cy.get('[role="group"][aria-label="Color by"]').contains('button', mode).click()
        cy.document().should((doc) => {
          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
          const style = (el) => doc.defaultView.getComputedStyle(el)
          const board = style(doc.querySelector('.bali-gantt-mount > div > div')).backgroundColor
          // A bar too short for its label writes it outside, over the canvas.
          const bars = [...doc.querySelectorAll('.react-flow__node')]
            .map((node) => ({ node, progress: node.querySelector('.inset-y-0.left-0') }))
            .filter(({ progress }) => progress && parseFloat(progress.style.width) > 0)
            .map(({ node, progress }) => ({ node, progress, label: progress.parentElement.querySelector('span.truncate') }))
            .filter(({ label }) => label)
          expect(bars, `${mode}: labelled bars with progress`).to.have.length.at.least(3)

          bars.forEach(({ node, progress, label }) => {
            const what = `${theme}, ${mode}: "${node.firstElementChild.title}"`
            const bar = progress.parentElement
            const [onProgress, onBar] = style(label).backgroundImage.match(COLOUR) || []
            expect(style(label).backgroundImage, `${what}: the ink changes at ${progress.style.width}`)
              .to.include(`${parseFloat(progress.style.width)}%`)
            expect(label.getBoundingClientRect().width, `${what}: label as wide as the progress track`)
              .to.be.closeTo(bar.clientWidth, 0.5)
            expect(style(progress).opacity, `${what}: progress opacity`).to.equal('1')

            const over = (...layers) => luminance(paintedPixel(doc, board, style(bar).backgroundColor, ...layers))
            const ink = (colour) => luminance(paintedPixel(doc, board, colour))
            expect(contrastRatio(ink(onProgress), over(style(progress).backgroundColor)), `${what} over its progress`)
              .to.be.at.least(AA)
            expect(contrastRatio(ink(onBar), over()), `${what} over the rest of the bar`).to.be.at.least(AA)
          })
        })
      })
    })
  })
})
