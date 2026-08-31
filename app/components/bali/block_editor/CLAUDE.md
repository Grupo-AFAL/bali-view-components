# BlockNote / ProseMirror Gotchas

Applies to `block_editor`, `document_editor`, and `document_page`.

### Turbo + React + ProseMirror cleanup
ProseMirror plugins (e.g. Placeholder) remove DOM nodes during destroy. If Turbo detaches the tree first, `removeChild` throws. Fix: destroy `_tiptapEditor` before calling `root.unmount()` in Stimulus `disconnect()`.

### Content serialization with comment marks
`useContentSync` debounces content writes to the hidden input by 500ms. If `save()` reads the input immediately, it may get stale content without comment marks. Fix: flush content synchronously from the editor before reading the hidden input in `save()`.

### `format: :json` writes two different schemas
Comment marks only survive in the ProseMirror document, so with `:json` the editor switches from `editor.document` (an Array of blocks, `props`) to `_tiptapEditor.getJSON()` (`{type: "doc"}`, `blockGroup`/`blockContainer`, `attrs`) as soon as the document holds one — triggered by whoever comments, not by the host. Any host code reading the column has to handle both, or the column has to be pinned with `format: :blocks` / `:prosemirror` (#1091). `Bali::BlockEditor.content_format` answers the question from Ruby; the hidden input's `data-content-format` answers it from JS. Pinning `:blocks` drops the comment anchors — the marks are the anchors — and the editor warns in the console when it does.

### BlockNote comment mark cleanup
`ThreadStore.deleteThread()` removes the thread from the store but does NOT remove `comment` marks from the ProseMirror document. Must explicitly call `tr.removeMark()` for the deleted threadId.

### Multiple Stimulus controllers on same page
Document show pages may render multiple overlays (editor + viewer), each with their own `document-editor` controller. Global keyboard listeners (e.g. Cmd+S on `document`) fire on ALL controllers. Guard actions against read-only/empty state.
