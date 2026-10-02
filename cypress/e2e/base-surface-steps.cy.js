import { contrastRatio, paintedContrast, paintedLuminance } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// A hover, a tint or a panel's edge has to step off the surface under it. Painted with base-200
// or base-300 they did not: daisyUI's `dark` and Bali's dark themes step those DOWN from base-100,
// and even on the light themes the step is faint. Measured over the surface each one sits on, a
// base-200 hover over base-100 read 1.048:1 on afal-dark and no more than 1.101 on any theme
// (afal), TreeView's 1.00 on all six — its own surface is base-200 — and a panel's base-300 edge
// 1.07–1.09 on afal-dark (#1276). The ink at 8% (a hover, a tint) and at 15% (an edge) steps off
// either way the theme's ramp runs: 1.16 and 1.27 at worst.
describe('hovers, tints and edges over a base surface', () => {
  const STEP = 1.15
  // Above the 1.238 a base-300 edge reads on afal, so base-300 does not pass, and below the 1.267
  // the ink at 15% paints at worst: the multi-select list inside the filter group's tint, on afal.
  const EDGE = 1.25

  // A hover is the element's own fill, so what it lifts off starts at its parent.
  const lift = (el) => paintedContrast(el, { over: el.parentElement, property: 'backgroundColor' })

  // A border paints over its panel's own background, not over what lies outside the panel: over
  // the filter group's tint outside, the multi-select list's edge read 1.329:1 on afal and
  // paints 1.267. `under` measures it against both sides and keeps the lower.
  const edge = (panel) => paintedContrast(panel, {
    over: panel.parentElement,
    property: 'borderTopColor',
    under: panel.ownerDocument.defaultView.getComputedStyle(panel).backgroundColor
  })

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

  // The select's values are RRule's frequency constants: 0 yearly, 1 monthly.
  const openRecurrence = (frequency) => () => {
    cy.visit('/bali/recurrent_event_rule_form/default')
    cy.get('#form_record_rule_freq').select(frequency)
  }
  const recurrenceOption = (period, n) => `label:has(> input[name$="_${period}_on"][value="${n}"])`

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
    ['a RecurrentEventRuleForm option, yearly on a date', openRecurrence('0'), recurrenceOption('yearly', 1)],
    ['a RecurrentEventRuleForm option, yearly on the Nth weekday', openRecurrence('0'), recurrenceOption('yearly', 2)],
    ['a RecurrentEventRuleForm option, monthly on a day', openRecurrence('1'), recurrenceOption('monthly', 1)],
    ['a RecurrentEventRuleForm option, monthly on the Nth weekday', openRecurrence('1'), recurrenceOption('monthly', 2)],
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
          expect(lift($el[0]), `${theme}: ${what} against its surface`).to.be.at.least(STEP)
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
          expect(edge($panel[0]), `${theme}: edge of ${what}`).to.be.above(EDGE)
        })
      })
    })
  })

  // A day's looks replace each other, so each is painted on the page alone, never one over the
  // other. The year preview's card is base-100, like the page.
  const onPage = (doc, ...colours) =>
    paintedLuminance(doc, doc.defaultView.getComputedStyle(doc.body).backgroundColor, ...colours)
  const apart = (doc, a, b) => contrastRatio(onPage(doc, a), onPage(doc, b))
  const offPage = (doc, a) => contrastRatio(onPage(doc, a), onPage(doc))
  const side = (doc, a) => Math.sign(onPage(doc, a) - onPage(doc))

  // The preview's sample events cycle through `ghost` and `neutral`: 20 January is a ghost day,
  // 20 February a neutral one.
  THEMES.forEach((theme) => {
    it(`tints a ghost day off an empty one and, under the pointer, further off the page than at rest, off a neutral day and with its number at AA, on the ${theme} theme`, () => {
      const ghost = 'a.year-day[aria-label="20 January 2026"]'
      const neutral = 'a.year-day[aria-label="20 February 2026"]'
      const fill = (el) => el.ownerDocument.defaultView.getComputedStyle(el).backgroundColor
      let atRest, neutralAtRest
      cy.viewport(1440, 1200)
      cy.visit('/bali/calendar/year?start_date=2026-01-01')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get(ghost, { timeout: 10000 }).should(($day) => {
        const doc = $day[0].ownerDocument
        settled(doc)
        expect($day[0].matches(':hover'), 'at rest').to.equal(false)
        expect(lift($day[0]), `${theme}: ghost day against an empty one`).to.be.at.least(STEP)
        expect(doc.querySelector(neutral), 'a neutral day').to.not.equal(null)
        atRest = fill($day[0])
        neutralAtRest = fill(doc.querySelector(neutral))
      })
      cy.get(ghost).then(hover)

      // Away from its rest is not enough: base-300 under the pointer is a step away from the ink
      // at 8% on the dark themes too, but across the page and nearer to it than the day at rest.
      // The number's AA is what kept the hover at 30%: at 40% it read 4.11:1 on `dark`.
      cy.get(ghost, { timeout: 10000 }).should(($day) => {
        const doc = $day[0].ownerDocument
        settled(doc)
        expect($day[0].matches(':hover'), 'under the pointer').to.equal(true)
        const hovered = fill($day[0])
        expect(apart(doc, hovered, atRest), `${theme}: hovered ghost day against the same day at rest`).to.be.at.least(STEP)
        expect(side(doc, hovered), `${theme}: hovered ghost day on the side of the page the day at rest is`).to.equal(side(doc, atRest))
        expect(offPage(doc, hovered), `${theme}: hovered ghost day off the page, against the day at rest`).to.be.above(offPage(doc, atRest))
        expect(apart(doc, hovered, neutralAtRest), `${theme}: hovered ghost day against a neutral day at rest`).to.be.at.least(STEP)
        expect(paintedContrast($day[0]), `${theme}: number on a hovered ghost day`).to.be.at.least(4.5)
      })
    })
  })
})
