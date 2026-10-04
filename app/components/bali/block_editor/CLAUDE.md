# BlockNote / ProseMirror Gotchas

Applies to `block_editor`, `document_editor`, and `document_page`.

### Turbo + React + ProseMirror cleanup
ProseMirror plugins remove DOM nodes during destroy. If Turbo detaches the tree first, `removeChild` throws. Fix: destroy `_tiptapEditor` before calling `root.unmount()` in Stimulus `disconnect()`.

### Turbo's head merge and BlockNote's placeholder `<style>`
BlockNote appends one EMPTY `<style>` per editor to `document.head` (rules via `insertRule`) and `head.removeChild`s it on destroy. Turbo's head merge drops head elements with identical `outerHTML` except the first, so on a Turbo visit every editor but one lost its style before unmounting and its teardown threw NotFoundError — the comment editors of a document with threads, out of React's unmount, to Sentry (#1212). `namePlaceholderStyle` in `index.js` tags each style (`data-bali-placeholder-style`) with its editor's `placeholder-selector-*` so they stay distinct. A new library that injects empty `<style>` elements into the head will hit the same merge.

### Content serialization with comment marks
`useContentSync` debounces content writes to the hidden input by 500ms. If `save()` reads the input immediately, it may get stale content without comment marks. Fix: DocumentEditor's `save()` calls the BlockEditor controller's `flush()` — the same write a form submit triggers — before reading the input. `flush()` also cancels the pending write, whose `input` event would otherwise land mid-request and read as a new edit; its own `input` fires synchronously, so `save()` clears the save it queues.

### `format: :json` writes two different schemas
Comment marks only survive in the ProseMirror document, so with `:json` the editor switches from `editor.document` (an Array of blocks, `props`) to `_tiptapEditor.getJSON()` (`{type: "doc"}`, `blockGroup`/`blockContainer`, `attrs`) as soon as the document holds one — triggered by whoever comments, not by the host. Any host code reading the column has to handle both, or the column has to be pinned with `format: :blocks` / `:prosemirror` (#1091). `Bali::BlockEditor.content_format` answers the question from Ruby; the hidden input's `data-content-format` answers it from JS. Pinning `:blocks` drops the comment anchors — the marks are the anchors — and the editor warns in the console when it does.

### BlockNote comment mark cleanup
`ThreadStore.deleteThread()` removes the thread from the store but does NOT remove `comment` marks from the ProseMirror document. Must explicitly call `tr.removeMark()` for the deleted threadId.

### Multiple Stimulus controllers on same page
Document show pages may render multiple overlays (editor + viewer), each with their own `document-editor` controller. Global keyboard listeners (e.g. Cmd+S on `document`) fire on ALL controllers. Guard actions against read-only/empty state.
