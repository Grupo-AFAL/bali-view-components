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
    'versionsList'
  ]

  static values = {
    autoSave: { type: Boolean, default: true },
    autoSaveDelay: { type: Number, default: 3000 },
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
    if (!this.autoSaveValue) return
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => { this.save() }, this.autoSaveDelayValue)
  }

  async save () {
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
      if (!response.ok) console.error('Auto-save failed:', response.status)
    } catch (error) {
      console.error('Auto-save error:', error)
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
    window.open(`${this.versionsUrlValue}/${versionId}`, '_blank')
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
    wrapper.className = 'py-3 border-b border-base-200 last:border-0'

    const header = document.createElement('div')
    header.className = 'flex items-center justify-between'

    const versionLabel = document.createElement('span')
    versionLabel.className = 'text-sm font-medium'
    versionLabel.textContent = `Version ${v.version_number}`
    header.appendChild(versionLabel)

    const timeLabel = document.createElement('span')
    timeLabel.className = 'text-xs text-base-content/50'
    timeLabel.textContent = this._timeAgo(v.created_at)
    header.appendChild(timeLabel)

    wrapper.appendChild(header)

    const author = document.createElement('p')
    author.className = 'text-xs text-base-content/60 mt-1'
    author.textContent = v.author_name
    wrapper.appendChild(author)

    if (v.summary) {
      const summary = document.createElement('p')
      summary.className = 'text-xs text-base-content/50 mt-1'
      summary.textContent = v.summary
      wrapper.appendChild(summary)
    }

    const actions = document.createElement('div')
    actions.className = 'flex gap-2 mt-2'

    const previewBtn = document.createElement('button')
    previewBtn.className = 'btn btn-ghost btn-xs'
    previewBtn.textContent = 'Preview'
    previewBtn.dataset.action = 'document-editor#previewVersion'
    previewBtn.dataset.versionId = v.id
    actions.appendChild(previewBtn)

    const restoreBtn = document.createElement('button')
    restoreBtn.className = 'btn btn-ghost btn-xs'
    restoreBtn.textContent = 'Restore'
    restoreBtn.dataset.action = 'document-editor#restoreVersion'
    restoreBtn.dataset.versionId = v.id
    actions.appendChild(restoreBtn)

    wrapper.appendChild(actions)
    return wrapper
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
