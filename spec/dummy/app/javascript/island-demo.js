// Dedicated esbuild entry for the demo island (see esbuild.config.mjs).
// A real host app's island entry is exactly this shape: registerIsland does
// the window.Stimulus dance (never a second Application) with an idempotence
// guard, and the react/react-dom imports inside the controller's
// loadComponent() are attributed to THIS bundle, keeping the main one lean.
//
// The main bundle lazy-loads this file through startIslandLoader plus the
// react_island_meta_tags helper -- see application.js and the previews at
// app/components/bali/react_island/previews/.
import { registerIsland } from 'bali/react-island'
import ReactIslandDemoController from './controllers/react_island_demo_controller'

// The onError hook is global to all islands; a host app sets it once to plug
// in its tracker (e.g. Sentry.captureException). The dummy records errors on
// window so the Cypress spec can assert the hook fires.
ReactIslandDemoController.onError = (error, context) => {
  window.__baliIslandErrors ||= []
  window.__baliIslandErrors.push({
    message: error.message,
    identifier: context.identifier,
    phase: context.phase
  })
}

registerIsland('react-island-demo', ReactIslandDemoController)
