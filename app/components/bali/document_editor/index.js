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
    versionsUrl: String,
    tocOpen: { type: Boolean, default: true },
    panel: { type: String, default: '' }
  }

  connect () {
    this.saveTimeout = null
    this.bindKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.bindKeydown)
    document.body.style.overflow = 'hidden'
  }

  disconnect () {
    document.removeEventListener('keydown', this.bindKeydown)
    document.body.style.overflow = ''
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

    const contentInput = this.element.querySelector("input[name='document[content]']")
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
      this.versionsListTarget.innerHTML = '<p class="text-sm text-error">Failed to load versions.</p>'
    }
  }

  renderVersions (versions) {
    if (!versions.length) {
      this.versionsListTarget.innerHTML = '<p class="text-sm text-base-content/50">No versions yet.</p>'
      return
    }

    this.versionsListTarget.innerHTML = versions.map(v => `
      <div class="py-3 border-b border-base-200 last:border-0">
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium">Version ${v.version_number}</span>
          <span class="text-xs text-base-content/50">${this.timeAgo(v.created_at)}</span>
        </div>
        <p class="text-xs text-base-content/60 mt-1">${v.author_name}</p>
        ${v.summary ? `<p class="text-xs text-base-content/50 mt-1">${v.summary}</p>` : ''}
        <div class="flex gap-2 mt-2">
          <button class="btn btn-ghost btn-xs"
                  data-action="document-editor#previewVersion"
                  data-version-id="${v.id}">Preview</button>
          <button class="btn btn-ghost btn-xs"
                  data-action="document-editor#restoreVersion"
                  data-version-id="${v.id}">Restore</button>
        </div>
      </div>
    `).join('')
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
    const closeLink = this.element.querySelector("a[data-action*='close']")
    window.location.href = closeLink?.href || this.documentUrlValue
  }

  timeAgo (dateString) {
    const date = new Date(dateString)
    const now = new Date()
    const seconds = Math.floor((now - date) / 1000)
    if (seconds < 60) return 'just now'
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`
    return `${Math.floor(seconds / 86400)}d ago`
  }
}
