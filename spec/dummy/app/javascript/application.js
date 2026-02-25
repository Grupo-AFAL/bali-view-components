// esbuild entry point for Bali dummy app
import { Application } from '@hotwired/stimulus'
import * as Turbo from '@hotwired/turbo'
import * as ActiveStorage from '@rails/activestorage'

// Bali Controllers - Core Bundle
import {
  registerAllControllers,
  registerAllComponents
} from 'bali'

// Local controllers
import ThemeSwitcherController from './controllers/theme_switcher_controller'

// Initialize Stimulus
const application = Application.start()
application.debug = false
window.Stimulus = application
window.Turbo = Turbo

// Start ActiveStorage
ActiveStorage.start()

// Register local controllers
application.register('theme-switcher', ThemeSwitcherController)

// Register all core Bali controllers (utility + component)
registerAllControllers(application)
registerAllComponents(application)

// ---------------------------------------------------------
// Bali Optional Modules - Lazy loaded for performance
// Only import heavy dependencies when their elements exist
// ---------------------------------------------------------

const loadedModules = { charts: false, gantt: false, blockEditor: false }

function loadChartsIfNeeded () {
  if (loadedModules.charts) return
  if (document.querySelector('[data-controller*="chart"]')) {
    loadedModules.charts = true
    import('bali/charts').then(({ registerCharts }) => {
      registerCharts(application)
    })
  }
}

function loadGanttIfNeeded () {
  if (loadedModules.gantt) return
  if (document.querySelector('[data-controller*="gantt"]')) {
    loadedModules.gantt = true
    import('bali/gantt').then(({ registerGantt }) => {
      registerGantt(application)
    })
  }
}

function loadBlockEditorIfNeeded () {
  if (loadedModules.blockEditor) return
  if (document.querySelector('[data-controller*="block-editor"]')) {
    loadedModules.blockEditor = true
    import('bali/block-editor').then(({ registerBlockEditor }) => {
      registerBlockEditor(application)
    })
  }
}

// Check on initial page load
loadChartsIfNeeded()
loadGanttIfNeeded()
loadBlockEditorIfNeeded()

// Re-check after Turbo navigations bring in new content
document.addEventListener('turbo:load', () => {
  loadChartsIfNeeded()
  loadGanttIfNeeded()
  loadBlockEditorIfNeeded()
})

document.addEventListener('turbo:frame-load', () => {
  loadChartsIfNeeded()
  loadGanttIfNeeded()
  loadBlockEditorIfNeeded()
})

console.log('esbuild + Stimulus ready')
