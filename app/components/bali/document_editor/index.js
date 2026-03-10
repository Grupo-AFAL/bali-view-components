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
    'versionsList', 'saveStatus', 'saveButton',
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
    this._previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
  }

  disconnect () {
    document.removeEventListener('keydown', this.bindKeydown)
    document.body.style.overflow = this._previousOverflow || ''
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
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
    const wrapper = document.createElement('div')
    wrapper.className = 'version-item group'

    // Top row: version badge + time
    const header = document.createElement('div')
    header.className = 'flex items-center justify-between mb-1.5'

    const badge = document.createElement('span')
    badge.className = 'inline-flex items-center gap-1.5 text-xs font-semibold text-base-content'
    badge.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-50"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> v${v.version_number}`
    header.appendChild(badge)

    const timeLabel = document.createElement('span')
    timeLabel.className = 'text-[11px] text-base-content/40 tabular-nums'
    timeLabel.textContent = this._timeAgo(v.created_at)
    header.appendChild(timeLabel)

    wrapper.appendChild(header)

    // Author row
    const authorRow = document.createElement('div')
    authorRow.className = 'flex items-center gap-1.5 mb-1'

    const avatar = document.createElement('span')
    avatar.className = 'inline-flex items-center justify-center w-4 h-4 rounded-full bg-base-content/10 text-[9px] font-bold text-base-content/60 shrink-0'
    avatar.textContent = (v.author_name || '?')[0].toUpperCase()
    authorRow.appendChild(avatar)

    const authorName = document.createElement('span')
    authorName.className = 'text-xs text-base-content/60'
    authorName.textContent = v.author_name
    authorRow.appendChild(authorName)

    wrapper.appendChild(authorRow)

    // Summary
    if (v.summary) {
      const summary = document.createElement('p')
      summary.className = 'text-[11px] text-base-content/40 leading-relaxed mb-1 italic'
      summary.textContent = v.summary
      wrapper.appendChild(summary)
    }

    // Actions: show on hover
    const actions = document.createElement('div')
    actions.className = 'flex items-center gap-1 mt-2 pt-2 border-t border-base-200/60'

    const previewBtn = document.createElement('button')
    previewBtn.className = 'version-btn version-btn-preview'
    previewBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg> Preview'
    previewBtn.dataset.action = 'document-editor#previewVersion'
    previewBtn.dataset.versionId = v.id
    previewBtn.dataset.versionNumber = v.version_number
    actions.appendChild(previewBtn)

    const restoreBtn = document.createElement('button')
    restoreBtn.className = 'version-btn version-btn-restore'
    restoreBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg> Restore'
    restoreBtn.dataset.action = 'document-editor#restoreVersion'
    restoreBtn.dataset.versionId = v.id
    actions.appendChild(restoreBtn)

    wrapper.appendChild(actions)
    return wrapper
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
