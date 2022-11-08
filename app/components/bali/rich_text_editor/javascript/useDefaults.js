import Document from '@tiptap/extension-document'
import Dropcursor from '@tiptap/extension-dropcursor'
import Gapcursor from '@tiptap/extension-gapcursor'
import History from '@tiptap/extension-history'
import Placeholder from '@tiptap/extension-placeholder'
import BubbleMenu from '@tiptap/extension-bubble-menu'

export const defaultTargets = ['bubbleMenu']

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
    })
  ]

  if (controller.editableValue && controller.hasBubbleMenuTarget) {
    DefaultExtensions.push(
      BubbleMenu.configure({
        element: controller.bubbleMenuTarget,
        tippyOptions: { appendTo: controller.element, duration: 100 }
      })
    )
  }

  return { DefaultExtensions }
}
