import { Controller } from '@hotwired/stimulus'
import { confirmDialog } from '../../../assets/javascripts/bali/confirm/confirm_dialog.js'

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
    'versionsList', 'versionsError', 'versionsEmpty',
    'versionTemplate', 'saveStatus', 'saveButton',
    'previewBanner', 'previewVersionLabel',
    'editorArea'
  ]

  static values = {
    autoSave: { type: Boolean, default: true },
    autoSaveDelay: { type: Number, default: 30000 },
    documentUrl: String,
    closeUrl: String,
    versionsUrl: String,
    // Declared, not invented. This controller used to POST to
    // `${documentUrl}/restore_version`, which made the host's routes a guess.
    restoreVersionUrl: String,
    // Root key of the PATCH payload and the basis of the default inputName.
    // Hardcoding "document" assumed every host named its model Document.
    paramKey: { type: String, default: 'document' },
    inputName: { type: String, default: 'document[content]' },
    tocOpen: { type: Boolean, default: true },
    panel: { type: String, default: '' },
    // Every string this controller writes into the DOM. It used to hardcode them
    // in English, so a Spanish app showed "Unsaved changes" in its own toolbar.
    // The two that carry runtime data keep the Rails placeholder (`%{time}`,
    // `%{number}`) and get substituted here.
    locale: { type: String, default: '' },
    statusUnsaved: { type: String, default: '' },
    statusSaving: { type: String, default: '' },
    statusSaved: { type: String, default: '' },
    statusFailed: { type: String, default: '' },
    versionLabel: { type: String, default: '' },
    restoreConfirm: { type: String, default: '' }
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
    this._updateStatus(this.statusUnsavedValue)
    if (!this.autoSaveValue) return
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => { this.save() }, this.autoSaveDelayValue)
  }

  async save () {
    if (this._saving) return
    this._saving = true
    this._updateStatus(this.statusSavingValue)

    // Flush content synchronously to avoid the 500ms debounce in useContentSync
    // which can cause stale reads (e.g. missing comment marks)
    this._flushContent()

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const attributes = {}

    if (this.hasTitleInputTarget) {
      attributes.title = this.titleInputTarget.value
    }

    const contentInput = this.element.querySelector(`input[name='${this.inputNameValue}']`)
    if (contentInput) {
      attributes.content = contentInput.value
    }

    // Nothing to save (e.g. read-only viewer overlay with no inputs)
    if (Object.keys(attributes).length === 0) {
      this._saving = false
      return
    }

    const body = { [this.paramKeyValue]: attributes }

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
        this._updateStatus(this._savedStatus())
      } else {
        this._updateStatus(this.statusFailedValue, true)
        console.error('Auto-save failed:', response.status)
      }
    } catch (error) {
      this._updateStatus(this.statusFailedValue, true)
      console.error('Auto-save error:', error)
    } finally {
      this._saving = false
      // If new changes came in during save, show unsaved and re-schedule
      if (this._dirty) {
        this._updateStatus(this.statusUnsavedValue)
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
      this._showVersionsMessage('error')
    }
  }

  renderVersions (versions) {
    this.versionsListTarget.replaceChildren()
    this._showVersionsMessage(versions.length ? null : 'empty')

    versions.forEach(v => {
      this.versionsListTarget.appendChild(this._buildVersionItem(v))
    })
  }

  async restoreVersion (event) {
    const versionId = event.currentTarget.dataset.versionId
    // The dialog's own labels come off the button's data-bali-confirm-* attributes,
    // which the server renders translated.
    const confirmed = await confirmDialog(this.restoreConfirmValue, null, event.currentTarget)
    if (!confirmed) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.restoreVersionUrlValue, {
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
    const versionNumber = event.currentTarget.dataset.versionNumber
    // The URL comes from the version's own JSON (`url`), not from a path this
    // controller assembles. _buildVersionItem still derives it when the payload
    // omits the field, so a host that has not adopted the richer shape keeps working.
    const versionUrl = event.currentTarget.dataset.versionUrl
    if (!versionUrl) return

    try {
      const response = await fetch(versionUrl, {
        headers: { Accept: 'application/json' }
      })
      const version = await response.json()

      // Store current content for restoring later
      const blockEditor = this._blockEditorController()
      if (!blockEditor || !blockEditor.blockNoteEditor) {
        // Fallback: open in new tab if editor not available
        window.open(versionUrl, '_blank')
        return
      }

      const editor = blockEditor.blockNoteEditor
      // Only capture the current document on the first preview: previewing
      // another version while already previewing would otherwise overwrite
      // the saved content with the previewed version, and "Back to current"
      // would restore that version (read-only) instead of the real document.
      if (this._savedContent == null) {
        this._savedContent = editor._tiptapEditor.getJSON()
        this._savedEditable = editor.isEditable
      }

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
          this.previewVersionLabelTarget.textContent = this.versionLabelValue
            .replace('%{number}', versionNumber || version.version_number)
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
    previewBtn.dataset.versionUrl = v.url || `${this.versionsUrlValue}/${v.id}`

    el.querySelector('[data-action*="restoreVersion"]').dataset.versionId = v.id

    return fragment
  }

  _flushContent () {
    const blockEditor = this._blockEditorController()
    if (!blockEditor?.blockNoteEditor) return

    const editor = blockEditor.blockNoteEditor
    const contentInput = this.element.querySelector(`input[name='${this.inputNameValue}']`)
    if (!contentInput) return

    let hasComments = false
    editor._tiptapEditor.state.doc.descendants((node) => {
      if (!hasComments && node.marks?.some(m => m.type.name === 'comment')) {
        hasComments = true
      }
      return !hasComments
    })

    if (hasComments) {
      contentInput.value = JSON.stringify(editor._tiptapEditor.getJSON())
    } else {
      contentInput.value = JSON.stringify(editor.document)
    }
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

  // Relative time used to be four hardcoded English strings ('just now', '5m ago').
  // Intl.RelativeTimeFormat produces the same buckets in the app's own locale, so
  // there is nothing left to translate. `narrow` keeps it as short as the old
  // wording -- the slot it fills is 11px and tabular.
  _timeAgo (dateString) {
    const seconds = Math.floor((new Date() - new Date(dateString)) / 1000)
    const format = new Intl.RelativeTimeFormat(this.localeValue || undefined, {
      numeric: 'auto', style: 'narrow'
    })

    // 0 seconds renders as "now"/"ahora" with numeric: 'auto', which is what
    // 'just now' meant for the whole first minute.
    if (seconds < 60) return format.format(0, 'second')
    if (seconds < 3600) return format.format(-Math.floor(seconds / 60), 'minute')
    if (seconds < 86400) return format.format(-Math.floor(seconds / 3600), 'hour')
    return format.format(-Math.floor(seconds / 86400), 'day')
  }

  // The time is the only runtime value in the status line, so the placeholder is
  // substituted here and the sentence around it stays in the locale file.
  _savedStatus () {
    const time = new Date().toLocaleTimeString(this.localeValue || undefined)
    return this.statusSavedValue.replace('%{time}', time)
  }

  // Both messages are already in the DOM, translated; only one is ever visible.
  _showVersionsMessage (kind) {
    if (this.hasVersionsErrorTarget) {
      this.versionsErrorTarget.classList.toggle('hidden', kind !== 'error')
    }
    if (this.hasVersionsEmptyTarget) {
      this.versionsEmptyTarget.classList.toggle('hidden', kind !== 'empty')
    }
  }
}
