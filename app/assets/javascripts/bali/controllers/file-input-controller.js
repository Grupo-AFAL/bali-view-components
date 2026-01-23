import { Controller } from '@hotwired/stimulus'

// TODO: Add tests (Issue: #156)

/**
 * File Input Controller
 * Displays the selected filename in the correct place.
 *
 * It expects the following structure:
 *
    <div class="file has-name field" data-controller="file-input">
      <label class="file-label">
        <%= form.file_field :[fieldName], class: 'file-input',
            data: { action: 'file-input#onChange', file_input_target: 'input' } %>
        <span class="file-cta">
          <span class="file-icon">
            <i class="fas fa-cloud-upload-alt"></i>
          </span>
          <span class="file-label" >
            Seleccionar Imagen
          </span>
        </span>
        <span class="file-name" data-target="file-input.value">
          No hay imagen seleccionada
        </span>
      </label>
    </div>
 */

export class FileInputController extends Controller {
  static targets = ['value', 'input']
  static values = {
    nonSelectedText: String,
    multiple: { type: Boolean, default: false }
  }

  // Escape HTML to prevent XSS when inserting user-provided content
  escapeHtml (text) {
    const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
    return String(text).replace(/[&<>"']/g, ch => map[ch])
  }

  connect () {
    this.filesArray = []
  }

  onChange (event) {
    const newFiles = Array.from(event.target.files)

    // For single file mode, replace existing file; for multiple, append
    if (this.multipleValue) {
      this.filesArray = this.filesArray.concat(newFiles)
    } else {
      this.filesArray = newFiles
    }

    this.updateFileList()
  }

  removeFile (event) {
    event.preventDefault()
    const { name } = event.params

    this.filesArray = this.filesArray.filter(f => f.name !== name)
    this.updateFileList()
  }

  updateFileList () {
    this.inputTarget.files = this.convertToFileList()
    this.valueTarget.innerHTML = this.filesValueContent()
  }

  convertToFileList () {
    const dataTransfer = new DataTransfer()
    this.filesArray.forEach(file => dataTransfer.items.add(file))
    return dataTransfer.files
  }

  filesValueContent () {
    if (this.filesArray.length === 0) {
      return this.nonSelectedTextValue
    }

    if (!this.multipleValue) {
      return this.filesArray.map(f => f.name).join(', ')
    }

    return this.filesListUI()
  }

  filesListUI () {
    return `
      <ul class="space-y-1 mt-2">
        ${this.filesArray.map(file => this.fileItemUI(file)).join('')}
      </ul>
    `
  }

  fileItemUI (file) {
    const escapedName = this.escapeHtml(file.name)
    return `
      <li class="flex items-center gap-2 text-sm">
        <span class="truncate">${escapedName}</span>
        <button type="button"
                class="btn btn-ghost btn-xs text-error hover:bg-error/10"
                data-action="file-input#removeFile"
                data-file-input-name-param="${escapedName}"
                aria-label="Remove ${escapedName}">
          <svg class="size-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 6h18"></path>
            <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
            <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
            <line x1="10" y1="11" x2="10" y2="17"></line>
            <line x1="14" y1="11" x2="14" y2="17"></line>
          </svg>
        </button>
      </li>
    `
  }
}
