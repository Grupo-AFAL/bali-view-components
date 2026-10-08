/**
 * Bali Block Editor - Optional Module
 *
 * WARNING: This module requires React and BlockNote dependencies.
 * Import separately and only if you need block-based editing functionality.
 *
 * Required dependencies — free packages only; the paid @blocknote/xl-*
 * packages are opt-in and documented in docs/api/block-editor.md:
 *   yarn add @blocknote/core@^0.53.0 @blocknote/react@^0.53.0 @blocknote/mantine@^0.53.0 \
 *            @mantine/core@^8.3.0 @mantine/hooks@^8.3.0 react@^19 react-dom@^19
 *
 * Usage:
 *   import { BlockEditorController, registerBlockEditor } from 'bali-view-components/block-editor'
 *   application.register('block-editor', BlockEditorController)
 *   // OR
 *   registerBlockEditor(application)
 *   // OR make 'bali-view-components/block-editor-entry' your bundler entry,
 *   // which self-registers on window.Stimulus (see docs/api/block-editor.md)
 */

import { BlockEditorController } from '../../components/bali/block_editor/index'

export { BlockEditorController } from '../../components/bali/block_editor/index'

/**
 * Register block editor controller with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerBlockEditor (application) {
  application.register('block-editor', BlockEditorController)
}
