import { get } from '@rails/request.js'
import SuggestionRenderer from './renderer.js'

/**
 * Tiptap suggestion utility
 *
 * https://tiptap.dev/api/utilities/suggestion
 */
export default {
  items: async ({ query }) => {
    const response = await get('/documentation/pages', {
      query: { title: query },
      responseKind: 'json'
    })

    if (!response.ok) return []

    return await response.json
  },

  render: SuggestionRenderer()
}
