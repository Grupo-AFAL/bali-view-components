import { paintedContrast } from '../support/painted_contrast'

// `Bali::WorkflowSteps` with `orientation: :segments`, the shape for a table cell (#1235).
describe('WorkflowSteps segments', () => {
  const THEMES = ['light', 'dark', 'afal', 'afal-dark', 'costa-norte']

  beforeEach(() => cy.visit('/bali/workflow_steps/segments'))

  // Every assertion about a box being narrow enough also holds for an unstyled list, which
  // stacks its items and fits anywhere. So each geometry test also asserts the segments are
  // one row of real bars.
  const oneRowOfBars = (segments, { min, max }) => {
    const centres = new Set(segments.map((s) => {
      const box = s.getBoundingClientRect()
      return Math.round(box.top + box.height / 2)
    }))
    expect(centres.size, 'rows of segments').to.equal(1)
    segments.forEach((s) => {
      expect(s.getBoundingClientRect().width, `${s.title}: width`).to.be.within(min, max)
    })
  }

  const neverScrolls = (root) => {
    const boxes = [root, ...root.querySelectorAll('*:not(.sr-only)')]
    boxes.forEach((el) => {
      expect(el.scrollWidth, `${el.className}: scrollWidth`).to.be.at.most(el.clientWidth)
      expect(getComputedStyle(el).overflowX, `${el.className}: overflow-x`).to.equal('visible')
    })
    expect(root.querySelectorAll('[tabindex]'), 'tab stops').to.have.length(0)
  }

  // The premise of #1235, measured with these four steps in a 180px cell: `:vertical` is 200px
  // tall, `:horizontal` stacks four cards 236px tall, and `:rail` and `:progress` need 384px
  // and scroll inside the cell.
  it('fits four steps and the current title in a 180px cell without scrolling', () => {
    cy.get('td:has(> .workflow-steps-segments)').invoke('css', 'width', '180px')

    cy.get('table .workflow-steps-segments').should(($roots) => {
      expect($roots).to.have.length(5)
      $roots.each((_, root) => {
        expect(root.closest('td').getBoundingClientRect().width, 'the cell').to.be.at.most(180)
        oneRowOfBars([...root.querySelectorAll('.workflow-step-segment')], { min: 24, max: 24 })
        neverScrolls(root)
      })
      expect($roots[0].querySelector('.workflow-steps-current-title')).to.have.text('Validate · Corporate direction')
    })
  })

  it('shrinks nine segments into a 160px column instead of overflowing it', () => {
    cy.get('#nine-steps .workflow-steps-segments').should(($root) => {
      const root = $root[0]
      const segments = [...root.querySelectorAll('.workflow-step-segment')]
      expect(segments).to.have.length(9)
      expect(root.getBoundingClientRect().width, 'the column').to.equal(160)
      oneRowOfBars(segments, { min: 8, max: 23 })
      neverScrolls(root)
    })
  })

  // WCAG 1.4.1. Read off the computed style rather than the class list, so a class Tailwind did
  // not generate shows up here as two states with the same shape.
  it('draws each of the six states as a different shape', () => {
    cy.get('#six-states .workflow-step-segment').should(($segments) => {
      const shape = (s) => {
        const style = getComputedStyle(s)
        return [
          style.backgroundImage.split('(')[0],
          style.backgroundColor === 'rgba(0, 0, 0, 0)' ? 'unfilled' : 'filled',
          Math.round(s.getBoundingClientRect().height),
          style.outlineStyle,
          style.borderTopWidth
        ].join(' ')
      }
      const shapes = $segments.toArray().map(shape)

      expect(shapes).to.have.length(6)
      expect(new Set(shapes).size, shapes.join(' | ')).to.equal(6)
    })
  })

  // WCAG 1.4.11. Every cue a segment carries — its fill, hatching, half, line, outline and
  // border — is drawn in its `color`, so that is the colour measured, against the cell or
  // page under it: `base-100`, or `base-200` on the table's zebra rows.
  THEMES.forEach((theme) => {
    it(`paints every segment at 3:1 or more on the ${theme} theme`, () => {
      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.workflow-step-segment').should(($segments) => {
        expect($segments[0].ownerDocument.getAnimations(), 'transitions still running').to.have.length(0)
        $segments.each((_, s) => {
          expect(paintedContrast(s, { over: s.parentElement }), `${theme}: ${s.title}`).to.be.at.least(3)
        })
      })
    })
  })
})
