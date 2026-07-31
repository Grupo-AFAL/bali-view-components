# BlockNote / ProseMirror Gotchas

Applies to `block_editor`, `document_editor`, and `document_page`.

### Turbo + React + ProseMirror cleanup
ProseMirror plugins (e.g. Placeholder) remove DOM nodes during destroy. If Turbo detaches the tree first, `removeChild` throws. Fix: destroy `_tiptapEditor` before calling `root.unmount()` in Stimulus `disconnect()`.

### Content serialization with comment marks
`useContentSync` debounces content writes to the hidden input by 500ms. If `save()` reads the input immediately, it may get stale content without comment marks. Fix: flush content synchronously from the editor before reading the hidden input in `save()`.

### BlockNote comment mark cleanup
`ThreadStore.deleteThread()` removes the thread from the store but does NOT remove `comment` marks from the ProseMirror document. Must explicitly call `tr.removeMark()` for the deleted threadId.

### Multiple Stimulus controllers on same page
Document show pages may render multiple overlays (editor + viewer), each with their own `document-editor` controller. Global keyboard listeners (e.g. Cmd+S on `document`) fire on ALL controllers. Guard actions against read-only/empty state.
