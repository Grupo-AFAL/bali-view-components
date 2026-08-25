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
 * Which of the two JSON shapes this write is going to produce.
 *
 * `json` is ADAPTIVE, and that was the trap (#1091): it switches to ProseMirror JSON the
 * moment the document holds a comment mark, because `editor.document` would drop it. The
 * host does not trigger that — the first user to leave a comment does, and with auto-save
 * their comment rewrites the column into the other schema without anyone asking. `blocks`
 * and `prosemirror` pin one shape so the column stays one shape.
 */
function contentShape (editor, format) {
  if (format === 'markdown' || format === 'html') return format
  if (format === 'prosemirror') return 'prosemirror'
  if (format === 'blocks') return 'blocks'

  return hasCommentMarks(editor) ? 'prosemirror' : 'blocks'
}

/**
 * Serializes the current document to the resolved shape.
 *
 * MUST stay synchronous on the happy path: `flush()` runs inside the form's
 * submit handler, and a promise would resolve after the browser has already
 * read the field. BlockNote's serializers return plain values as of 0.51 (they
 * returned promises before), so this returns a string there; on an older
 * version it returns a thenable and the caller falls back to the async path.
 */
function serialize (editor, shape) {
  if (shape === 'markdown') return editor.blocksToMarkdownLossy(editor.document)
  if (shape === 'html') return editor.blocksToHTMLLossy(editor.document)
  if (shape === 'prosemirror') {
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
  const warnedAboutDroppedMarks = useRef(false)

  const write = useCallback(() => {
    if (!outputElement || !editor || !ready.current) return

    const shape = contentShape(editor, format)

    // Pinning `blocks` with comments on is a real trade-off: the threads survive in their
    // store, their ANCHORS do not, because that is what `editor.document` strips. It is a
    // trade a host may want — losing it in silence is what this whole option exists to
    // stop. Once per editor: the write runs on every keystroke.
    if (format === 'blocks' && !warnedAboutDroppedMarks.current && hasCommentMarks(editor)) {
      warnedAboutDroppedMarks.current = true
      console.warn(
        'BlockEditor: format "blocks" does not persist comment marks, so the comment ' +
        'anchors in this document are not being saved. Use format "json" (the default) ' +
        'or "prosemirror" to keep them.'
      )
    }

    const commit = (value) => {
      outputElement.value = value
      // En qué forma quedó escrito, para el host que lo lea antes de mandarlo. Del lado de
      // Rails la misma pregunta la responde `Bali::BlockEditor.content_format`.
      outputElement.dataset.contentFormat = shape
      outputElement.dispatchEvent(new Event('input', { bubbles: true }))
    }

    try {
      const serialized = serialize(editor, shape)
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
