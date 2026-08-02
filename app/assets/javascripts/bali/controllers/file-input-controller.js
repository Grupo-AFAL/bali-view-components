import { Controller } from '@hotwired/stimulus'

// TODO: Add tests (Issue: #156)

/**
 * File Input Controller
 * Displays the selected filename in the correct place.
 *
 * `f.file_group` / `f.file_field` build this; the structure is only two
 * targets deep, so hand-written markup works as long as it carries both.
 * The example that used to live here described the Bulma markup
 * (`.file`, `.file-label`, `.file-cta`, `.file-icon`) the field stopped
 * emitting, and the stylesheet no longer has rules for any of those names.
 *
    <div class="flex items-center gap-3" data-controller="file-input"
         data-file-input-non-selected-text-value="No file selected"
         data-file-input-multiple-value="false">
      <label class="cursor-pointer inline-flex">
        <input type="file" class="hidden"
               data-action="file-input#onChange" data-file-input-target="input">
        <span class="btn btn-soft btn-primary btn-sm gap-2">Choose file</span>
      </label>
      <span class="text-sm text-base-content/60 truncate"
            data-file-input-target="value">No file selected</span>
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
