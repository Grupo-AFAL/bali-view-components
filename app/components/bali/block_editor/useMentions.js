import { useCallback } from 'react'

export function useMentions (editor, mentionsUrl, staticMentions) {
  return useCallback(async (query) => {
    let users = []

    if (mentionsUrl) {
      try {
        const url = new URL(mentionsUrl, window.location.origin)
        if (query) url.searchParams.set('q', query)
        const response = await fetch(url, {
          headers: { Accept: 'application/json' }
        })
        if (response.ok) {
          users = await response.json()
        }
      } catch (error) {
        console.error('BlockEditor: Failed to fetch mentions:', error)
      }
    } else if (staticMentions) {
      users = staticMentions
    }

    const items = users.map((user) => {
      const name = typeof user === 'string' ? user : user.name
      const id = typeof user === 'string' ? user : (user.id || user.name)
      return {
        title: name,
        onItemClick: () => {
          editor.insertInlineContent([
            { type: 'mention', props: { user: name, id: String(id) } },
            ' '
          ])
        }
      }
    })

    if (!query) return items
    const q = query.toLowerCase()
    return items.filter(item => item.title.toLowerCase().includes(q))
  }, [editor, mentionsUrl, staticMentions])
}
