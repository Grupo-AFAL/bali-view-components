import Document from '@tiptap/extension-document'
import Dropcursor from '@tiptap/extension-dropcursor'
import Gapcursor from '@tiptap/extension-gapcursor'
import History from '@tiptap/extension-history'
import Placeholder from '@tiptap/extension-placeholder'
import BubbleMenu from '@tiptap/extension-bubble-menu'
import TextAlign from '@tiptap/extension-text-align'

export const defaultTargets = [
  'bubbleMenu',
  'alignLeft',
  'alignCenter',
  'alignRight'
]

export const toolbarExtensions = [
  { target: 'alignLeft', name: { textAlign: 'left' } },
  { target: 'alignCenter', name: { textAlign: 'center' } },
  { target: 'alignRight', name: { textAlign: 'right' } }
]

export default (controller, options = {}) => {
  const DefaultExtensions = [
    Document,
    Dropcursor,
    Gapcursor,
    History,
    Placeholder.configure({
      placeholder: ({ node }) => {
        if (node.type.name === 'heading') {
          return `Heading ${node.attrs.level}`
        }

        if (node.type.name === 'codeBlock') return ''

        return options.placeholder
      }
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph']
    })
  ]

  const setTextAlignLeft = () => {
    controller.runCommand('setTextAlign', 'left')
  }

  const setTextAlignCenter = () => {
    controller.runCommand('setTextAlign', 'center')
  }

  const setTextAlignRight = () => {
    controller.runCommand('setTextAlign', 'right')
  }

  const enableSelectedExtensions = () => {
    toolbarExtensions.forEach(({ target, name }) => {
      if (!controller.editor.isActive(name)) return

      const targetNode = controller.targets.find(target)
      if (targetNode) {
        targetNode.classList.add('is-active')
      }
    })
  }

  if (controller.editableValue && controller.hasBubbleMenuTarget) {
    DefaultExtensions.push(
      BubbleMenu.configure({
        element: controller.bubbleMenuTarget,
        tippyOptions: { appendTo: controller.element, duration: 100 }
      })
    )
  }

  Object.assign(controller, {
    setTextAlignLeft,
    setTextAlignCenter,
    setTextAlignRight,
    enableSelectedExtensions
  })

  return { DefaultExtensions }
}
