import { Controller } from '@hotwired/stimulus'

/**
 * DocumentEditor Controller
 *
 * Manages the full-screen document editor overlay behavior including:
 * - Table of contents panel toggle
 * - Comments and history side panels
 * - Auto-save with configurable delay
 * - Version history loading and restoration
 * - Keyboard shortcuts (Escape to close, Ctrl/Cmd+S to save)
 */
export class DocumentEditorController extends Controller {
  static targets = [
    'titleInput', 'tocPanel', 'tocContainer',
    'commentsPanel', 'commentsToggle',
    'historyPanel', 'historyToggle',
    'versionsList', 'versionTemplate', 'saveStatus', 'saveButton',
    'previewBanner', 'previewVersionLabel',
    'editorArea'
  ]

  static values = {
    autoSave: { type: Boolean, default: true },
    autoSaveDelay: { type: Number, default: 30000 },
    documentUrl: String,
    closeUrl: String,
    versionsUrl: String,
    inputName: { type: String, default: 'document[content]' },
    tocOpen: { type: Boolean, default: true },
    panel: { type: String, default: '' }
  }

  connect () {
    this.saveTimeout = null
    this.bindKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.bindKeydown)

    // Only lock body scroll when the editor is visible.
    // When rendered inside a hidden overlay (e.g., document show page),
    // defer the lock until the overlay becomes visible.
    if (this._isVisible()) {
      this._lockBodyScroll()
    } else {
      this._visibilityObserver = new window.MutationObserver(() => {
        if (this._isVisible()) {
          this._lockBodyScroll()
          this._visibilityObserver.disconnect()
          this._visibilityObserver = null
        }
      })
      if (this.element.parentElement) {
        this._visibilityObserver.observe(this.element.parentElement, {
          attributes: true, attributeFilter: ['class']
        })
      }
    }
  }

  disconnect () {
    document.removeEventListener('keydown', this.bindKeydown)
    if (this._scrollLocked) {
      document.body.style.overflow = this._previousOverflow || ''
    }
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    if (this._visibilityObserver) {
      this._visibilityObserver.disconnect()
      this._visibilityObserver = null
    }
  }

  toggleToc () {
    this.tocOpenValue = !this.tocOpenValue
  }

  tocOpenValueChanged () {
    if (this.hasTocPanelTarget) {
      this.tocPanelTarget.classList.toggle('hidden', !this.tocOpenValue)
    }
  }

  toggleComments () {
    this.panelValue = this.panelValue === 'comments' ? '' : 'comments'
  }

  toggleHistory () {
    this.panelValue = this.panelValue === 'history' ? '' : 'history'
    if (this.panelValue === 'history') this.loadVersions()
  }

  panelValueChanged () {
    if (this.hasCommentsPanelTarget) {
      this.commentsPanelTarget.classList.toggle('hidden', this.panelValue !== 'comments')
    }
    if (this.hasHistoryPanelTarget) {
      this.historyPanelTarget.classList.toggle('hidden', this.panelValue !== 'history')
    }
    if (this.hasCommentsToggleTarget) {
      this.commentsToggleTarget.classList.toggle('btn-active', this.panelValue === 'comments')
    }
    if (this.hasHistoryToggleTarget) {
      this.historyToggleTarget.classList.toggle('btn-active', this.panelValue === 'history')
    }
  }

  titleChanged () {
    this.scheduleSave()
  }

  contentChanged () {
    this.scheduleSave()
  }

  scheduleSave () {
    this._dirty = true
    this._updateStatus('Unsaved changes')
    if (!this.autoSaveValue) return
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => { this.save() }, this.autoSaveDelayValue)
  }

  async save () {
    if (this._saving) return
    this._saving = true
    this._updateStatus('Saving...')
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const body = { document: {} }

    if (this.hasTitleInputTarget) {
      body.document.title = this.titleInputTarget.value
    }

    const contentInput = this.element.querySelector(`input[name='${this.inputNameValue}']`)
    if (contentInput) {
      body.document.content = contentInput.value
    }

    try {
      const response = await fetch(this.documentUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          Accept: 'application/json'
        },
        body: JSON.stringify(body)
      })
      if (response.ok) {
        this._dirty = false
        this._updateStatus(`Saved at ${new Date().toLocaleTimeString()}`)
      } else {
        this._updateStatus('Save failed', true)
        console.error('Auto-save failed:', response.status)
      }
    } catch (error) {
      this._updateStatus('Save failed', true)
      console.error('Auto-save error:', error)
    } finally {
      this._saving = false
      // If new changes came in during save, show unsaved and re-schedule
      if (this._dirty) {
        this._updateStatus('Unsaved changes')
        if (this.autoSaveValue) {
          if (this.saveTimeout) clearTimeout(this.saveTimeout)
          this.saveTimeout = setTimeout(() => { this.save() }, this.autoSaveDelayValue)
        }
      }
    }
  }

  async loadVersions () {
    if (!this.versionsUrlValue || !this.hasVersionsListTarget) return

    try {
      const response = await fetch(this.versionsUrlValue, {
        headers: { Accept: 'application/json' }
      })
      const versions = await response.json()
      this.renderVersions(versions)
    } catch (error) {
      console.error('Failed to load versions:', error)
      this.versionsListTarget.replaceChildren()
      const p = document.createElement('p')
      p.className = 'text-sm text-error'
      p.textContent = 'Failed to load versions.'
      this.versionsListTarget.appendChild(p)
    }
  }

  renderVersions (versions) {
    this.versionsListTarget.replaceChildren()

    if (!versions.length) {
      const p = document.createElement('p')
      p.className = 'text-sm text-base-content/50'
      p.textContent = 'No versions yet.'
      this.versionsListTarget.appendChild(p)
      return
    }

    versions.forEach(v => {
      this.versionsListTarget.appendChild(this._buildVersionItem(v))
    })
  }

  async restoreVersion (event) {
    const versionId = event.currentTarget.dataset.versionId
    if (!window.confirm('Restore this version? Current content will be saved as a new version first.')) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(`${this.documentUrlValue}/restore_version`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          Accept: 'application/json'
        },
        body: JSON.stringify({ version_id: versionId })
      })
      if (response.ok) window.location.reload()
    } catch (error) {
      console.error('Restore failed:', error)
    }
  }

  async previewVersion (event) {
    const versionId = event.currentTarget.dataset.versionId
    const versionNumber = event.currentTarget.dataset.versionNumber

    try {
      const response = await fetch(`${this.versionsUrlValue}/${versionId}`, {
        headers: { Accept: 'application/json' }
      })
      const version = await response.json()

      // Store current content for restoring later
      const blockEditor = this._blockEditorController()
      if (!blockEditor || !blockEditor.blockNoteEditor) {
        // Fallback: open in new tab if editor not available
        window.open(`${this.versionsUrlValue}/${versionId}`, '_blank')
        return
      }

      const editor = blockEditor.blockNoteEditor
      this._savedContent = editor._tiptapEditor.getJSON()
      this._savedEditable = editor.isEditable

      // Load version content into the editor (read-only)
      const content = typeof version.content === 'string' ? JSON.parse(version.content) : version.content
      if (content && content.type === 'doc') {
        editor._tiptapEditor.commands.setContent(content)
      } else if (Array.isArray(content)) {
        editor.replaceBlocks(editor.document, content)
      }
      editor.isEditable = false

      // Show preview banner
      if (this.hasPreviewBannerTarget) {
        this.previewBannerTarget.classList.remove('hidden')
        if (this.hasPreviewVersionLabelTarget) {
          this.previewVersionLabelTarget.textContent = `Version ${versionNumber || version.version_number}`
        }
      }
    } catch (error) {
      console.error('Preview failed:', error)
    }
  }

  exitPreview () {
    const blockEditor = this._blockEditorController()
    if (!blockEditor || !blockEditor.blockNoteEditor || !this._savedContent) return

    const editor = blockEditor.blockNoteEditor
    editor._tiptapEditor.commands.setContent(this._savedContent)
    editor.isEditable = this._savedEditable ?? true
    this._savedContent = null
    this._savedEditable = null

    if (this.hasPreviewBannerTarget) {
      this.previewBannerTarget.classList.add('hidden')
    }
  }

  exportPdf () {
    this._blockEditorController()?.exportPdf()
  }

  exportDocx () {
    this._blockEditorController()?.exportDocx()
  }

  handleKeydown (event) {
    if (event.key === 'Escape') {
      event.preventDefault()
      this.close()
    }
    if ((event.ctrlKey || event.metaKey) && event.key === 's') {
      event.preventDefault()
      this.save()
    }
  }

  close () {
    window.location.href = this.closeUrlValue || this.documentUrlValue
  }

  _blockEditorController () {
    const el = this.element.querySelector('[data-controller~="block-editor"]')
    if (!el) return null
    return this.application.getControllerForElementAndIdentifier(el, 'block-editor')
  }

  _buildVersionItem (v) {
    const fragment = this.versionTemplateTarget.content.cloneNode(true)
    const el = fragment.firstElementChild

    el.querySelector('[data-version-field="number"]').textContent = `v${v.version_number}`
    el.querySelector('[data-version-field="time"]').textContent = this._timeAgo(v.created_at)
    el.querySelector('[data-version-field="avatar"]').textContent = (v.author_name || '?')[0].toUpperCase()
    el.querySelector('[data-version-field="author"]').textContent = v.author_name

    const summary = el.querySelector('[data-version-field="summary"]')
    if (v.summary) {
      summary.textContent = v.summary
      summary.classList.remove('hidden')
    }

    const previewBtn = el.querySelector('[data-action*="previewVersion"]')
    previewBtn.dataset.versionId = v.id
    previewBtn.dataset.versionNumber = v.version_number

    el.querySelector('[data-action*="restoreVersion"]').dataset.versionId = v.id

    return fragment
  }

  _updateStatus (text, error = false) {
    if (this.hasSaveStatusTarget) {
      this.saveStatusTarget.textContent = text
      this.saveStatusTarget.classList.toggle('text-error', error)
      this.saveStatusTarget.classList.toggle('text-base-content/50', !error)
    }
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = !this._dirty
    }
  }

  _isVisible () {
    // offsetParent is null for position:fixed elements, so use getClientRects
    return this.element.getClientRects().length > 0
  }

  _lockBodyScroll () {
    this._previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    this._scrollLocked = true
  }

  _timeAgo (dateString) {
    const date = new Date(dateString)
    const now = new Date()
    const seconds = Math.floor((now - date) / 1000)
    if (seconds < 60) return 'just now'
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`
    return `${Math.floor(seconds / 86400)}d ago`
  }
}
