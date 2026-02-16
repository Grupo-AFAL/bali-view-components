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
          outputElement.value = JSON.stringify(editor.document)
        }
      } catch (error) {
        console.error('BlockEditor: Failed to serialize content:', error)
      }
    }, 300)
  }, [editor, outputElement, format])
}
