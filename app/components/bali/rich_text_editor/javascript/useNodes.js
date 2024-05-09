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

export default async (controller, _options = {}) => {
  const { default: Blockquote } = await import('@tiptap/extension-blockquote')
  const { default: BulletList } = await import('@tiptap/extension-bullet-list')
  const { default: CodeBlock } = await import('@tiptap/extension-code-block')
  const { default: CodeBlockLowlight } = await import(
    '@tiptap/extension-code-block-lowlight'
  )
  const { default: HardBreak } = await import('@tiptap/extension-hard-break')
  const { default: Heading } = await import('@tiptap/extension-heading')
  const { default: HorizontalRule } = await import(
    '@tiptap/extension-horizontal-rule'
  )
  const { default: ListItem } = await import('@tiptap/extension-list-item')
  const { default: OrderedList } = await import(
    '@tiptap/extension-ordered-list'
  )
  const { default: Paragraph } = await import('@tiptap/extension-paragraph')
  // const { default: TaskList } = await import('@tiptap/extension-task-list')
  // const { default: TaskItem } = await import('@tiptap/extension-task-item')
  const { default: Text } = await import('@tiptap/extension-text')

  const { default: lowlight } = await import('bali/rich_text_editor/lowlight')

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
      if (!controller.editor.isActive(name, attributes)) return false

      const targetNode = controller.targets.find(target)
      if (!targetNode) return false

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
