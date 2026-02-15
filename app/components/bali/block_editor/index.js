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
    theme: { type: String, default: 'light' }
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
  }
}
