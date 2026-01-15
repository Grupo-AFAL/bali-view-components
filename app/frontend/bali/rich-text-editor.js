/**
 * Bali Rich Text Editor - Optional Module
 *
 * WARNING: This module is currently broken and requires TipTap dependencies.
 * Import separately and only if you need rich text editing functionality.
 *
 * Required dependencies (install in your app):
 *   yarn add @tiptap/core @tiptap/starter-kit @tiptap/extension-link ...
 *
 * Usage:
 *   import { RichTextEditorController, registerRichTextEditor } from 'bali/rich-text-editor'
 *   application.register('rich-text-editor', RichTextEditorController)
 *   // OR
 *   registerRichTextEditor(application)
 */

export { RichTextEditorController } from '../../components/bali/rich_text_editor/index'

import { RichTextEditorController } from '../../components/bali/rich_text_editor/index'

/**
 * Register rich text editor controller with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerRichTextEditor (application) {
  application.register('rich-text-editor', RichTextEditorController)
}
