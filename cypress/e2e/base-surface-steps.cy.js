import { contrastRatio, paintedContrast, paintedLuminance } from '../support/painted_contrast'
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
  // Above the 1.238 a base-300 edge reads on afal, so base-300 does not pass, and below the 1.279
  // of the lowest edge: the multi-select list's ink at 20% over the filter group's 8% tint, on afal.
  const EDGE = 1.25
  const AA = 4.5

  // A hover is the element's own fill, so what it lifts off starts at its parent.
  const lift = (el) => paintedContrast(el, { over: el.parentElement, property: 'backgroundColor' })

  // A border paints over its panel's own background, not over what lies outside the panel: over
  // the filter group's tint outside, the multi-select list's edge read 1.476:1 on afal and
  // paints 1.279. `under` measures it against both sides and keeps the lower.
  const edge = (panel) => paintedContrast(panel, {
    over: panel.parentElement,
    property: 'borderTopColor',
    under: panel.ownerDocument.defaultView.getComputedStyle(panel).backgroundColor
  })

  // The Command palette's backdrop is the panel's sibling, not its ancestor, so no search from
  // the panel finds what paints outside its edge. Over that backdrop the ink at 15% paints
  // 1.63:1 at worst (afal-dark), over the panel's own fill 1.33 (afal): the fill is the lower side.
  const edgeOnOwnFill = (panel) => paintedContrast(panel, { property: 'borderTopColor' })

  const openCommand = () => {
    cy.visit('/bali/command/default')
    cy.get('.bali-command-trigger').click()
    cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')
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

  // The select's values are RRule's frequency constants: 0 yearly, 1 monthly.
  const openRecurrence = (frequency) => () => {
    cy.visit('/bali/recurrent_event_rule_form/default')
    cy.get('#form_record_rule_freq').select(frequency)
  }
  const recurrenceOption = (period, n) => `label:has(> input[name$="_${period}_on"][value="${n}"])`

  const openDatepicker = (field) => () => {
    cy.visit(`/bali/form/${field}/default`)
    cy.get('form input.input:not([type="hidden"])').click()
    cy.get('.flatpickr-calendar.open').should('be.visible')
  }
  const DAY = '.flatpickr-calendar.open .flatpickr-day'

  // [what, how the state is reached, the element that paints it, { filled, text, ringless }]
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
    ['a SplitView row', () => cy.visit('/bali/split_view/default'), '.split-view-row:not([aria-current])'],
    ['a Datepicker day', openDatepicker('date'),
      `${DAY}:not(.prevMonthDay):not(.nextMonthDay):not(.today):not(.selected)`, { text: '.flatpickr-day', ringless: true }],
    // Its hover was a light-theme literal: on the dark themes a near-white square, 13.6–15.3:1
    // against the calendar, with the number on it at 1.00–1.02.
    ['a Datepicker day of another month', openDatepicker('date'), `${DAY}.nextMonthDay`,
      { text: '.flatpickr-day', ringless: true }],
    ['the hour of the time picker', openDatepicker('time'), '.flatpickr-calendar.open input.flatpickr-hour',
      { text: 'input.flatpickr-hour' }],
    ['the AM/PM toggle of the time picker', openDatepicker('time'), '.flatpickr-calendar.open .flatpickr-am-pm',
      { text: '.flatpickr-am-pm' }],
    // `.numInputWrapper span:hover` is a white tint meant for the coloured header: over the time
    // row it painted 1.00:1 on the light themes and a light square, 2.65–2.70, on the dark ones.
    ['a stepper arrow of the time picker', openDatepicker('time'),
      '.flatpickr-calendar.open .flatpickr-time span.arrowUp'],
    // Filled at rest. Their base-300 hover over a base-200 fill stepped 1.044:1 (afal-dark) to
    // 1.130 (costa-norte) off the same control at rest; the ink at 16% over 8%, 1.168 at worst
    // (afal). The fill has to step off the surface too, and the text is read on both fills.
    ['the Avatar::Upload button', () => cy.visit('/bali/avatar/with_upload'),
      'label:has([data-avatar-target="input"])', { filled: true }],
    ['the Command trigger', () => cy.visit('/bali/command/default'),
      '.bali-command-trigger', { filled: true, text: '.bali-command-trigger > span' }],
    ['a SplitView filter pill', () => cy.visit('/bali/split_view/default'),
      '.split-view-filter:not([data-active="true"])', { filled: true, text: '.split-view-filter' }]
  ]

  const EDGES = [
    ['the Filters panel', openFilters, '[data-filters-target="dropdownContent"] > div'],
    ['the multi-select panel the controller built', openBuiltMultiSelect,
      '[data-condition-target="valueContainer"] .filters-multi-select-content'],
    ['the multi-select panel the server drew', openServerMultiSelect,
      '[data-condition-target="valueContainer"] [data-multi-select-target="dropdown"]'],
    ['the Gantt zoom controls', openGantt, 'div:has(> button[title="Zoom in"])'],
    ['the Gantt minimap', openGantt, 'div[title^="Minimap"]'],
    ['the Datepicker calendar', openDatepicker('date'), '.flatpickr-calendar.open'],
    ['the line over the time of a datetime picker', openDatepicker('datetime'), '.flatpickr-calendar.open .flatpickr-time'],
    ['the Gantt filter menu', openGanttMenu('Filter'), 'details[open] > ul.menu'],
    ['the Gantt columns menu', openGanttMenu('Columns'), 'details[open] > ul.menu'],
    ['the Command palette', openCommand, '.cmd-panel', edgeOnOwnFill]
  ]

  beforeEach(() => cy.viewport(1280, 900))
  afterEach(() => cy.then(unhover))

  // Under Electron on xvfb, on a loaded machine, a theme switch took ~3 s to settle
  // (soft-text-contrast.cy.js), so every wait after one gets 10 s.
  const settled = (doc) => expect(doc.getAnimations(), 'transitions settled').to.have.length(0)

  const textOn = (el, selector) => paintedContrast(el.matches(selector) ? el : el.querySelector(selector))

  // A translucent fill already runs under a transparent border: a border in the same colour
  // paints over it a second time, a darker ring.
  const ring = (el) => paintedContrast(el, { property: 'borderTopColor' })

  HOVERS.forEach(([what, reach, selector, { filled = false, text, ringless = false } = {}]) => {
    THEMES.forEach((theme) => {
      const name = filled
        ? `tints ${what} off its surface and lifts it further under the pointer on the ${theme} theme`
        : `lifts ${what} under the pointer off its surface on the ${theme} theme`
      it(name, () => {
        let atRest
        reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get(selector).first({ timeout: 10000 }).should(($el) => {
          settled($el[0].ownerDocument)
          expect($el[0].matches(':hover'), 'at rest').to.equal(false)
          atRest = lift($el[0])
          if (filled) expect(atRest, `${theme}: ${what} at rest against its surface`).to.be.at.least(STEP)
          if (text) expect(textOn($el[0], text), `${theme}: the text on ${what} at rest`).to.be.at.least(AA)
        })
        cy.get(selector).first().then(hover)

        // A fill worn at rest too lifts the element off its surface without the pointer, so the
        // step is also taken from the same element at rest. Two lifts off one surface divide into
        // the contrast between the two fills when both sit on the same side of it, and into less
        // when they do not: the safe side.
        cy.get(selector).first({ timeout: 10000 }).should(($el) => {
          settled($el[0].ownerDocument)
          expect($el[0].matches(':hover'), 'under the pointer').to.equal(true)
          const lifted = lift($el[0])
          expect(lifted, `${theme}: ${what} against its surface`).to.be.at.least(STEP)
          expect(lifted / atRest, `${theme}: ${what} against itself at rest`).to.be.at.least(STEP)
          if (text) expect(textOn($el[0], text), `${theme}: the text on ${what} under the pointer`).to.be.at.least(AA)
          if (ringless) expect(ring($el[0]), `${theme}: the border of ${what} over its own fill`).to.be.closeTo(1, 0.01)
        })
      })
    })
  })

  EDGES.forEach(([what, reach, selector, measure = edge]) => {
    THEMES.forEach((theme) => {
      it(`draws the edge of ${what} off the surface under it on the ${theme} theme`, () => {
        reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get(selector).first({ timeout: 10000 }).should(($panel) => {
          settled($panel[0].ownerDocument)
          const style = $panel[0].ownerDocument.defaultView.getComputedStyle($panel[0])
          expect(parseFloat(style.borderTopWidth), 'border width').to.be.at.least(1)
          expect(measure($panel[0]), `${theme}: edge of ${what}`).to.be.above(EDGE)
        })
      })
    })
  })

  // The group has no border: its tint is all that draws it on the panel. The remove-condition
  // icon is the one glyph on that tint with no fill of its own; at /50 it read 2.92:1 over the
  // ink at 8% on afal, under the 3:1 an icon needs.
  THEMES.forEach((theme) => {
    it(`tints a Filters group off its panel, its remove icon at 3:1, on the ${theme} theme`, () => {
      openFilters()
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.filter-group').first({ timeout: 10000 }).should(($group) => {
        settled($group[0].ownerDocument)
        expect(lift($group[0]), `${theme}: a Filters group against its panel`).to.be.at.least(STEP)
        expect(paintedContrast($group[0].querySelector('[data-action="condition#remove"]')),
          `${theme}: the remove-condition icon on the group`).to.be.at.least(3)
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

  // The preview colours a day after its first event (`day_variant_lambda`) and lists the day's
  // events in order as Tags in its hover card, so the card's first Tag names the day's variant.
  const dayWith = (doc, variant) => {
    const day = [...doc.querySelectorAll('.hover-card-component')]
      .find(card => card.querySelector(':scope > template')?.content
        .querySelector('.badge')?.classList.contains(`badge-${variant}`))
      ?.querySelector('a.year-day')
    expect(day, `a ${variant} day in the year preview`).to.not.equal(undefined)
    return day
  }
  const fill = (el) => el.ownerDocument.defaultView.getComputedStyle(el).backgroundColor
  const openYear = (theme) => {
    cy.viewport(1440, 1200)
    cy.visit('/bali/calendar/year?start_date=2026-01-01')
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  THEMES.forEach((theme) => {
    it(`tints a ghost day off an empty one on the ${theme} theme`, () => {
      openYear(theme)

      cy.document({ timeout: 10000 }).should((doc) => {
        const day = dayWith(doc, 'ghost')
        settled(doc)
        expect(day.matches(':hover'), 'at rest').to.equal(false)
        expect(lift(day), `${theme}: ghost day against an empty one`).to.be.at.least(STEP)
      })
    })

    it(`lifts a hovered ghost day further off the page, off a neutral day, number at AA on the ${theme} theme`, () => {
      let atRest, neutralAtRest
      openYear(theme)

      cy.document({ timeout: 10000 }).should((doc) => {
        const day = dayWith(doc, 'ghost')
        settled(doc)
        expect(day.matches(':hover'), 'at rest').to.equal(false)
        atRest = fill(day)
        neutralAtRest = fill(dayWith(doc, 'neutral'))
      })
      cy.document().then(doc => hover(Cypress.$(dayWith(doc, 'ghost'))))

      // Away from its rest is not enough: base-300 under the pointer is a step away from the ink
      // at 8% on the dark themes too, but across the page and nearer to it than the day at rest.
      // The number's AA is what kept the hover at 30%: at 40% it read 4.11:1 on `dark`.
      cy.document({ timeout: 10000 }).should((doc) => {
        const day = dayWith(doc, 'ghost')
        settled(doc)
        expect(day.matches(':hover'), 'under the pointer').to.equal(true)
        const hovered = fill(day)
        expect(apart(doc, hovered, atRest), `${theme}: hovered ghost day against the same day at rest`).to.be.at.least(STEP)
        expect(side(doc, hovered), `${theme}: hovered ghost day on the side of the page the day at rest is`).to.equal(side(doc, atRest))
        expect(offPage(doc, hovered), `${theme}: hovered ghost day off the page, against the day at rest`).to.be.above(offPage(doc, atRest))
        expect(apart(doc, hovered, neutralAtRest), `${theme}: hovered ghost day against a neutral day at rest`).to.be.at.least(STEP)
        expect(paintedContrast(day), `${theme}: number on a hovered ghost day`).to.be.at.least(4.5)
      })
    })
  })
})
