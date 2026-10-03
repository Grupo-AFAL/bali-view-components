import { ReactIslandController } from '../../../frontend/bali/react-island'

// BlockNote appends an EMPTY <style> per editor to the head (its rules go in
// through insertRule) and takes it out with `head.removeChild`. Turbo's head
// merge drops all but the first of identical head elements, so every other
// editor's teardown threw NotFoundError half way through `destroyPluginViews`
// (#1212). Naming each style after its editor keeps them distinct; it has to
// happen on insertion, because Turbo reads the head before `turbo:before-render`.
// Delete once BlockNote's Placeholder removes its style with `style.remove()`.
const PLACEHOLDER_SELECTOR = /^\.(placeholder-selector-[\w-]+)/

const namePlaceholderStyle = (node) => {
  if (node.localName !== 'style' || node.dataset.baliPlaceholderStyle) return

  try {
    const owner = node.sheet?.cssRules[0]?.selectorText?.match(PLACEHOLDER_SELECTOR)
    if (owner) node.dataset.baliPlaceholderStyle = owner[1]
  } catch { /* a sheet the page cannot read is not one of these */ }
}

// Observing a node this observer already watches replaces its options rather
// than adding a second registration, so every editor can call `observe`.
const placeholderStyles = new MutationObserver((mutations) => {
  for (const { addedNodes } of mutations) addedNodes.forEach(namePlaceholderStyle)
})

// The block editor is the island the react-island base was extracted FROM
// (#703), so it is also the proof the base carries its weight: everything this
// controller used to spell out — the `_disconnected` guard, createRoot over an
// own mount point, `turbo-cache-control`, unmount on disconnect, the error
// fallback — now comes from the base, and what is left below is only what makes
// this island the block editor.
export class BlockEditorController extends ReactIslandController {
  static targets = ['editor', 'output']

  static values = {
    initialContent: { type: String, default: '' },
    htmlContent: { type: String, default: '' },
    markdownContent: { type: String, default: '' },
    format: { type: String, default: 'json' },
    preset: { type: String, default: 'full' },
    locale: { type: String, default: 'en' },
    syntaxHighlighting: { type: Boolean, default: true },
    placeholder: { type: String, default: '' },
    editable: { type: Boolean, default: true },
    uploadUrl: String,
    exportFilename: { type: String, default: 'document' },
    aiUrl: { type: String, default: '' },
    mentionsUrl: { type: String, default: '' },
    mentions: { type: Array, default: [] },
    referencesUrl: { type: String, default: '' },
    referencesResolveUrl: { type: String, default: '' },
    referencesConfig: { type: Object, default: {} },
    multiColumn: { type: Boolean, default: false },
    exportPdf: { type: Boolean, default: false },
    exportDocx: { type: Boolean, default: false },
    tableOfContents: { type: Boolean, default: false },
    tableOfContentsContainerId: { type: String, default: '' },
    comments: { type: Boolean, default: false },
    commentsContainerId: { type: String, default: '' },
    // "interactive" or "read-only". Only the portaled sidebar needs it in JS: the
    // inline one sits under the root, which Rails already flags. See
    // `Config#comments_sidebar`.
    commentsSidebar: { type: String, default: 'interactive' },
    commentsUrl: { type: String, default: '' },
    commentsUser: { type: Object, default: {} },
    commentsUsers: { type: Array, default: [] },
    commentsUsersUrl: { type: String, default: '' },
    commentsThreads: { type: Array, default: [] },
    // 0 turns polling off; -1 means "unset", so RESTThreadStore's own 5000 ms
    // default stays the single place that number is written down.
    commentsPollInterval: { type: Number, default: -1 },
    // Every string the React bundle puts on screen, served by Rails. It is only
    // empty when a host wires this controller up by hand instead of rendering
    // the component; the modules that read it fall back to English there.
    translations: { type: Object, default: {} }
  }

  // The island mounts inside the editor target, not on the controller element:
  // the element also carries the hidden input the surrounding form reads, and
  // replacing its children would take that input with it.
  mountElement () {
    return this.hasEditorTarget ? this.editorTarget : this.element
  }

  errorFallback (_error) {
    return this.translationsValue.load_failed
  }

  async loadComponent () {
    placeholderStyles.observe(document.head, { childList: true })

    const [react, reactDom, { default: Component }] = await Promise.all([
      import('react'),
      import('react-dom/client'),
      import('./BlockNoteEditorWrapper.jsx')
    ])

    // The optional paid modules are resolved HERE, not in componentProps(),
    // because they are async and props are not. Loading them before the base
    // creates the root also means the base's own `_disconnected` check covers
    // them: an editor torn down mid-import never mounts at all.
    this._optionalProps = {
      ...await this._loadMultiColumn(),
      ...await this._loadAi()
    }

    return { react, reactDom, Component }
  }

