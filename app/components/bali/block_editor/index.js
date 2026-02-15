import { Controller } from '@hotwired/stimulus'

export class BlockEditorController extends Controller {
  static targets = ['editor', 'output']

  static values = {
    initialContent: { type: String, default: '' },
    htmlContent: { type: String, default: '' },
    format: { type: String, default: 'json' },
    placeholder: { type: String, default: '' },
    editable: { type: Boolean, default: true },
    imagesUrl: String,
    theme: { type: String, default: 'light' },
    exportFilename: { type: String, default: 'document' }
  }

  async connect () {
    try {
      const [{ createElement }, { createRoot }, { default: BlockNoteEditorWrapper }] = await Promise.all([
        import('react'),
        import('react-dom/client'),
        import('./BlockNoteEditorWrapper.jsx')
      ])

      this.root = createRoot(this.editorTarget)

      this.root.render(
        createElement(BlockNoteEditorWrapper, {
          initialContent: this.initialContentValue || undefined,
          htmlContent: this.htmlContentValue || undefined,
          editable: this.editableValue,
          placeholder: this.placeholderValue || undefined,
          format: this.formatValue,
          imagesUrl: this.imagesUrlValue || undefined,
          outputElement: this.hasOutputTarget ? this.outputTarget : null,
          onEditorReady: (editor) => { this.blockNoteEditor = editor },
          theme: this.themeValue
        })
      )

      // Clean up React DOM before Turbo caches the page
      this._boundCleanCache = () => {
        if (this.root) {
          this.root.unmount()
          this.root = null
        }
      }
      document.addEventListener('turbo:before-cache', this._boundCleanCache)
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
    if (this._boundCleanCache) {
      document.removeEventListener('turbo:before-cache', this._boundCleanCache)
    }
    if (this.root) {
      this.root.unmount()
      this.root = null
    }
    this.blockNoteEditor = null
  }

  async exportPdf () {
    if (!this.blockNoteEditor) return

    try {
      const [
        { PDFExporter, pdfDefaultSchemaMappings },
        { pdf }
      ] = await Promise.all([
        import('@blocknote/xl-pdf-exporter'),
        import('@react-pdf/renderer')
      ])

      const exporter = new PDFExporter(this.blockNoteEditor.schema, pdfDefaultSchemaMappings)
      const pdfDocument = await exporter.toReactPDFDocument(this.blockNoteEditor.document)
      const blob = await pdf(pdfDocument).toBlob()
      this._downloadBlob(blob, `${this.exportFilenameValue}.pdf`)
    } catch (error) {
      console.error('BlockEditor: PDF export failed:', error)
    }
  }

  async exportDocx () {
    if (!this.blockNoteEditor) return

    try {
      const [
        { DOCXExporter, docxDefaultSchemaMappings },
        { Packer }
      ] = await Promise.all([
        import('@blocknote/xl-docx-exporter'),
        import('docx')
      ])

      const exporter = new DOCXExporter(this.blockNoteEditor.schema, docxDefaultSchemaMappings)
      const docxDocument = await exporter.toDocxJsDocument(this.blockNoteEditor.document)
      const blob = await Packer.toBlob(docxDocument)
      this._downloadBlob(blob, `${this.exportFilenameValue}.docx`)
    } catch (error) {
      console.error('BlockEditor: DOCX export failed:', error)
    }
  }

  // --- Private helpers ---

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
