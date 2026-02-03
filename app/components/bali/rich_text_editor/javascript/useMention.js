export default async (_controller, _options = {}) => {
  const { default: Mention } = await import('@tiptap/extension-mention')
  const { default: suggestion } = await import('./suggestions/pages_options.js')

  const MentionExtensions = [
    Mention.configure({
      HTMLAttributes: {
        class: 'suggestion'
      },
      renderLabel ({ options, node }) {
        return `${options.suggestion.char}${node.attrs.label}`
      },
      suggestion
    })
  ]

  return { MentionExtensions }
}
