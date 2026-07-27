import { useCallback, useEffect, useRef } from 'react'

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

/**
 * Serializes the current document to the configured storage format.
 *
 * MUST stay synchronous on the happy path: `flush()` runs inside the form's
 * submit handler, and a promise would resolve after the browser has already
 * read the field. BlockNote's serializers return plain values as of 0.51 (they
 * returned promises before), so this returns a string there; on an older
 * version it returns a thenable and the caller falls back to the async path.
 */
function serialize (editor, format) {
  if (format === 'markdown') return editor.blocksToMarkdownLossy(editor.document)
  if (format === 'html') return editor.blocksToHTMLLossy(editor.document)

  if (hasCommentMarks(editor)) {
    // ProseMirror JSON preserves comment marks; editor.document strips them
    // (blocknoteIgnore: true).
    return JSON.stringify(editor._tiptapEditor.getJSON())
  }
  return JSON.stringify(editor.document)
}

const isThenable = (value) => typeof value?.then === 'function'

const SYNC_DELAY = 500

/**
 * Keeps a hidden input in sync with the editor content.
 *
 * Returns `{ handleChange, flush }`:
 *   - `handleChange` is the debounced onChange handler.
 *   - `flush` writes the current content immediately, cancelling any pending
 *     debounce. Bind it to the form's `submit` event — otherwise a submit that
 *     lands within the debounce window posts the PREVIOUS content and silently
 *     loses the user's last edits.
 */
export function useContentSync (editor, outputElement, format, ready) {
  const pendingUpdate = useRef(null)

  const write = useCallback(() => {
    if (!outputElement || !editor || !ready.current) return

    const commit = (value) => {
      outputElement.value = value
      outputElement.dispatchEvent(new Event('input', { bubbles: true }))
    }

    try {
      const serialized = serialize(editor, format)
      if (isThenable(serialized)) {
        // BlockNote < 0.51 only. A submit inside the debounce window can still
        // lose the last edits there — hence the >=0.51 peer range.
        serialized.then(commit).catch((error) => {
          console.error('BlockEditor: Failed to serialize content:', error)
        })
      } else {
        commit(serialized)
      }
    } catch (error) {
      console.error('BlockEditor: Failed to serialize content:', error)
    }
  }, [editor, outputElement, format, ready])

  const flush = useCallback(() => {
    if (pendingUpdate.current) {
      clearTimeout(pendingUpdate.current)
      pendingUpdate.current = null
    }
    return write()
  }, [write])

  const handleChange = useCallback(() => {
    if (!outputElement || !editor || !ready.current) return

    if (pendingUpdate.current) clearTimeout(pendingUpdate.current)
    pendingUpdate.current = setTimeout(write, SYNC_DELAY)
  }, [editor, outputElement, ready, write])

  useEffect(() => {
    return () => {
      if (pendingUpdate.current) clearTimeout(pendingUpdate.current)
    }
  }, [])

  return { handleChange, flush }
}