  componentProps () {
    return {
      initialContent: this.initialContentValue || undefined,
      htmlContent: this.htmlContentValue || undefined,
      markdownContent: this.markdownContentValue || undefined,
      editable: this.editableValue,
      placeholder: this.placeholderValue || undefined,
      format: this.formatValue,
      preset: this.presetValue,
      locale: this.localeValue,
      syntaxHighlighting: this.syntaxHighlightingValue,
      uploadUrl: this.uploadUrlValue || undefined,
      outputElement: this.hasOutputTarget ? this.outputTarget : null,
      containerElement: this.element,
      onEditorReady: (editor) => { this.blockNoteEditor = editor },
      onSyncReady: (flush) => this._bindSubmitFlush(flush),
      aiUrl: this.aiUrlValue || undefined,
      mentionsUrl: this.mentionsUrlValue || undefined,
      mentions: this.mentionsValue.length > 0 ? this.mentionsValue : undefined,
      referencesUrl: this.referencesUrlValue || undefined,
      referencesResolveUrl: this.referencesResolveUrlValue || undefined,
      referencesConfig: Object.keys(this.referencesConfigValue).length > 0 ? this.referencesConfigValue : undefined,
      tableOfContents: this.tableOfContentsValue,
      tableOfContentsContainerId: this.tableOfContentsContainerIdValue || undefined,
      comments: this.commentsValue,
      commentsContainerId: this.commentsContainerIdValue || undefined,
      commentsSidebar: this.commentsSidebarValue,
      commentsUrl: this.commentsUrlValue || undefined,
      commentsUser: Object.keys(this.commentsUserValue).length > 0 ? this.commentsUserValue : undefined,
      commentsUsers: this.commentsUsersValue.length > 0 ? this.commentsUsersValue : undefined,
      commentsUsersUrl: this.commentsUsersUrlValue || undefined,
      commentsThreads: this.commentsThreadsValue.length > 0 ? this.commentsThreadsValue : undefined,
      commentsPollInterval: this.commentsPollIntervalValue >= 0 ? this.commentsPollIntervalValue : undefined,
      translations: this.translationsValue,
      ...this._optionalProps
    }
  }

  // Dynamically load multi-column module when enabled
  async _loadMultiColumn () {
    if (!this.multiColumnValue) return {}

    try {
      const mc = await import('@blocknote/xl-multi-column')
      return {
        multiColumn: {
          withMultiColumn: mc.withMultiColumn,
          multiColumnDropCursor: mc.multiColumnDropCursor,
          getMultiColumnSlashMenuItems: mc.getMultiColumnSlashMenuItems,
          locales: mc.locales
        }
      }
    } catch (error) {
      console.error('BlockEditor: Failed to load multi-column module:', error)
      return {}
    }
  }

  // Dynamically load AI modules when ai_url is configured.
  // Each import() is awaited on its own line: esbuild only treats a dynamic
  // import as optional when it can attribute the failure to a surrounding
  // try, which it cannot do for imports nested in a Promise.all argument
  // list. Grouping them made these paid packages mandatory AT BUILD TIME
  // for every consuming app, even one that never enables AI.
  async _loadAi () {
    if (!this.aiUrlValue) return {}

    try {
      const xlAi = await import('@blocknote/xl-ai')
      await import('@blocknote/xl-ai/style.css')
      const aiLocales = await import('@blocknote/xl-ai/locales')
      const aiSdk = await import('ai')

      return {
        ai: {
          AIExtension: xlAi.AIExtension,
          AIMenuController: xlAi.AIMenuController,
          AIToolbarButton: xlAi.AIToolbarButton,
          getAISlashMenuItems: xlAi.getAISlashMenuItems,
          aiLocales,
          DefaultChatTransport: aiSdk.DefaultChatTransport
        }
      }
    } catch (error) {
      console.error('BlockEditor: Failed to load AI modules:', error)
      return {}
    }
  }

  // Write pending content to the hidden input the moment the surrounding form
  // is submitted. The content sync is debounced (500 ms), so a form sent before
  // the debounce fires would otherwise post the PREVIOUS content — the user's
  // last edits vanish with no error. Drawers that submit over fetch hit this
  // constantly. BlockNote's serializers are synchronous as of 0.51, so the
  // value is in place before the browser reads the form.
  _bindSubmitFlush (flush) {
    this._flush = flush

    const form = this.element.closest('form')
    if (!form || this._submitFlushBound) return

    this._submitFlushBound = () => { this._flush?.() }
    form.addEventListener('submit', this._submitFlushBound, { capture: true })
    this._boundForm = form
  }

