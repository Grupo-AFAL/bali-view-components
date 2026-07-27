/**
 * Bali Block Editor - Self-registering entry
 *
 * Make this the entire body of a dedicated bundler entry (e.g.
 * app/javascript/editor.js):
 *
 *   import 'bali-view-components/block-editor-entry'
 *
 * A dedicated entry matters for two reasons:
 *   1. The editor imports CSS from JS. In its own entry, esbuild emits it as
 *      editor.css; inside the main entry it would be appended to the
 *      application stylesheet instead.
 *   2. The editor weighs several MB and only capture screens need it. Pair
 *      this entry with 'bali-view-components/block-editor-loader' to load it
 *      on demand.
 *
 * Unlike a standalone bundle, this does NOT start a second Stimulus
 * application: it registers on the one the host app exposes as
 * window.Stimulus. Two applications scanning the same DOM mount every
 * controller twice.
 */
import { registerBlockEditor } from './block-editor'

const register = (application) => {
  if (!application || application.baliBlockEditorRegistered) return

  application.baliBlockEditorRegistered = true
  registerBlockEditor(application)
}

if (window.Stimulus) {
  register(window.Stimulus)
} else {
  document.addEventListener('DOMContentLoaded', () => {
    if (!window.Stimulus) {
      console.error(
        'Bali BlockEditor: window.Stimulus is not defined. Expose your ' +
        'Stimulus application (window.Stimulus = application) so the block ' +
        'editor can register on it, or register BlockEditorController manually.'
      )
      return
    }

    register(window.Stimulus)
  }, { once: true })
}
