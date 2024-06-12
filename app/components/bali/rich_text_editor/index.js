import { Controller } from '@hotwired/stimulus'
import throttle from 'lodash.throttle'

import useDefaults, {
  defaultTargets,
  toolbarExtensions
} from 'bali/rich_text_editor/useDefaults'

import useMarks, { marksTargets, toolbarMarks } from 'bali/rich_text_editor/useMarks'
import useTable, { tableTargets } from 'bali/rich_text_editor/useTable'
import useLink, { linkTargets } from 'bali/rich_text_editor/useLink'
import useMention from 'bali/rich_text_editor/useMention'
import useNodes, { nodesTargets, toolbarNodes } from 'bali/rich_text_editor/useNodes'
import useImage, { imageTargets } from 'bali/rich_text_editor/useImage'
import useSlashCommands from 'bali/rich_text_editor/useSlashCommands'

export class RichTextEditorController extends Controller {
  static targets = [
    ...defaultTargets,
    ...nodesTargets,
    ...marksTargets,
    ...linkTargets,
    ...tableTargets,
    ...imageTargets,
    'output'
  ]

  static values = {
    content: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    editable: { type: Boolean, default: true },
    imagesUrl: String
  }

  allMenuButtons = toolbarMarks.concat(toolbarNodes, toolbarExtensions)

  async connect () {
    const { Editor } = await import('@tiptap/core')

    const { DefaultExtensions } = await useDefaults(this, {
      placeholder: this.placeholderValue
    })
    const { NodesExtensions } = await useNodes(this)
    const { MarkExtensions } = await useMarks(this)
    const { TableExtensions } = await useTable(this)
    const { LinkExtensions } = await useLink(this)
    const { MentionExtensions } = await useMention(this)
    const { ImageExtensions } = await useImage(this)

    const { SlashCommandsExtension } = await useSlashCommands(this)

    this.editor = new Editor({
      element: this.element,
      extensions: [
        ...DefaultExtensions,
        ...NodesExtensions,
        ...MarkExtensions,
        ...LinkExtensions,
        ...TableExtensions,
        ...MentionExtensions,
        ...ImageExtensions,
        ...SlashCommandsExtension
      ],
      autofocus: true,
      content: this.contentValue,
      onUpdate: this.throttledUpdate,
      editable: this.editableValue
    })

    this.editor.on('transaction', () => {
      this.closeAllPanels()
      this.resetMenuButtons()
      this.enableSelectedToolbarMarks()
      this.enableSelectedToolbarNode()
      this.enableSelectedExtensions()
      this.enableSelectedColor()
      this.updateTableModifiers()
    })
  }

  disconnect () {
    this.editor?.destroy()
  }

  onUpdate = ({ editor }) => {
    if (!this.hasOutputTarget) return

    this.outputTarget.value = editor.getHTML()
  }

  throttledUpdate = throttle(this.onUpdate, 1000)

  runCommand (name, attributes) {
    const editor = this.editor.chain().focus()
    editor[name](attributes).run()
  }

  closeAllPanels () {
    this.closeNodeSelect()
    this.closeLinkPanel()
    this.closeTablePanel()
    this.closeImagePanel()
  }

  resetMenuButtons () {
    this.allMenuButtons.forEach(({ target }) => {
      const targetNode = this.targets.find(target)
      if (targetNode) {
        targetNode.classList.remove('is-active')
      }
    })
  }

  hideMenu () {
    this.editor
      .chain()
      .focus()
      .blur()
      .run()
  }
}
