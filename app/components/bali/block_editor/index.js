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
    const html = this._getExportHTML()
    if (!html) return

    const iframe = document.createElement('iframe')
    iframe.style.cssText = 'position:fixed;left:-9999px;width:0;height:0;border:none;'
    document.body.appendChild(iframe)

    const doc = iframe.contentDocument || iframe.contentWindow.document
    doc.open()
    doc.write(this._wrapHTMLForPrint(html))
    doc.close()

    // Wait for images to load before printing
    iframe.contentWindow.onafterprint = () => {
      document.body.removeChild(iframe)
    }

    // Small delay to ensure styles are applied
    setTimeout(() => {
      iframe.contentWindow.print()
      // Fallback cleanup if onafterprint doesn't fire (e.g., user cancels)
      setTimeout(() => {
        if (iframe.parentNode) document.body.removeChild(iframe)
      }, 1000)
    }, 250)
  }

  async exportDocx () {
    const html = this._getExportHTML()
    if (!html) return

    try {
      const { default: htmlToDocx } = await import('html-to-docx')
      const blob = await htmlToDocx(this._wrapHTMLForDocx(html), null, {
        table: { row: { cantSplit: true } },
        footer: false,
        header: false
      })

      this._downloadBlob(blob, `${this.exportFilenameValue}.docx`)
    } catch (error) {
      if (error.message?.includes('Failed to fetch') || error.code === 'MODULE_NOT_FOUND') {
        console.error('BlockEditor: html-to-docx is not installed. Run: yarn add html-to-docx')
      } else {
        console.error('BlockEditor: DOCX export failed:', error)
      }
    }
  }

  // --- Private helpers ---

  _getExportHTML () {
    if (!this.blockNoteEditor) {
      console.error('BlockEditor: Editor not ready for export')
      return null
    }
    return this.blockNoteEditor.blocksToHTMLLossy(this.blockNoteEditor.document)
  }

  _wrapHTMLForPrint (bodyHTML) {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${this._escapeHTML(this.exportFilenameValue)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1a1a1a; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1 { font-size: 2em; margin-top: 1em; }
    h2 { font-size: 1.5em; margin-top: 0.8em; }
    h3 { font-size: 1.25em; margin-top: 0.6em; }
    pre { background: #f4f4f4; padding: 12px; border-radius: 4px; overflow-x: auto; font-size: 0.875em; }
    code { font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; }
    blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 1em; color: #555; }
    table { border-collapse: collapse; width: 100%; margin: 1em 0; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background: #f4f4f4; font-weight: 600; }
    img { max-width: 100%; height: auto; }
    ul, ol { padding-left: 1.5em; }
    @media print { body { padding: 0; } }
  </style>
</head>
<body>${bodyHTML}</body>
</html>`
  }

  _wrapHTMLForDocx (bodyHTML) {
    return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body>${bodyHTML}</body>
</html>`
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

  _escapeHTML (str) {
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }
}
