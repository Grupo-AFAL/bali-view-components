/**
 * Bali Block Editor - Optional Module
 *
 * WARNING: This module requires React and BlockNote dependencies.
 * Import separately and only if you need block-based editing functionality.
 *
 * Required dependencies (install in your app):
 *   yarn add @blocknote/react @blocknote/mantine @mantine/core @mantine/hooks react react-dom
 *
 * Usage:
 *   import { BlockEditorController, registerBlockEditor } from 'bali-view-components/block-editor'
 *   application.register('block-editor', BlockEditorController)
 *   // OR
 *   registerBlockEditor(application)
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
