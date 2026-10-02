import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

// Text in a colour over a tint of that same colour fails by construction wherever the colour
// does not contrast with a dilution of itself. Measured before `text-soft-*`
// (app/assets/stylesheets/bali/utilities.css): the Command's match highlight in the active row
// 2.23:1 on `dark` and 3.52 on `afal`, SideMenu's active item 4.12 on `afal`, its warning badge
// 1.46 (#1245, #1247). Each state is reached the way a user reaches it: a query typed into the
// palette, a group opened, a mention picked, a pointer resting on the button.
describe('text over a tint of its own colour', () => {
  const AA = 4.5

  // [preview, how the state is reached, [[what, selector, how many]], whether the pointer is on it]
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
      ['12px badge', '[class~="text-[12px]"]', 6]
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
    ], true]
  ]

  // Below `lg` a fixed SideMenu is a closed drawer, and its bottom group cannot be opened.
  beforeEach(() => cy.viewport(1280, 800))
  afterEach(() => cy.then(unhover))

  PREVIEWS.forEach(([preview, reach, targets, hovered = false]) => {
    THEMES.forEach((theme) => {
      it(`reads ${targets.map(([what]) => what).join(', ')} of ${preview} at AA on the ${theme} theme`, () => {
        cy.visit(`/bali/${preview}`)
        if (reach) reach()
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        // Under Electron on xvfb, on a loaded machine, a theme switch took ~3 s to settle and a
        // hovered button ran past the default 4 s on `transitions settled` alone.
        cy.document({ timeout: 10000 }).should((doc) => {
          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)

          targets.forEach(([what, selector, count]) => {
            const elements = [...doc.querySelectorAll(selector)]
            expect(elements, `${preview}: every ${what}`).to.have.length(count)
            elements.forEach((el) => {
              expect(el.matches(':hover'), hovered ? 'under the pointer' : 'at rest').to.equal(hovered)
              const label = (el.textContent.trim() || el.getAttribute('aria-label')).replace(/\s+/g, ' ')
              expect(paintedContrast(el), `${theme}: ${what} "${label}"`).to.be.at.least(AA)
            })
          })
        })
      })
    })
  })
})
