// Vite entry point for Bali dummy app
// This replaces the importmap-based application.js

import { Application } from '@hotwired/stimulus'
import { registerControllers } from 'stimulus-vite-helpers'
import * as Turbo from '@hotwired/turbo'
import * as ActiveStorage from '@rails/activestorage'

// Rich Text Editor (Lexxy) - Basecamp's Lexical-based editor
import '@37signals/lexxy'

// ---------------------------------------------------------
// Bali Controllers - Core Bundle
// ---------------------------------------------------------
import {
  registerAllControllers,
  registerAllComponents
} from 'bali'

// Initialize Stimulus
const application = Application.start()
application.debug = false
window.Stimulus = application
window.Turbo = Turbo

// Start ActiveStorage
ActiveStorage.start()

// Auto-register local controllers (if any exist in app/javascript/controllers)
const localControllers = import.meta.glob('../controllers/**/*_controller.js', { eager: true })
registerControllers(application, localControllers)

// Register all core Bali controllers (utility + component)
registerAllControllers(application)
registerAllComponents(application)

// ---------------------------------------------------------
// Bali Optional Modules - Lazy loaded for performance
// Only import heavy dependencies when their elements exist
// ---------------------------------------------------------

// Track which modules have been loaded to avoid duplicate registration
const loadedModules = { charts: false, gantt: false }

/**
 * Lazy load Charts module when chart elements are detected
 * Reduces initial bundle by ~100KB when charts aren't used
 */
function loadChartsIfNeeded () {
  if (loadedModules.charts) return
  if (document.querySelector('[data-controller*="chart"]')) {
    loadedModules.charts = true
    import('bali/charts').then(({ registerCharts }) => {
      registerCharts(application)
    })
  }
}

/**
 * Lazy load Gantt module when gantt elements are detected
 */
function loadGanttIfNeeded () {
  if (loadedModules.gantt) return
  if (document.querySelector('[data-controller*="gantt"]')) {
    loadedModules.gantt = true
    import('bali/gantt').then(({ registerGantt }) => {
      registerGantt(application)
    })
  }
}

// Check on initial page load
loadChartsIfNeeded()
loadGanttIfNeeded()

// Re-check after Turbo navigations bring in new content
document.addEventListener('turbo:load', () => {
  loadChartsIfNeeded()
  loadGanttIfNeeded()
})

// Also check after Turbo Frames/Streams update the DOM
document.addEventListener('turbo:frame-load', () => {
  loadChartsIfNeeded()
  loadGanttIfNeeded()
})

// Rich Text Editor (TipTap) - DEPRECATED: use Lexxy instead
// import { registerRichTextEditor } from 'bali/rich-text-editor'
// registerRichTextEditor(application)

console.log('Vite + Stimulus HMR ready')
