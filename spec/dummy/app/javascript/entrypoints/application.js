// Vite entry point for Bali dummy app
// This replaces the importmap-based application.js

import { Application } from '@hotwired/stimulus'
import { registerControllers } from 'stimulus-vite-helpers'
import * as Turbo from '@hotwired/turbo'
import * as ActiveStorage from '@rails/activestorage'

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

// ---------------------------------------------------------
// Bali Controllers - Core Bundle
// ---------------------------------------------------------
import {
  registerAllControllers,
  registerAllComponents
} from 'bali'

// Register all core Bali controllers (utility + component)
registerAllControllers(application)
registerAllComponents(application)

// ---------------------------------------------------------
// Bali Optional Modules - Heavy dependencies, import separately
// ---------------------------------------------------------

// Charts (ApexCharts) - uncomment if needed
import { registerCharts } from 'bali/charts'
registerCharts(application)

// Gantt Chart - uncomment if needed
import { registerGantt } from 'bali/gantt'
registerGantt(application)

// Rich Text Editor (TipTap) - WARNING: currently broken
// import { registerRichTextEditor } from 'bali/rich-text-editor'
// registerRichTextEditor(application)

console.log('Vite + Stimulus HMR ready')