  // Runs while the island's DOM is still attached, right before the base
  // unmounts the React root — which is exactly what the ProseMirror teardown
  // below needs.
  beforeUnmount () {
    if (this._boundForm && this._submitFlushBound) {
      this._boundForm.removeEventListener('submit', this._submitFlushBound, { capture: true })
      this._boundForm = null
      this._submitFlushBound = null
    }
    this._flush = null

    // Destroy the tiptap/ProseMirror editor BEFORE React unmount, while the
    // island's DOM is still attached. A failure here reaches the base, which
    // logs it: swallowing it is what hid #1212 for the main editor.
    this.blockNoteEditor?._tiptapEditor?.destroy()
    this.blockNoteEditor = null
  }

  async exportPdf () {
    if (!this.blockNoteEditor || !this.exportPdfValue) return

    try {
      // Awaited one per line so esbuild keeps these paid packages optional —
      // see the note in connect().
      const { PDFExporter, pdfDefaultSchemaMappings } = await import('@blocknote/xl-pdf-exporter')
      const reactPdf = await import('@react-pdf/renderer')
      const { createElement } = await import('react')

      const { pdf, Text, View } = reactPdf
      const mappings = {
        ...pdfDefaultSchemaMappings,
        blockMapping: {
          ...pdfDefaultSchemaMappings.blockMapping,
          // Override toggleListItem to avoid upstream SVG bug (fill="undefined" causes Infinity)
          toggleListItem: (block, transformer) => createElement(
            View,
            { style: { flexDirection: 'row', marginBottom: 2 }, key: 'toggle-' + block.id },
            createElement(View, { style: { width: 18, paddingTop: 2 } },
              createElement(Text, { style: { fontSize: 8 } }, '\u25B8')
            ),
            createElement(Text, { style: { flex: 1 } },
              ...transformer.transformInlineContent(block.content)
            )
          )
        },
        inlineContentMapping: {
          ...pdfDefaultSchemaMappings.inlineContentMapping,
          mention: (ic) => createElement(Text, { key: 'mention-' + ic.props.id }, '@' + ic.props.user),
          entityReference: (ic) => createElement(Text, { key: 'ref-' + ic.props.entityId }, '#' + ic.props.entityName)
        }
      }

      const exporter = new PDFExporter(this.blockNoteEditor.schema, mappings, {
        resolveFileUrl: this._resolveFileUrl
      })
      const pdfDocument = await exporter.toReactPDFDocument(this.blockNoteEditor.document)
      const blob = await pdf(pdfDocument).toBlob()
      this._downloadBlob(blob, `${this.exportFilenameValue}.pdf`)
    } catch (error) {
      console.error('BlockEditor: PDF export failed:', error)
    }
  }

  async exportDocx () {
    if (!this.blockNoteEditor || !this.exportDocxValue) return

    try {
      // Awaited one per line so esbuild keeps these paid packages optional —
      // see the note in connect().
      const { DOCXExporter, docxDefaultSchemaMappings } = await import('@blocknote/xl-docx-exporter')
      const docx = await import('docx')

      const mappings = {
        ...docxDefaultSchemaMappings,
        inlineContentMapping: {
          ...docxDefaultSchemaMappings.inlineContentMapping,
          mention: (ic) => new docx.TextRun({ text: '@' + ic.props.user }),
          entityReference: (ic) => new docx.TextRun({ text: '#' + ic.props.entityName })
        }
      }

      const exporter = new DOCXExporter(this.blockNoteEditor.schema, mappings, {
        resolveFileUrl: this._resolveFileUrl
      })
      const docxDocument = await exporter.toDocxJsDocument(this.blockNoteEditor.document)
      const blob = await docx.Packer.toBlob(docxDocument)
      this._downloadBlob(blob, `${this.exportFilenameValue}.docx`)
    } catch (error) {
      console.error('BlockEditor: DOCX export failed:', error)
    }
  }

  // --- Private helpers ---

  async _resolveFileUrl (url) {
    if (!url) return url
    // Blob and data URLs work as-is
    if (url.startsWith('blob:') || url.startsWith('data:')) return url
    // Convert relative URLs to absolute (e.g. Rails Active Storage paths)
    const absoluteUrl = url.startsWith('http') ? url : window.location.origin + (url.startsWith('/') ? '' : '/') + url
    return absoluteUrl
  }

  _downloadBlob (blob, filename) {
    const url = URL.createObjectURL(blob instanceof Blob ? blob : new Blob([blob]))
    const a = document.createElement('a')
    a.href = url
    a.download = filename
    a.style.display = 'none'
    document.body.appendChild(a)
    a.click()
    setTimeout(() => {
      URL.revokeObjectURL(url)
      document.body.removeChild(a)
    }, 100)
  }
}
