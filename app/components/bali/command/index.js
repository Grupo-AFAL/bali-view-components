import { Controller } from '@hotwired/stimulus'

/**
 * Command palette controller — Linear/Notion-style ⌘K launcher.
 *
 * Targets:
 *   - panel      Modal container (toggled hidden/visible)
 *   - backdrop   Click-to-close overlay
 *   - input      Search input
 *   - group      One per <Group> component (used to show/hide group headers)
 *   - row        One per <Item> component (filtered + highlighted)
 *   - noResults  "No matches" message (shown when query has no regular hits)
 *   - count      Result count display in the footer
 *
 * Global events (window):
 *   - bali:command:open    → opens the palette
 *   - bali:command:close   → closes the palette
 *   - bali:command:toggle  → toggles
 */
export class CommandController extends Controller {
  static targets = [
    'panel', 'backdrop', 'input', 'group', 'row', 'noResults', 'count'
  ]

  static values = {
    open: { type: Boolean, default: false }
  }

  connect () {
    this._handleKeydown = this._handleKeydown.bind(this)
    this._handleGlobalOpen = () => this.open()
    this._handleGlobalClose = () => this.close()
    this._handleGlobalToggle = () => (this.openValue ? this.close() : this.open())

    document.addEventListener('keydown', this._handleKeydown)
    window.addEventListener('bali:command:open', this._handleGlobalOpen)
    window.addEventListener('bali:command:close', this._handleGlobalClose)
    window.addEventListener('bali:command:toggle', this._handleGlobalToggle)

    this._activeIndex = 0
    this.filter()
  }

  disconnect () {
    document.removeEventListener('keydown', this._handleKeydown)
    window.removeEventListener('bali:command:open', this._handleGlobalOpen)
    window.removeEventListener('bali:command:close', this._handleGlobalClose)
    window.removeEventListener('bali:command:toggle', this._handleGlobalToggle)
  }

  open (event) {
    event?.preventDefault()
    if (this.openValue) return
    this.openValue = true
    this.panelTarget.classList.remove('hidden')
    this.backdropTarget.classList.remove('hidden')
    this.filter()
    requestAnimationFrame(() => this.inputTarget.focus())
  }

  close (event) {
    event?.preventDefault()
    if (!this.openValue) return
    this.openValue = false
    this.panelTarget.classList.add('hidden')
    this.backdropTarget.classList.add('hidden')
    if (this.hasInputTarget) this.inputTarget.value = ''
  }

  filter () {
    const query = this.hasInputTarget
      ? this.inputTarget.value.trim().toLowerCase()
      : ''
    const isEmpty = query.length === 0
    let visibleCount = 0
    let regularResultsCount = 0

    this.rowTargets.forEach(row => {
      const mode = row.dataset.mode || 'searchable'
      let visible

      if (mode === 'action') {
        visible = true
      } else if (mode === 'recent') {
        visible = isEmpty
      } else {
        const text = (row.dataset.search || row.textContent).toLowerCase()
        visible = !isEmpty && text.includes(query)
        if (visible) regularResultsCount++
      }

      row.classList.toggle('hidden', !visible)
      if (visible) visibleCount++

      if (visible && !isEmpty && mode === 'searchable') {
        this._highlight(row, query)
      } else {
        this._unhighlight(row)
      }
    })

    // Hide groups whose items are all hidden
    this.groupTargets.forEach(group => {
      const visibleItems = group.querySelectorAll('.cmd-row:not(.hidden)').length
      group.classList.toggle('hidden', visibleItems === 0)
    })

    // Show no-results message when there's a query but no regular matches
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.toggle(
        'hidden',
        isEmpty || regularResultsCount > 0
      )
    }

    if (this.hasCountTarget) {
      const label = visibleCount === 1 ? 'result' : 'results'
      this.countTarget.textContent = `${visibleCount} ${label}`
    }

    this._activeIndex = 0
    this._updateActive()
  }

  nav (event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this._move(1)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this._move(-1)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      this._activate()
    } else if (event.key === 'Escape') {
      event.preventDefault()
      this.close()
    }
  }

  select (event) {
    this._activateRow(event.currentTarget)
  }

  _move (delta) {
    const visible = this._visibleRows()
    if (visible.length === 0) return
    this._activeIndex =
      (this._activeIndex + delta + visible.length) % visible.length
    this._updateActive()
  }

  _updateActive () {
    this.rowTargets.forEach(r => r.classList.remove('is-active'))
    const visible = this._visibleRows()
    if (visible.length === 0) return
    const idx = Math.min(this._activeIndex, visible.length - 1)
    visible[idx].classList.add('is-active')
    visible[idx].scrollIntoView({ block: 'nearest' })
  }

  _activate () {
    const visible = this._visibleRows()
    if (visible.length === 0) return
    const idx = Math.min(this._activeIndex, visible.length - 1)
    this._activateRow(visible[idx])
  }

  _activateRow (row) {
    const href = row.dataset.href
    if (href) {
      window.location.href = href
      return
    }
    // Custom event so consumers can hook actions without an href
    this.element.dispatchEvent(new CustomEvent('bali:command:select', {
      bubbles: true,
      detail: { row, value: row.dataset.value }
    }))
    this.close()
  }

  _visibleRows () {
    return this.rowTargets.filter(r => !r.classList.contains('hidden'))
  }

  _highlight (row, query) {
    [
      row.querySelector('.cmd-row-title'),
      row.querySelector('.cmd-row-meta')
    ].forEach(el => {
      if (!el) return
      const text = el.dataset.text || el.textContent
      if (!el.dataset.text) el.dataset.text = text
      const idx = text.toLowerCase().indexOf(query)
      if (idx < 0) {
        el.textContent = text
        return
      }
      const before = this._escape(text.slice(0, idx))
      const match = this._escape(text.slice(idx, idx + query.length))
      const after = this._escape(text.slice(idx + query.length))
      el.innerHTML = `${before}<mark class="cmd-mark">${match}</mark>${after}`
    })
  }

  _unhighlight (row) {
    [
      row.querySelector('.cmd-row-title'),
      row.querySelector('.cmd-row-meta')
    ].forEach(el => {
      if (el && el.dataset.text) el.textContent = el.dataset.text
    })
  }

  _escape (s) {
    const div = document.createElement('div')
    div.textContent = s
    return div.innerHTML
  }

  _handleKeydown (e) {
    // ⌘K (Mac) / Ctrl+K (Windows/Linux) — toggles the palette globally
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault()
      this.openValue ? this.close() : this.open()
      return
    }
    // Esc closes the palette when it's open (even when input doesn't have focus)
    if (e.key === 'Escape' && this.openValue) {
      e.preventDefault()
      this.close()
    }
  }
}
