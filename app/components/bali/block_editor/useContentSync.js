import { useCallback, useRef } from 'react'

/**
 * Checks whether the ProseMirror document contains any comment marks.
 * BlockNote strips these from `editor.document` (blocknoteIgnore: true),
 * so we need to use the tiptap/PM JSON serialization to preserve them.
 */
function hasCommentMarks (editor) {
  let found = false
  editor._tiptapEditor.state.doc.descendants((node) => {
    if (!found && node.marks?.some(m => m.type.name === 'comment')) {
      found = true
    }
    return !found
  })
  return found
}

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
        } else if (hasCommentMarks(editor)) {
          // Use ProseMirror JSON which preserves comment marks.
          // editor.document strips them (blocknoteIgnore: true).
          const pmJson = editor._tiptapEditor.getJSON()
          outputElement.value = JSON.stringify(pmJson)
        } else {
          outputElement.value = JSON.stringify(editor.document)
        }
        outputElement.dispatchEvent(new Event('input', { bubbles: true }))
      } catch (error) {
        console.error('BlockEditor: Failed to serialize content:', error)
      }
    }, 500)
  }, [editor, outputElement, format])
}
