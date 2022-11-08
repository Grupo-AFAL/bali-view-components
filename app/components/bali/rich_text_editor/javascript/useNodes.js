import Blockquote from '@tiptap/extension-blockquote'
import BulletList from '@tiptap/extension-bullet-list'
import CodeBlock from '@tiptap/extension-code-block'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import HardBreak from '@tiptap/extension-hard-break'
import Heading from '@tiptap/extension-heading'
import HorizontalRule from '@tiptap/extension-horizontal-rule'
import ListItem from '@tiptap/extension-list-item'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
// import TaskList from '@tiptap/extension-task-list'
// import TaskItem from '@tiptap/extension-task-item'
import Text from '@tiptap/extension-text'

import lowlight from './lowlight'

export const nodesTargets = [
  'nodeSelect',
  'nodeSelectTrigger',
  'text',
  'h1',
  'h2',
  'h3',
  'ul',
  'ol',
  'blockquote',
  'codeBlock'
]

export const toolbarNodes = [
  {
    target: 'h1',
    name: 'heading',
    attributes: { level: 1 },
    text: 'Heading 1'
  },
  {
    target: 'h2',
    name: 'heading',
    attributes: { level: 2 },
    text: 'Heading 2'
  },
  {
    target: 'h3',
    name: 'heading',
    attributes: { level: 3 },
    text: 'Heading 3'
  },
  {
    name: 'bulletList',
    target: 'ul',
    text: 'Bulleted List'
  },
  {
    name: 'orderedList',
    target: 'ol',
    text: 'Ordered List'
  },
  {
    name: 'blockquote',
    target: 'blockquote',
    text: 'Quote'
  },
  {
    name: 'codeBlock',
    target: 'codeBlock',
    text: 'Code'
  },
  {
    name: 'paragraph',
    target: 'text',
    text: 'Text'
  }
]

export default (controller, _options = {}) => {
  const NodesExtensions = [
    Blockquote,
    BulletList,
    CodeBlock,
    CodeBlockLowlight.configure({
      lowlight
    }),
    HardBreak,
    Heading,
    HorizontalRule,
    Image,
    ListItem,
    OrderedList,
    Paragraph,
    Text
  ]

  const toggleH1 = () => {
    controller.runCommand('toggleHeading', { level: 1 })
  }

  const toggleH2 = () => {
    controller.runCommand('toggleHeading', { level: 2 })
  }

  const toggleH3 = () => {
    controller.runCommand('toggleHeading', { level: 3 })
  }

  const setParagraph = () => {
    controller.runCommand('setParagraph')
  }

  const toggleBulletList = () => {
    controller.runCommand('toggleBulletList')
  }

  const toggleOrderedList = () => {
    controller.runCommand('toggleOrderedList')
  }

  const toggleBlockquote = () => {
    controller.runCommand('toggleBlockquote')
  }

  const toggleCodeBlock = () => {
    controller.runCommand('toggleCodeBlock')
  }

  const enableSelectedToolbarNode = () => {
    toolbarNodes.some(({ target, name, text, attributes }) => {
      if (!controller.editor.isActive(name, attributes)) return

      const targetNode = controller.targets.find(target)
      if (!targetNode) return

      if (controller.hasNodeSelectTriggerTarget) {
        controller.nodeSelectTriggerTarget.innerHTML = text
      }

      targetNode.classList.add('is-active')
      return true
    })
  }

  const openNodeSelect = () => {
    controller.closeLinkPanel()
    controller.closeTablePanel()
    controller.closeImagePanel()
  }

  const closeNodeSelect = () => {
    if (!controller.hasNodeSelectTarget) return

    controller.nodeSelectTarget.classList.remove('is-active')
  }

  Object.assign(controller, {
    toggleH1,
    toggleH2,
    toggleH3,
    setParagraph,
    toggleBulletList,
    toggleOrderedList,
    toggleBlockquote,
    toggleCodeBlock,
    enableSelectedToolbarNode,
    openNodeSelect,
    closeNodeSelect
  })

  return { NodesExtensions }
}
