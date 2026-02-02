import { Controller } from '@hotwired/stimulus'
import { DirectUpload } from '@rails/activestorage'

/**
 * DirectUpload Controller
 *
 * Handles file uploads directly to cloud storage (S3/GCS) using Active Storage's
 * DirectUpload API. Supports drag & drop, multiple files, progress tracking,
 * and creates hidden fields with signed_ids for form submission.
 */
export class DirectUploadController extends Controller {
  static targets = [
    'input',
    'dropzone',
    'fileList',
    'template',
    'hiddenFields',
    'existingFiles',
    'removeFields',
    'errorAlert',
    'errorMessage',
    'announcer'
  ]

  static values = {
    url: String,
    multiple: { type: Boolean, default: false },
    maxFiles: { type: Number, default: 10 },
    maxFileSize: { type: Number, default: 10 }, // in MB
    accept: { type: String, default: '*' },
    autoUpload: { type: Boolean, default: true },
    fieldName: String,
    removeFieldName: String
  }

  // Track files: Map<id, { file, progress, status, signedId, error, xhr, element }>
  // status: 'pending' | 'uploading' | 'completed' | 'error'
  files = new Map()
  fileIdCounter = 0
  removedAttachmentIds = new Set()

  connect () {
    this.dragCounter = 0
    this.setupFormGuard()
    this.setupAutoReset()
  }

  disconnect () {
    this.teardownFormGuard()
  }

  // ==================== Form Submission Guard ====================

  setupFormGuard () {
    this.form = this.element.closest('form')
    if (this.form) {
      this.boundFormSubmit = this.handleFormSubmit.bind(this)
      this.form.addEventListener('submit', this.boundFormSubmit)
    }
  }

  setupAutoReset () {
    if (this.form) {
      this.boundFormSuccess = this.handleFormSuccess.bind(this)
      this.form.addEventListener('turbo:submit-end', this.boundFormSuccess)
    }
  }

  teardownFormGuard () {
    if (this.form) {
      if (this.boundFormSubmit) {
        this.form.removeEventListener('submit', this.boundFormSubmit)
      }
      if (this.boundFormSuccess) {
        this.form.removeEventListener('turbo:submit-end', this.boundFormSuccess)
      }
    }
  }

  handleFormSubmit (event) {
    const uploading = this.getUploadingCount()
    if (uploading > 0) {
      event.preventDefault()
      event.stopPropagation()
      this.showError(`Please wait for ${uploading} upload(s) to complete`)
      this.announce(`Upload in progress. Please wait for ${uploading} file(s) to finish uploading.`)
    }
  }

  handleFormSuccess (event) {
    // Clear files only on successful submission (2xx response)
    if (event.detail.success) {
      this.clearAllFiles()
    }
  }

  getUploadingCount () {
    let count = 0
    for (const fileData of this.files.values()) {
      if (fileData.status === 'uploading' || fileData.status === 'pending') {
        count++
      }
    }
    return count
  }

  // ==================== File Selection ====================

  openFilePicker () {
    this.inputTarget.click()
  }

  selectFiles (event) {
    const files = Array.from(event.target.files)
    this.addFiles(files)
    // Reset input so the same file can be selected again
    event.target.value = ''
  }

  addFiles (files) {
    const validFiles = this.validateFiles(files)

    validFiles.forEach(file => {
      const id = this.generateFileId()
      this.files.set(id, {
        file,
        progress: 0,
        status: 'pending',
        signedId: null,
        error: null,
        xhr: null,
        element: null
      })

      this.renderFileItem(id)

      if (this.autoUploadValue) {
        this.uploadFile(id)
      }
    })
  }

  validateFiles (files) {
    const maxSizeBytes = this.maxFileSizeValue * 1024 * 1024
    const currentCount = this.files.size
    const validFiles = []

    for (const file of files) {
      // Check max files
      if (this.multipleValue && (currentCount + validFiles.length) >= this.maxFilesValue) {
        this.showError(`Maximum ${this.maxFilesValue} files allowed`)
        break
      }

      // Check file size
      if (file.size > maxSizeBytes) {
        this.showError(`${file.name} exceeds ${this.maxFileSizeValue}MB limit`)
        continue
      }

      // Check file type
      if (!this.isAcceptedType(file)) {
        this.showError(`${file.name}: File type not accepted`)
        continue
      }

      // For single file mode, replace existing
      if (!this.multipleValue && this.files.size > 0) {
        this.clearAllFiles()
      }

      validFiles.push(file)
    }

    return validFiles
  }

