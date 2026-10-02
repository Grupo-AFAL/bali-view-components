import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// `Bali::WorkflowSteps` with `orientation: :segments`, the shape for a table cell (#1235).
describe('WorkflowSteps segments', () => {
  const MIXED_STATES = ['Completed', 'Rejected', 'Needs attention']

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

  const flowCells = () => cy.get('td:has(.workflow-steps-segments)')

  it('fits four steps and the current title in a 180px cell without scrolling', () => {
    flowCells().invoke('css', 'width', '180px')

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

  // A flow that waits on nobody has no title, and the host writes its own ("Concluded") beside
  // the bar in a `flex flex-wrap` row. The root's `w-full` took that whole row and pushed the
  // text to the far edge of the cell.
  it("keeps the host's text right after the bar, and under it when the cell is too narrow", () => {
    const placement = ($texts) => $texts.toArray().map((text) => {
      const bar = text.parentElement.querySelector('.workflow-steps-list').getBoundingClientRect()
      const box = text.getBoundingClientRect()
      return { gap: box.left - bar.right, below: box.top >= bar.bottom, flush: Math.round(box.left - bar.left) }
    })

    flowCells().invoke('css', 'width', '240px')
    cy.get('[data-concluded]').should(($texts) => {
      expect($texts).to.have.length(2)
      placement($texts).forEach(({ gap, below }) => {
        expect(below, 'on the line under the bar').to.equal(false)
        expect(gap, 'px between the bar and the text').to.be.within(7, 9)
      })
    })

    flowCells().invoke('css', 'width', '180px')
    cy.get('[data-concluded]').should(($texts) => {
      placement($texts).forEach(({ below, flush }) => {
        expect(below, 'on the line under the bar').to.equal(true)
        expect(flush, 'px from the start of the bar').to.equal(0)
      })
    })
  })

  // WCAG 1.4.1. Read off the computed style rather than the class list, so a class Tailwind did
  // not generate shows up here as two states with the same shape. "Filled" is a background that
  // differs from the ground under it: under forced colours the browser repaints a fill as
  // Canvas, which is the ground itself.
  const alpha = (colour) => {
    const parts = colour.match(/[\d.]+/g).map(Number)
    return parts.length > 3 ? parts[3] : 1
  }
  const rgb = (colour) => colour.match(/[\d.]+/g).slice(0, 3).join(',')
  const groundOf = (el) => {
    for (let node = el.parentElement; node; node = node.parentElement) {
      const colour = getComputedStyle(node).backgroundColor
      if (alpha(colour) === 1) return colour
    }
    return 'rgb(255, 255, 255)'
  }
  const shapeOf = (s) => {
    const style = getComputedStyle(s)
    const filled = alpha(style.backgroundColor) > 0 && rgb(style.backgroundColor) !== rgb(groundOf(s))
    const image = style.backgroundImage.split('(')[0]
    return {
      drawn: filled || image !== 'none' || style.borderTopWidth !== '0px' || style.outlineStyle !== 'none',
      shape: [image, filled ? 'filled' : 'unfilled', Math.round(s.getBoundingClientRect().height),
        style.outlineStyle, style.borderTopWidth].join(' ')
    }
  }
  const sixDifferentShapes = ($segments) => {
    const shapes = $segments.toArray().map(shapeOf)
    expect(shapes).to.have.length(6)
    shapes.forEach(({ drawn }, i) => expect(drawn, `${$segments[i].title} is drawn`).to.equal(true))
    const names = shapes.map(({ shape }) => shape)
    expect(new Set(names).size, names.join(' | ')).to.equal(6)
  }

  it('draws each of the six states as a different shape', () => {
    cy.get('#six-states .workflow-step-segment').should(sixDifferentShapes)
  })

  // Forced colours repaint every background as Canvas and drop every gradient: left to the
  // browser, four states became the same hollow pill and `:skipped` vanished.
  context('under forced colours', () => {
    const forcedColors = (value) => cy.wrap(Cypress.automation('remote:debugger:protocol', {
      command: 'Emulation.setEmulatedMedia',
      params: { features: [{ name: 'forced-colors', value }] }
    }))

    beforeEach(() => forcedColors('active'))
    afterEach(() => forcedColors(''))

    it('still draws each of the six states as a different shape', () => {
      cy.window().should((win) => {
        expect(win.matchMedia('(forced-colors: active)').matches, 'forced colours emulated').to.equal(true)
      })
      cy.get('#six-states .workflow-step-segment').should(sixDifferentShapes)
    })
  })

  // WCAG 1.4.11. Every cue a segment carries — its fill, hatching, half, line, outline and
  // border — is drawn in its `color`, so that is the colour measured, against the cell or
  // page under it: `base-100`, or `base-200` on the table's zebra rows.
  //
  // A state colour that never reached the page would inherit the root's `base-content` and
  // pass 3:1 with no hue at all, so the three mixed states also have to differ from it.
  THEMES.forEach((theme) => {
    it(`paints every segment at 3:1 or more on the ${theme} theme`, () => {
      cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.workflow-step-segment').should(($segments) => {
        expect($segments[0].ownerDocument.getAnimations(), 'transitions still running').to.have.length(0)
        $segments.each((_, s) => {
          expect(paintedContrast(s, { over: s.parentElement }), `${theme}: ${s.title}`).to.be.at.least(3)

          if (MIXED_STATES.some((state) => s.title.endsWith(`: ${state}`))) {
            const inherited = getComputedStyle(s.closest('.workflow-steps')).color
            expect(getComputedStyle(s).color, `${theme}: ${s.title} has its own colour`).not.to.equal(inherited)
          }
        })
      })
    })
  })
})
