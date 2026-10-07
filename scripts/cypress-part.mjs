#!/usr/bin/env node
/**
 * Prints the specs one part of the split Cypress run takes, comma-separated for `--spec`.
 *
 * .github/workflows/cypress.yml runs the suite as a matrix of parts side by side. Every part but
 * the last is a fixed list below, balanced by the time each spec took in CI; the last part is
 * every spec those lists leave out, so a spec nobody listed still runs. A listed spec that no
 * longer exists fails the run instead of quietly running nothing.
 *
 * Usage: node scripts/cypress-part.mjs <part> <parts>
 *   e.g. node scripts/cypress-part.mjs 2 4   (the matrix passes `strategy.job-total`)
 */

import { readdirSync } from 'node:fs'

// About seven minutes of specs each, by the times of the CI run of c416dc15 and, for the
// contrast guards that load a page once for every theme, by their local times in headless Chrome.
const LISTS = [
  [
    'app-layout-banner.cy.js', 'app-layout-overlay-triggers.cy.js', 'base-surface-steps.cy.js',
    'block-editor-content-format.cy.js', 'block-editor-popover-frames.cy.js', 'char-counter.cy.js',
    'data-table-toolbar-keyboard.cy.js', 'date-range-presets.cy.js', 'drawer-closed-shadow.cy.js',
    'drawer-controller.cy.js', 'dropdown-controller.cy.js', 'dynamic-fields-controller.cy.js',
    'feedback-widget-alignment.cy.js', 'feedback-widget-handshake.cy.js',
    'gantt-bar-label-contrast.cy.js', 'gantt-swap.cy.js', 'navbar-focus-ring.cy.js',
    'number-format.cy.js', 'side-menu-controller.cy.js', 'split-view-full-height.cy.js',
    'widget-grid.cy.js', 'widget-refresh.cy.js'
  ],
  [
    'alert-controller.cy.js', 'bali-events.cy.js', 'block-editor-threads-sidebar.cy.js',
    'bulk-actions-controller.cy.js', 'carousel.cy.js', 'chat-controller.cy.js',
    'document-editor.cy.js', 'entity-references.cy.js', 'feedback-widget-capture.cy.js',
    'filter-persistence-simple-filters.cy.js', 'filters-between.cy.js',
    'filters-condition-controller.cy.js', 'gantt-island.cy.js', 'gantt-table.cy.js',
    'hover-card.cy.js', 'image-grid.cy.js', 'modal-morph-top-layer.cy.js',
    'muted-text-contrast.cy.js', 'navbar-ghost-contrast.cy.js', 'navbar-transparent.cy.js',
    'split-view-list.cy.js', 'toolbar-overflow.cy.js'
  ],
  [
    'block-editor-comments.cy.js', 'block-editor-editing.cy.js', 'calendar-year-view.cy.js',
    'chart.cy.js', 'command-controller.cy.js', 'content-versions.cy.js',
    'data-table-column-memory.cy.js', 'drawer-broadcast.cy.js', 'filters-built-multi-select.cy.js',
    'filters-condition-names.cy.js', 'filters-controller.cy.js', 'kanban-surfaces.cy.js',
    'locations-map.cy.js', 'modal-controller.cy.js', 'radio-toggle-controller.cy.js',
    'recurrent-event-rule-form.cy.js', 'side-menu-chrome-surfaces.cy.js',
    'soft-text-contrast.cy.js', 'split-view.cy.js', 'theme-follow-contrast.cy.js',
    'topbar-user-menu.cy.js', 'widget-grid-resize.cy.js'
  ]
]

const fail = (message) => {
  console.error(`cypress-part: ${message}`)
  process.exit(1)
}

const [part, parts] = process.argv.slice(2).map(Number)
if (parts !== LISTS.length + 1) fail(`the matrix has ${parts} parts and this script splits the run in ${LISTS.length + 1}`)
if (!(part >= 1 && part <= parts)) fail(`no part ${process.argv[2]} of ${parts}`)

// Cypress's own specPattern, cypress/e2e/**/*.cy.{js,jsx,ts,tsx}.
const specs = readdirSync('cypress/e2e', { recursive: true }).filter(name => /\.cy\.[jt]sx?$/.test(name))
const listed = LISTS.flat()
const gone = listed.filter(name => !specs.includes(name))
if (gone.length) fail(`listed but not in cypress/e2e: ${gone.join(', ')}`)
const twice = listed.filter((name, i) => listed.indexOf(name) !== i)
if (twice.length) fail(`listed twice: ${twice.join(', ')}`)

const mine = part <= LISTS.length ? LISTS[part - 1] : specs.filter(name => !listed.includes(name))
console.log(mine.map(name => `cypress/e2e/${name}`).join(','))
