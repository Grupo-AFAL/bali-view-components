import { Controller } from '@hotwired/stimulus'

export class BlockEditorController extends Controller {
  static targets = ['editor', 'output']

  static values = {
    initialContent: { type: String, default: '' },
    htmlContent: { type: String, default: '' },
    format: { type: String, default: 'json' },
    placeholder: { type: String, default: '' },
    editable: { type: Boolean, default: true },
    uploadUrl: String,
    theme: { type: String, default: 'light' },
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
    commentsUrl: { type: String, default: '' },
    commentsUser: { type: Object, default: {} },
    commentsUsers: { type: Array, default: [] },
    commentsUsersUrl: { type: String, default: '' }
  }

  async connect () {
    this._disconnected = false

    // Tell Turbo not to cache this page. React's internal state
    // (fiber tree, __reactContainer$ expando properties) doesn't survive
    // Turbo's cache→preview→replace cycle, causing broken editors on revisit.
    if (!document.querySelector('meta[name="turbo-cache-control"]')) {
      this._turboMeta = document.createElement('meta')
      this._turboMeta.name = 'turbo-cache-control'
      this._turboMeta.content = 'no-cache'
      document.head.appendChild(this._turboMeta)
    }

    try {
      const [{ createElement }, { createRoot }, { default: BlockNoteEditorWrapper }] = await Promise.all([
        import('react'),
        import('react-dom/client'),
        import('./BlockNoteEditorWrapper.jsx')
      ])

      if (this._disconnected) return

      this._mountPoint = document.createElement('div')
      this.editorTarget.replaceChildren(this._mountPoint)
      this.root = createRoot(this._mountPoint)

      const props = {
        initialContent: this.initialContentValue || undefined,
        htmlContent: this.htmlContentValue || undefined,
        editable: this.editableValue,
        placeholder: this.placeholderValue || undefined,
        format: this.formatValue,
        uploadUrl: this.uploadUrlValue || undefined,
        outputElement: this.hasOutputTarget ? this.outputTarget : null,
        onEditorReady: (editor) => { this.blockNoteEditor = editor },
        theme: this.themeValue,
        aiUrl: this.aiUrlValue || undefined,
        mentionsUrl: this.mentionsUrlValue || undefined,
        mentions: this.mentionsValue.length > 0 ? this.mentionsValue : undefined,
        referencesUrl: this.referencesUrlValue || undefined,
        referencesResolveUrl: this.referencesResolveUrlValue || undefined,
        referencesConfig: Object.keys(this.referencesConfigValue).length > 0 ? this.referencesConfigValue : undefined,
        tableOfContents: this.tableOfContentsValue,
        tableOfContentsContainerId: this.tableOfContentsContainerIdValue || undefined,
        comments: this.commentsValue,
        commentsUrl: this.commentsUrlValue || undefined,
        commentsUser: Object.keys(this.commentsUserValue).length > 0 ? this.commentsUserValue : undefined,
        commentsUsers: this.commentsUsersValue.length > 0 ? this.commentsUsersValue : undefined,
        commentsUsersUrl: this.commentsUsersUrlValue || undefined
      }

      // Dynamically load multi-column module when enabled
      if (this.multiColumnValue) {
        try {
          const mc = await import('@blocknote/xl-multi-column')
          props.multiColumn = {
            withMultiColumn: mc.withMultiColumn,
            multiColumnDropCursor: mc.multiColumnDropCursor,
            getMultiColumnSlashMenuItems: mc.getMultiColumnSlashMenuItems,
            locales: mc.locales
          }
        } catch (error) {
          console.error('BlockEditor: Failed to load multi-column module:', error)
        }
      }

      // Dynamically load AI modules when ai_url is configured
      if (props.aiUrl) {
        try {
          const [xlAi, , aiLocales, aiSdk] = await Promise.all([
            import('@blocknote/xl-ai'),
            import('@blocknote/xl-ai/style.css'),
            import('@blocknote/xl-ai/locales'),
            import('ai')
          ])

          props.ai = {
            AIExtension: xlAi.AIExtension,
            AIMenuController: xlAi.AIMenuController,
            AIToolbarButton: xlAi.AIToolbarButton,
            getAISlashMenuItems: xlAi.getAISlashMenuItems,
            aiLocales,
            DefaultChatTransport: aiSdk.DefaultChatTransport
          }
        } catch (error) {
          console.error('BlockEditor: Failed to load AI modules:', error)
        }
      }

      // Re-check after optional async imports (multi-column, AI)
      if (this._disconnected) {
        this.root.unmount()
        this.root = null
        return
      }

      this.root.render(createElement(BlockNoteEditorWrapper, props))
    } catch (error) {
      console.error('BlockEditor failed to initialize:', error)
      if (this.hasEditorTarget) {
        const errorMsg = document.createElement('p')
        errorMsg.className = 'text-error text-sm p-4'
        errorMsg.textContent = 'Failed to load editor. Ensure @blocknote/react, @blocknote/mantine, react, and react-dom are installed.'
        this.editorTarget.appendChild(errorMsg)
      }
    }
  }

  disconnect () {
    this._disconnected = true

    if (this._turboMeta) {
      this._turboMeta.remove()
      this._turboMeta = null
    }
    if (this.root) {
      this.root.unmount()
      this.root = null
    }
    this._mountPoint = null
    this.blockNoteEditor = null
  }

  async exportPdf () {
    if (!this.blockNoteEditor || !this.exportPdfValue) return

    try {
      const [
        { PDFExporter, pdfDefaultSchemaMappings },
        reactPdf,
        { createElement }
      ] = await Promise.all([
        import('@blocknote/xl-pdf-exporter'),
        import('@react-pdf/renderer'),
        import('react')
      ])

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
      const [
        { DOCXExporter, docxDefaultSchemaMappings },
        docx
      ] = await Promise.all([
        import('@blocknote/xl-docx-exporter'),
        import('docx')
      ])

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
