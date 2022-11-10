export const marksTargets = ['bold', 'italic', 'underline', 'strike', 'link']
export const toolbarMarks = [
  { target: 'bold', name: 'bold' },
  { target: 'italic', name: 'italic' },
  { target: 'underline', name: 'underline' },
  { target: 'strike', name: 'strike' },
  { target: 'link', name: 'link' }
]

export default async (controller, _options = {}) => {
  const { default: Bold } = await import('@tiptap/extension-bold')
  const { default: Code } = await import('@tiptap/extension-code')
  // const { default: Highlight } = await import('@tiptap/extension-highlight')
  const { default: Italic } = await import('@tiptap/extension-italic')
  const { default: Strike } = await import('@tiptap/extension-strike')
  // const { default: Subscript } = await import('@tiptap/extension-subscript')
  // const { default: Superscript } = await import('@tiptap/extension-superscript')
  const { default: TextStyle } = await import('@tiptap/extension-text-style')
  const { default: Underline } = await import('@tiptap/extension-underline')

  const MarkExtensions = [Bold, Code, Italic, Strike, Underline, TextStyle]

  const toggleBold = () => {
    controller.runCommand('toggleBold')
  }

  const toggleItalic = () => {
    controller.runCommand('toggleItalic')
  }

  const toggleUnderline = () => {
    controller.runCommand('toggleUnderline')
  }

  const toggleStrike = () => {
    controller.runCommand('toggleStrike')
  }

  const enableSelectedToolbarMarks = () => {
    toolbarMarks.forEach(({ target, name, attributes }) => {
      if (!controller.editor.isActive(name, attributes)) return

      const targetNode = controller.targets.find(target)
      if (targetNode) {
        targetNode.classList.add('is-active')
      }
    })
  }

  Object.assign(controller, {
    toggleBold,
    toggleItalic,
    toggleUnderline,
    toggleStrike,
    enableSelectedToolbarMarks
  })

  return { MarkExtensions }
}