  isAcceptedType (file) {
    if (this.acceptValue === '*') return true

    const acceptPatterns = this.acceptValue.split(',').map(p => p.trim())

    return acceptPatterns.some(pattern => {
      if (pattern.startsWith('.')) {
        // Extension match (e.g., .pdf)
        return file.name.toLowerCase().endsWith(pattern.toLowerCase())
      } else if (pattern.endsWith('/*')) {
        // MIME type wildcard (e.g., image/*)
        const type = pattern.slice(0, -2)
        return file.type.startsWith(type)
      } else {
        // Exact MIME type (e.g., application/pdf)
        return file.type === pattern
      }
    })
  }

  // ==================== Upload ====================

  uploadFile (id) {
    const fileData = this.files.get(id)
    if (!fileData || fileData.status === 'uploading') return

    fileData.status = 'uploading'
    fileData.progress = 0
    fileData.error = null
    this.updateFileUI(id)

    const upload = new DirectUpload(fileData.file, this.urlValue, {
      directUploadWillStoreFileWithXHR: (xhr) => {
        fileData.xhr = xhr
        xhr.upload.addEventListener('progress', (event) => {
          if (event.lengthComputable) {
            const progress = Math.round((event.loaded / event.total) * 100)
            this.updateProgress(id, progress)
          }
        })
      }
    })

    upload.create((error, blob) => {
      if (error) {
        this.handleError(id, error)
      } else {
        this.handleSuccess(id, blob.signed_id)
      }
    })
  }

  updateProgress (id, progress) {
    const fileData = this.files.get(id)
    if (!fileData) return

    fileData.progress = progress
    this.updateFileUI(id)
  }

  handleSuccess (id, signedId) {
    const fileData = this.files.get(id)
    if (!fileData) return

    fileData.status = 'completed'
    fileData.signedId = signedId
    fileData.progress = 100
    fileData.xhr = null

    this.updateFileUI(id)
    this.createHiddenField(id, signedId)

    // Announce success
    this.announce(`${fileData.file.name} uploaded successfully`)

    // Dispatch completion event
    this.dispatch('complete', { detail: { id, filename: fileData.file.name, signedId } })

    // Check if all uploads are complete
    if (this.getUploadingCount() === 0) {
      this.dispatch('all-complete', { detail: { count: this.files.size } })
    }
  }

  handleError (id, error) {
    const fileData = this.files.get(id)
    if (!fileData) return

    fileData.status = 'error'
    fileData.error = error.message || 'Upload failed'
    fileData.xhr = null

    this.updateFileUI(id)

    // Announce error
    this.announce(`Failed to upload ${fileData.file.name}: ${fileData.error}`)
  }

  // ==================== Actions ====================

  cancel (event) {
    const id = this.getFileIdFromEvent(event)
    const fileData = this.files.get(id)
    if (!fileData) return

    // Abort XHR if in progress
    if (fileData.xhr) {
      fileData.xhr.abort()
    }

    this.removeFile(id)
  }

  retry (event) {
    const id = this.getFileIdFromEvent(event)
    this.uploadFile(id)
  }

  remove (event) {
    const id = this.getFileIdFromEvent(event)
    this.removeFile(id)
  }

  removeFile (id) {
    const fileData = this.files.get(id)
    if (!fileData) return

    // Remove UI element
    if (fileData.element) {
      fileData.element.remove()
    }

    // Remove hidden field if exists
    this.removeHiddenField(id)

    // Remove from map
    this.files.delete(id)
  }

  clearAllFiles () {
    for (const id of this.files.keys()) {
      this.removeFile(id)
    }
  }

  // ==================== Drag & Drop ====================

