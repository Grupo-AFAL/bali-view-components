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

  connect () {
    this.filesArray = []
  }

  onChange (event) {
    const newFiles = Array.from(event.target.files)
    this.filesArray = this.filesArray.concat(newFiles)

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
      <ul>
        ${this.filesArray.map(file => this.fileItemUI(file)).join('')}
      </ul>
    `
  }

  fileItemUI (file) {
    return `
      <li>
        <span>${file.name}</span>
        <a data-action="file-input#removeFile" data-file-input-name-param="${file.name}">
          <span class="icon-component icon has-text-danger">
            <svg viewBox="0 0 448 512" class="svg-inline">
              <path fill="currentColor"
                d="M268 416h24a12 12 0 0012-12V188a12 12 0 00-12-12h-24a12 12 0 00-12 12v216a12 12 0 0012 12zM432 80h-82.4l-34-56.7A48 48 0 00274.4 0H173.6a48 48 0 00-41.2 23.3L98.4 80H16A16 16 0 000 96v16a16 16 0 0016 16h16v336a48 48 0 0048 48h288a48 48 0 0048-48V128h16a16 16 0 0016-16V96a16 16 0 00-16-16zM171.8 51a6 6 0 015.2-3h94a6 6 0 015.2 3l17.4 29H154.4zM368 464H80V128h288zm-212-48h24a12 12 0 0012-12V188a12 12 0 00-12-12h-24a12 12 0 00-12 12v216a12 12 0 0012 12z"
                class=""></path>
            </svg>
          </span>
        </a>
      </li>
    `
  }
}
