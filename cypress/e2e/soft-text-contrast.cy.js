import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// A colour over a tint of that same colour fails by construction wherever the colour does not
// contrast with a dilution of itself. Measured before `text-soft-*`
// (app/assets/stylesheets/bali/utilities.css): the Command's match highlight in the active row
// 2.23:1 on `dark` and 3.52 on `afal`, SideMenu's active item 4.12 on `afal`, its warning badge
// 1.46 (#1245, #1247); a StatCard's warning icon 1.60 on `afal`, the hovered remove-filter button
// 2.27 there, an accent entity reference 1.71 on `light` (#1274). Each state is reached the way a
// user reaches it: a query typed into the palette, a group opened, a mention picked, a pointer
// resting on the button.
//
// DashboardPage's change line, StatCard's trend footer and every row from the FormBuilder's error
// message on measure the soft colour on base-100 instead (or on a ghost button's hover over it),
// where it replaced a `text-<colour>`. There error, success, warning, info and accent stay under
// AA on every light theme: as `text-success` the change line and the trend footer read 1.96:1 on
// `light`; as `text-error` the FormBuilder's error message read 2.75 on `afal`; and as
// `text-secondary` a Loader's label read 1.99 on `costa-norte` (#1281). A Gauge's ring and a
// Loader's spinner keep the colour itself and are not measured here.
describe('a colour over a tint of itself, and its soft colour on base-100', () => {
  const AA = 4.5
  // WCAG 1.4.11: an icon is a graphical object, not text.
  const GRAPHIC = 3

  const pickFile = () => {
    cy.get('input[type="file"]').selectFile({ contents: Cypress.Buffer.from('%PDF-1.4'), fileName: 'contract.pdf' }, { force: true })
    cy.get('[data-action="file-input#removeFile"]').should('have.length', 1)
  }
  const openFilters = () => cy.get('[data-filters-target="dropdown"] > button').click()
  const CLEAR_ALL = 'button[data-action="filters#clearAll"]'
  const TREND = '.bali-widget-body .sr-only + [aria-hidden="true"]'

  // [preview, how the state is reached, [[what, selector, how many, minimum = AA]], whether the
  // pointer is on it]
  const PREVIEWS = [
    ['command/default', () => {
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="input"]').type('pol')
    }, [
      ['match in the active row', '.cmd-row.is-active .cmd-mark', 1],
      ['match in another row', '.cmd-row:not(.is-active) .cmd-mark', 5]
    ]],
    // Inline: the item's tint sits on the container's base-200.
    ['side_menu/with_badges', null, [
      ['active item', '.menu-item.active.side-menu-expanded', 1],
      ['12px badge', '[class~="text-[12px]"]', 8]
    ]],
    ['side_menu/default', null, [
      ['active item, fixed', '.menu-item.active.side-menu-expanded', 1]
    ]],
    // Inside a `.menu`, where the colour comes from the unlayered `[aria-current]` rule in
    // side_menu/daisyui-overrides.css and not from side_menu/index.css.
    ['side_menu/with_bottom_groups?current_path=/settings', () => {
      cy.contains('.side-menu-bottom-group > [role="button"]', 'Configuration').click()
    }, [
      ['current item in an open bottom group', '.dropdown-content.menu .menu-item.side-menu-expanded[aria-current="page"]', 1]
    ]],
    // A sidebar with its own `theme:`, the reason `text-soft-*` is a utility and not a
    // custom property on `:root`.
    ['side_menu/dark_chrome', null, [
      ['active item under its own data-theme', '.menu-item.active.side-menu-expanded', 1]
    ]],
    ['tree_view/default', null, [
      ['active item', '.item.is-active', 1]
    ]],
    // A glyph on a card that keeps the default surface paints on a base-100 disc that
    // `paintedContrast` cannot see, so only the card that hands its surface over is measured.
    ['workflow_steps/progress', null, [
      ['current step number', ':not(.card) > .workflow-steps-progress-rail .workflow-step-circle.border-primary', 3],
      ['current step number on a card', '.card[class*="--bali-workflow-steps-surface"] .workflow-step-circle.border-primary', 1]
    ]],
    ['data_table/simple_filters/radio_group?status=draft', null, [
      ['checked radio', 'input:checked', 1]
    ]],
    ['data_table/simple_filters/toggle_group?kind=public', null, [
      ['checked toggle', 'input:checked', 1]
    ]],
    ['block_editor/with_mentions', () => {
      cy.get('.bn-editor.bn-default-styles').type('@', { delay: 0 })
      cy.get('.bn-suggestion-menu-item').should('have.length.at.least', 1)
      cy.get('.bn-editor.bn-default-styles').type('{enter}', { delay: 0 })
    }, [
      ['mention', '.bn-mention', 1]
    ]],
    ['filters/default?popover=false', () => {
      cy.get('[data-action="filter-group#addCondition"]').then(hover)
    }, [
      ['hovered "Add condition"', '[data-action="filter-group#addCondition"]', 1]
    ], true],
    ['filters/default?popover=false', () => {
      cy.get('[data-action="filters#addGroup"]').then(hover)
    }, [
      ['hovered "Add filter group"', '[data-action="filters#addGroup"]', 1]
    ], true],
    ['stat_card/all_colors', null, [
      ['icon on its tint', '.rounded-full svg', 9, GRAPHIC]
    ]],
    // The two ends of costa-norte's dashboard, which hands Bali::Status hexes to `custom_color:`:
    // amber read 1.99:1 on the light themes, violet 2.14 on `dark`.
    ['stat_card/with_custom_color?custom_color=%23f59e0b', null, [
      ['custom amber icon on its tint', '.rounded-full svg', 1, GRAPHIC]
    ]],
    ['stat_card/with_custom_color?custom_color=%236d28d9', null, [
      ['custom violet icon on its tint', '.rounded-full svg', 1, GRAPHIC]
    ]],
    // Not over a tint: DashboardPage#stat_change_class paints the change line with the same
    // class as the icon, on the card's base-100. As `text-primary`, the change line of a stat in
    // the default colour read 3.40:1 on `dark`.
    ['dashboard_page/default', null, [
      ['stat change', '.dashboard-page-component > .grid .card .text-sm > span', 3]
    ]],
    // A footer in `text-soft-success` on the card's base-100, the class the guide's StatCard
    // example writes.
    ['stat_card/with_trend', null, [
      ['trend', '.card .text-sm > span:not(.icon-component)', 1],
      ['trend icon', '.card .text-sm > .icon-component svg', 1, GRAPHIC]
    ]],
    ['filters/default?popover=false', () => {
      cy.get('[data-action="condition#remove"]').then(hover)
    }, [
      ['hovered "Remove condition"', '[data-action="condition#remove"]', 1, GRAPHIC]
    ], true],
    ['filters/with_applied_tags', () => {
      cy.get('[data-action="applied-tags#removeFilter"]').first().then(hover)
    }, [
      ['hovered "Remove filter"', '[data-action="applied-tags#removeFilter"]:hover', 1, GRAPHIC]
    ], true],
    ['form/file/multiple', pickFile, [
      ['"Remove file"', '[data-action="file-input#removeFile"]', 1, GRAPHIC]
    ]],
    ['form/file/multiple', () => {
      pickFile()
      cy.get('[data-action="file-input#removeFile"]').then(hover)
    }, [
      ['hovered "Remove file"', '[data-action="file-input#removeFile"]', 1, GRAPHIC]
    ], true],
    ['form/text/with_external_error', null, [
      ['error message', 'p.fieldset-label[id$="_error"]', 2],
      ['required asterisk', '.fieldset-legend span[aria-hidden="true"]', 1]
    ]],
    ['form/text/with_char_counter', () => {
      cy.get('#form_record_text').type('x'.repeat(41), { delay: 0 })
      cy.get('[data-textarea-target="counter"]').first().should('have.text', '41 / 40')
    }, [
      ['counters, one past its maximum', '[data-textarea-target="counter"]', 2]
    ]],
    ['filters/with_applied_tags', null, [
      ['"Clear all"', '.applied-filters > a', 1]
    ]],
    ['filters/default', openFilters, [
      ['"Clear all" in the panel', CLEAR_ALL, 1]
    ]],
    ['filters/default', () => {
      openFilters()
      cy.get(CLEAR_ALL).then(hover)
    }, [
      ['hovered "Clear all" in the panel', CLEAR_ALL, 1]
    ], true],
    ['filters/default?popover=false', null, [
      ['"Clear all"', CLEAR_ALL, 1]
    ]],
    ['filters/default?popover=false', () => {
      cy.get(CLEAR_ALL).then(hover)
    }, [
      ['hovered "Clear all"', CLEAR_ALL, 1]
    ], true],
    // Five rows that rise: bad news, as the preview's widget counts low stock. The arrow inherits
    // the delta's colour on the same surface, so the delta's 4.5 already holds it to its 3.
    ['widget/default?pattern=trend', null, [
      ['bad trend', TREND, 1]
    ]],
    ['widget/default?pattern=trend&count=0', null, [
      ['good trend', TREND, 1]
    ]],
    ['gauge/all_colors', null, [
      ['figure and label', '.bali-gauge > span > span', 16]
    ]],
    ['loader/all_colors', null, [
      ['label', '.loader-component > p', 8]
    ]],
    ['timeline/with_colors', null, [
      ['marker', '.timeline-middle svg', 9, GRAPHIC]
    ]],
    ['timeline/states', null, [
      ['marker', '.timeline-middle svg', 5, GRAPHIC]
    ]],
    // Sci-Fi brings an overdue date into the first page: the seeds end Inception's production
    // before the day they run. Infinite scroll keeps appending pages while the guard waits. An
    // overdue date is the one in `font-medium`, a weight the colour change leaves alone.
    ['split_view/default?q%5Bgenre_in%5D%5B%5D=Sci-Fi', null, [
      ['overdue date', '.split-view-item:nth-child(-n+5) .min-w-0 + span.font-medium', 1]
    ]],
    ['boolean_icon/all_states', null, [
      ['yes and no icon', '.boolean-icon-component:not([class*="text-base-content/"]) svg', 2, GRAPHIC]
    ]]
  ]

  // Below `lg` a fixed SideMenu is a closed drawer, and its bottom group cannot be opened.
  beforeEach(() => cy.viewport(1280, 800))
  afterEach(() => cy.then(unhover))

  PREVIEWS.forEach(([preview, reach, targets, hovered = false]) => {
    THEMES.forEach((theme) => {
      it(`reads ${targets.map(([what]) => what).join(', ')} of ${preview} on the ${theme} theme`, () => {
        cy.visit(`/bali/${preview}`)
        if (reach) reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        // Under Electron on xvfb, on a loaded machine, a theme switch took ~3 s to settle and a
        // hovered button ran past the default 4 s on `transitions settled` alone.
        cy.document({ timeout: 10000 }).should((doc) => {
          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)

          targets.forEach(([what, selector, count, minimum = AA]) => {
            const elements = [...doc.querySelectorAll(selector)]
            expect(elements, `${preview}: every ${what}`).to.have.length(count)
            elements.forEach((el) => {
              expect(el.matches(':hover'), hovered ? 'under the pointer' : 'at rest').to.equal(hovered)
              const label = (el.textContent.trim() || el.getAttribute('aria-label') ||
                el.closest('.card')?.querySelector('p')?.textContent.trim() || what).replace(/\s+/g, ' ')
              expect(paintedContrast(el), `${theme}: ${what} "${label}"`).to.be.at.least(minimum)
            })
          })
        })
      })
    })
  })

  // The chip's name, its type label and its icon, at rest over a 15% tint and under the pointer
  // over a 25% one, in every colour a host can name — the default `secondary` among them.
  THEMES.forEach((theme) => {
    it(`reads every entity reference at rest and under the pointer on the ${theme} theme`, () => {
      const expectReads = (chip) => {
        const what = `${theme}: ${chip.style.getPropertyValue('--entity-ref-color')}`
        expect(paintedContrast(chip), `${what} name`).to.be.at.least(AA)
        expect(paintedContrast(chip.querySelector('.bn-entity-reference-label')), `${what} type label`).to.be.at.least(AA)
        expect(paintedContrast(chip.querySelector('.bn-entity-reference-icon')), `${what} icon`).to.be.at.least(GRAPHIC)
      }

      cy.visit('/bali/block_editor/entity_reference_colors')
      cy.get('.bn-entity-reference-link > .bn-entity-reference').should('have.length', 9)
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.document({ timeout: 10000 }).should((doc) => {
        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        doc.querySelectorAll('.bn-entity-reference').forEach((chip) => {
          expect(chip.matches(':hover'), 'at rest').to.equal(false)
          expectReads(chip)
        })
      })

      cy.get('.bn-entity-reference').each(($chip) => {
        cy.wrap($chip).then(hover)
        cy.document({ timeout: 10000 }).should((doc) => {
          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
          expect($chip[0].matches(':hover'), 'under the pointer').to.equal(true)
          expectReads($chip[0])
        })
      })
    })
  })
})
