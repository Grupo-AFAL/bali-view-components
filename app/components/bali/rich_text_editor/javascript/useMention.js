import Mention from '@tiptap/extension-mention'
import suggestion from './suggestions/pages_options'

export default (_controller, _options = {}) => {
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
