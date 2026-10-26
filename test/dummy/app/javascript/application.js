// esbuild entry point for Bali dummy app
import { Application } from '@hotwired/stimulus'
import * as Turbo from '@hotwired/turbo'
import * as ActiveStorage from '@rails/activestorage'

// Bali Controllers - Core Bundle
import {
  registerAllControllers,
  registerAllComponents,
  installConfirmDialog,
  loadGoogleMapsApi,
  googleMapsConfig
} from 'bali'
import { startIslandLoader } from 'bali/react-island'

// Local controllers
import ThemeSwitcherController from './controllers/theme_switcher_controller'
import BpmnHostConsoleController from './controllers/bpmn_host_console_controller'
import BpmnSplitViewController from './controllers/bpmn_split_view_controller'
import BpmnCompareMenuController from './controllers/bpmn_compare_menu_controller'
import BpmnExportDemoController from './controllers/bpmn_export_demo_controller'

// Initialize Stimulus
const application = Application.start()
application.debug = false
window.Stimulus = application
window.Turbo = Turbo
// The dialog's labels live inside this bundle, so confirm-dialog.cy.js sets them through here,
// as a host's index.js does.
window.installConfirmDialog = installConfirmDialog
// For google-maps-loader.cy.js and google-maps-config.cy.js, which call them as a host app does.
window.loadGoogleMapsApi = loadGoogleMapsApi
window.googleMapsConfig = googleMapsConfig

// Start ActiveStorage
ActiveStorage.start()

// Register local controllers
application.register('theme-switcher', ThemeSwitcherController)
// The BPMN editor's "Host integration" Lookbook preview (dummy-only).
application.register('bpmn-host-console', BpmnHostConsoleController)
application.register('bpmn-split-view', BpmnSplitViewController)
application.register('bpmn-compare-menu', BpmnCompareMenuController)
application.register('bpmn-export-demo', BpmnExportDemoController)

// Lazy-load the React islands the first time they appear in the DOM.
// The digested bundle paths come from the react_island_meta_tags helper in
// the page (see app/components/bali/react_island/previews/ and
// app/components/bali/gantt/previews/).
startIslandLoader('react-island-demo')
startIslandLoader('gantt')
startIslandLoader('bpmn-editor')

// Register all core Bali controllers (utility + component)
registerAllControllers(application)
registerAllComponents(application)

// ---------------------------------------------------------
// Bali Optional Modules - Lazy loaded for performance
// Only import heavy dependencies when their elements exist
// ---------------------------------------------------------

const loadedModules = { charts: false, blockEditor: false }

function loadChartsIfNeeded () {
  if (loadedModules.charts) return
  if (document.querySelector('[data-controller*="chart"]')) {
    loadedModules.charts = true
    import('bali/charts').then(({ registerCharts }) => {
      registerCharts(application)
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
loadBlockEditorIfNeeded()

// Re-check after Turbo navigations bring in new content
document.addEventListener('turbo:load', () => {
  loadChartsIfNeeded()
  loadBlockEditorIfNeeded()
})

document.addEventListener('turbo:frame-load', () => {
  loadChartsIfNeeded()
  loadBlockEditorIfNeeded()
})

console.log('esbuild + Stimulus ready')
