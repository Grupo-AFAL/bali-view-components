/**
 * Bali Rich Text Editor - Optional Module
 *
 * WARNING: This module requires TipTap dependencies.
 * Import separately and only if you need rich text editing functionality.
 *
 * Required dependencies (install in your app):
 *   yarn add @tiptap/core@^2 @tiptap/extension-link@^2 ...
 *
 * Usage:
 *   import { RichTextEditorController, registerRichTextEditor } from 'bali-view-components/rich-text-editor'
 *   application.register('rich-text-editor', RichTextEditorController)
 *   // OR
 *   registerRichTextEditor(application)
 */

import { RichTextEditorController } from '../../components/bali/rich_text_editor/index'

export { RichTextEditorController } from '../../components/bali/rich_text_editor/index'

/**
 * Register rich text editor controller with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerRichTextEditor (application) {
  application.register('rich-text-editor', RichTextEditorController)
}
