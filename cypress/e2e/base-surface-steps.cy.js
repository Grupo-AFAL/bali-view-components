import { paintedLuminance } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// A hover, a tint or a panel's edge has to step off the surface under it. Painted with base-200
// or base-300 they did not: daisyUI's `dark` and Bali's dark themes step those DOWN from base-100,
// and even on the light themes the step is faint. Measured over the surface each one sits on, a
// base-200 hover over base-100 read 1.048:1 on afal-dark and no more than 1.101 on any theme
// (afal), TreeView's 1.00 on all six — its own surface is base-200 — and a panel's base-300 edge
// 1.07–1.09 on afal-dark (#1276). The ink at 8% (a hover, a tint) and at 15% (an edge) steps off
// either way the theme's ramp runs: 1.16 and 1.33 at worst.
describe('hovers, tints and edges over a base surface', () => {
  const STEP = 1.15
  // Above the 1.238 a base-300 edge reads on afal: base-300 must not pass it.
  const EDGE = 1.25

  // The colours under `el`, the farthest first: the first opaque background on the way up, then
  // every translucent one between it and `el`.
  const surfaceUnder = (el) => {
    const doc = el.ownerDocument
    const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 })
      .getContext('2d', { willReadFrequently: true })
    const tints = []
    for (let node = el.parentElement; node; node = node.parentElement) {
      const colour = doc.defaultView.getComputedStyle(node).backgroundColor
      ctx.clearRect(0, 0, 1, 1)
      ctx.fillStyle = colour
      ctx.fillRect(0, 0, 1, 1)
      const alpha = ctx.getImageData(0, 0, 1, 1).data[3]
      if (alpha === 255) return [colour, ...tints]
      if (alpha > 0) tints.unshift(colour)
    }
    return ['white', ...tints]
  }

  const ratio = (a, b) => (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)

  // How far `property` of `el`, painted over what is under it, stands off that surface.
  const step = (el, property) => {
    const doc = el.ownerDocument
    const under = surfaceUnder(el)
    const colour = doc.defaultView.getComputedStyle(el)[property]
    return ratio(paintedLuminance(doc, ...under, colour), paintedLuminance(doc, ...under))
  }

  const openFilters = (query = '') => {
    cy.visit(`/bali/data_table/complete${query}`)
    cy.get('.filters button').contains('Filters').click()
  }

  // Ransack's `genre_in`: the condition is drawn by the server already on "is any of".
  const SERVER_MULTI_SELECT = '?q%5Bg%5D%5B0%5D%5Bgenre_in%5D%5B%5D=Drama'

  const openBuiltMultiSelect = () => {
    openFilters()
    cy.get('[data-condition-target="attribute"]').select('genre')
    cy.get('[data-condition-target="operator"]').select('in')
    cy.get('[data-condition-target="valueContainer"] [data-multi-select-target="trigger"]').click()
  }

  const openServerMultiSelect = () => {
    openFilters(SERVER_MULTI_SELECT)
    cy.get('[data-condition-target="valueContainer"] [data-multi-select-target="trigger"]').click()
  }

  const openGantt = () => {
    cy.visit('/bali/gantt/default')
    cy.get('button[title="Zoom in"]').should('exist')
  }

  const openGanttMenu = (label) => () => {
    openGantt()
    cy.contains('details > summary', label).click()
  }

  // [what, how the state is reached, the element that paints it]
  const HOVERS = [
    ['a TreeView item', () => cy.visit('/bali/tree_view/default'),
      '.tree-view-item-component .item:not(.is-active)'],
    ['an option of a multi-select condition the controller built', openBuiltMultiSelect,
      '[data-condition-target="valueContainer"] .filters-multi-select-content label'],
    ['an option of a multi-select condition the server drew', openServerMultiSelect,
      '[data-condition-target="valueContainer"] [data-multi-select-target="dropdown"] label'],
    ['a Timeline item with an href', () => cy.visit('/bali/timeline/tracking'),
      'a.timeline-content-box'],
    ['the Clipboard trigger', () => cy.visit('/bali/clipboard/default'),
      '.clipboard-trigger'],
    ['the DirectUpload dropzone', () => cy.visit('/bali/direct_upload/basic_usage'),
      '[data-direct-upload-target="dropzone"]'],
    ['a RecurrentEventRuleForm option', () => cy.visit('/bali/recurrent_event_rule_form/default'),
      '[data-recurrent-event-rule-target="freqCustomizationInputsContainer"]:visible label'],
    ['a Gantt zoom button', openGantt, 'button[title="Zoom in"]'],
    ['a Gantt row toggle', openGantt, 'button[aria-label="Collapse"]'],
    ['a SplitView row', () => cy.visit('/bali/split_view/default'), '.split-view-row:not([aria-current])']
  ]

  const EDGES = [
    ['the Filters panel', openFilters, '[data-filters-target="dropdownContent"] > div'],
    ['the multi-select panel the controller built', openBuiltMultiSelect,
      '[data-condition-target="valueContainer"] .filters-multi-select-content'],
    ['the multi-select panel the server drew', openServerMultiSelect,
      '[data-condition-target="valueContainer"] [data-multi-select-target="dropdown"]'],
    ['the Gantt zoom controls', openGantt, 'div:has(> button[title="Zoom in"])'],
    ['the Gantt minimap', openGantt, 'div[title^="Minimap"]'],
    ['the Gantt filter menu', openGanttMenu('Filter'), 'details[open] > ul.menu'],
    ['the Gantt columns menu', openGanttMenu('Columns'), 'details[open] > ul.menu']
  ]

  beforeEach(() => cy.viewport(1280, 900))
  afterEach(() => cy.then(unhover))

  // Under Electron on xvfb, on a loaded machine, a theme switch took ~3 s to settle
  // (soft-text-contrast.cy.js), so every wait after one gets 10 s.
  const settled = (doc) => expect(doc.getAnimations(), 'transitions settled').to.have.length(0)

  HOVERS.forEach(([what, reach, selector]) => {
    THEMES.forEach((theme) => {
      it(`lifts ${what} under the pointer off its surface on the ${theme} theme`, () => {
        reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
        cy.get(selector).first().then(hover)

        cy.get(selector).first({ timeout: 10000 }).should(($el) => {
          settled($el[0].ownerDocument)
          expect($el[0].matches(':hover'), 'under the pointer').to.equal(true)
          expect(step($el[0], 'backgroundColor'), `${theme}: ${what} against its surface`).to.be.at.least(STEP)
        })
      })
    })
  })

  EDGES.forEach(([what, reach, selector]) => {
    THEMES.forEach((theme) => {
      it(`draws the edge of ${what} off the surface under it on the ${theme} theme`, () => {
        reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get(selector).first({ timeout: 10000 }).should(($panel) => {
          settled($panel[0].ownerDocument)
          const style = $panel[0].ownerDocument.defaultView.getComputedStyle($panel[0])
          expect(parseFloat(style.borderTopWidth), 'border width').to.be.at.least(1)
          expect(step($panel[0], 'borderTopColor'), `${theme}: edge of ${what}`).to.be.above(EDGE)
        })
      })
    })
  })

  // The preview's sample events cycle through `ghost`; 20 January is one.
  THEMES.forEach((theme) => {
    it(`tints a ghost day off an empty one, and again under the pointer, on the ${theme} theme`, () => {
      const day = 'a.year-day[aria-label="20 January 2026"]'
      let atRest
      cy.viewport(1440, 1200)
      cy.visit('/bali/calendar/year?start_date=2026-01-01')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get(day, { timeout: 10000 }).should(($day) => {
        const doc = $day[0].ownerDocument
        settled(doc)
        expect($day[0].matches(':hover'), 'at rest').to.equal(false)
        expect(step($day[0], 'backgroundColor'), `${theme}: ghost day against an empty one`).to.be.at.least(STEP)
        atRest = paintedLuminance(doc, ...surfaceUnder($day[0]), doc.defaultView.getComputedStyle($day[0]).backgroundColor)
      })
      cy.get(day).then(hover)

      cy.get(day, { timeout: 10000 }).should(($day) => {
        const doc = $day[0].ownerDocument
        settled(doc)
        expect($day[0].matches(':hover'), 'under the pointer').to.equal(true)
        const hovered = paintedLuminance(doc, ...surfaceUnder($day[0]), doc.defaultView.getComputedStyle($day[0]).backgroundColor)
        expect(ratio(hovered, atRest), `${theme}: hovered ghost day against the same day at rest`).to.be.at.least(STEP)
      })
    })
  })
})