  dragenter (event) {
    event.preventDefault()
    this.dragCounter++
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add('border-primary', 'bg-primary/10')
    }
  }

  dragover (event) {
    event.preventDefault()
  }

  dragleave (event) {
    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter === 0 && this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove('border-primary', 'bg-primary/10')
    }
  }

  drop (event) {
    event.preventDefault()
    this.dragCounter = 0
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove('border-primary', 'bg-primary/10')
    }

    const files = Array.from(event.dataTransfer.files)
    this.addFiles(files)
  }

  // Keyboard support for dropzone (Enter/Space to open file picker)
  dropzoneKeydown (event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.openFilePicker()
    }
  }

  // ==================== Existing Attachments ====================

  removeExisting (event) {
    const button = event.currentTarget
    const attachmentId = button.dataset.attachmentId
    const row = button.closest('[data-attachment-id]')

    if (!attachmentId || !row) return

    // Add to removed set
    this.removedAttachmentIds.add(attachmentId)

    // Create hidden field to mark for removal
    this.createRemoveField(attachmentId)

    // Remove from UI with animation
    row.style.opacity = '0.5'
    row.style.textDecoration = 'line-through'

    // Disable remove button
    button.disabled = true

    // Announce removal
    const filename = row.querySelector('.font-medium')?.textContent || 'File'
    this.announce(`${filename} marked for removal`)
  }

  createRemoveField (attachmentId) {
    if (!this.hasRemoveFieldsTarget) return

    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = this.removeFieldNameValue
    input.value = attachmentId
    input.dataset.attachmentId = attachmentId

    this.removeFieldsTarget.appendChild(input)
  }

  // ==================== UI Rendering ====================

  renderFileItem (id) {
    const fileData = this.files.get(id)
    if (!fileData || !this.hasTemplateTarget) return

    const template = this.templateTarget.content.cloneNode(true)
    const element = template.firstElementChild

    element.dataset.fileId = id
    element.querySelector('.file-name').textContent = fileData.file.name
    element.querySelector('.file-size').textContent = this.formatFileSize(fileData.file.size)

    this.fileListTarget.appendChild(element)
    fileData.element = this.fileListTarget.querySelector(`[data-file-id="${id}"]`)

    this.updateFileUI(id)
  }

  updateFileUI (id) {
    const fileData = this.files.get(id)
    if (!fileData || !fileData.element) return

    const element = fileData.element
    const progress = element.querySelector('progress')
    const percentage = element.querySelector('.percentage')
    const progressContainer = element.querySelector('.file-progress')
    const errorEl = element.querySelector('.file-error')
    const cancelBtn = element.querySelector('.file-cancel')
    const retryBtn = element.querySelector('.file-retry')
    const removeBtn = element.querySelector('.file-remove')
    const successIcon = element.querySelector('.file-success')

    // Update progress and ARIA attributes
    progress.value = fileData.progress
    progress.setAttribute('aria-valuenow', fileData.progress)
    progress.setAttribute('aria-label', `Uploading ${fileData.file.name}: ${fileData.progress}%`)
    percentage.textContent = `${fileData.progress}%`

    // Reset visibility
    progressContainer.classList.remove('hidden')
    errorEl.classList.add('hidden')
    cancelBtn.classList.remove('hidden')
    retryBtn.classList.add('hidden')
    removeBtn.classList.add('hidden')
    successIcon.classList.add('hidden')

    // Update button aria-labels with filename
    const filename = fileData.file.name
    cancelBtn.setAttribute('aria-label', `Cancel upload of ${filename}`)
    retryBtn.setAttribute('aria-label', `Retry upload of ${filename}`)
    removeBtn.setAttribute('aria-label', `Remove ${filename}`)

    switch (fileData.status) {
      case 'pending':
        percentage.textContent = 'Waiting...'
        progress.setAttribute('aria-label', `Waiting to upload ${filename}`)
        break

      case 'uploading':
        // Default state shown above
        break

      case 'completed':
        progressContainer.classList.add('hidden')
        percentage.classList.add('hidden')
        cancelBtn.classList.add('hidden')
        removeBtn.classList.remove('hidden')
        successIcon.classList.remove('hidden')
        break

      case 'error':
        progressContainer.classList.add('hidden')
        percentage.classList.add('hidden')
        errorEl.textContent = fileData.error
        errorEl.classList.remove('hidden')
        cancelBtn.classList.add('hidden')
        retryBtn.classList.remove('hidden')
        removeBtn.classList.remove('hidden')
        break
    }
  }

  // ==================== Hidden Fields ====================

  createHiddenField (id, signedId) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = this.fieldNameValue
    input.value = signedId
    input.dataset.directUploadId = id

    this.hiddenFieldsTarget.appendChild(input)
  }

  removeHiddenField (id) {
    const input = this.hiddenFieldsTarget.querySelector(`[data-direct-upload-id="${id}"]`)
    if (input) {
      input.remove()
    }
  }

  // ==================== Helpers ====================

  generateFileId () {
    return `file-${++this.fileIdCounter}`
  }

  getFileIdFromEvent (event) {
    const element = event.target.closest('[data-file-id]')
    return element?.dataset.fileId
  }

  formatFileSize (bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  showError (message) {
    console.warn('[DirectUpload]', message)
    this.dispatch('error', { detail: { message } })

    // Show visible error alert
    if (this.hasErrorAlertTarget && this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorAlertTarget.classList.remove('hidden')

      // Auto-dismiss after 5 seconds
      clearTimeout(this.errorDismissTimeout)
      this.errorDismissTimeout = setTimeout(() => {
        this.dismissError()
      }, 5000)
    }
  }

  dismissError () {
    if (this.hasErrorAlertTarget) {
      this.errorAlertTarget.classList.add('hidden')
    }
    clearTimeout(this.errorDismissTimeout)
  }

  // ==================== Accessibility ====================

  /**
   * Announce a message to screen readers via live region
   */
  announce (message) {
    if (this.hasAnnouncerTarget) {
      this.announcerTarget.textContent = message
      // Clear after announcement to allow repeated messages
      setTimeout(() => {
        this.announcerTarget.textContent = ''
      }, 1000)
    }
  }
}
