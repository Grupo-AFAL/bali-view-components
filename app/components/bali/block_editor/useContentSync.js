import { useCallback, useRef } from 'react'

export function useContentSync (editor, outputElement, format, ready) {
  const pendingUpdate = useRef(null)

  return useCallback(() => {
    if (!outputElement || !editor || !ready.current) return

    if (pendingUpdate.current) clearTimeout(pendingUpdate.current)

    pendingUpdate.current = setTimeout(async () => {
      try {
        if (format === 'html') {
          const html = await editor.blocksToHTMLLossy(editor.document)
          outputElement.value = html
        } else {
          const doc = editor.document
          const serialized = JSON.stringify(doc)

          // Verify comment annotation marks survive serialization
          if (process.env.NODE_ENV !== 'production') {
            const hasCommentMarks = serialized.includes('commentThread') || serialized.includes('comment')
            if (hasCommentMarks) {
              console.debug('BlockEditor: Document contains comment marks — annotations will persist.', JSON.parse(serialized))
            }
          }

          outputElement.value = serialized
        }
        outputElement.dispatchEvent(new Event('input', { bubbles: true }))
      } catch (error) {
        console.error('BlockEditor: Failed to serialize content:', error)
      }
    }, 500)
  }, [editor, outputElement, format])
}
