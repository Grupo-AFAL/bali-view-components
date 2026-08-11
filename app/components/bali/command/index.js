import { Controller } from '@hotwired/stimulus'

/**
 * Command palette controller — Linear/Notion-style ⌘K launcher.
 *
 * Targets:
 *   - surface    <dialog> holding the backdrop and the panel, opened with
 *                showModal() so the palette lands in the top layer — over a
 *                Modal or a Drawer, which are top-layer dialogs themselves
 *   - panel      Modal container (toggled hidden/visible)
 *   - backdrop   Click-to-close overlay
 *   - input      Search input
 *   - group      One per <Group> component (used to show/hide group headers)
 *   - row        One per <Item> component (filtered + highlighted)
 *   - noResults  "No matches" message (shown when query has no regular hits)
 *   - count      Result count display in the footer
 *
 * Global events (window), listened for:
 *   - bali:command:open    → opens the palette
 *   - bali:command:close   → closes the palette
 *   - bali:command:toggle  → toggles
 *
 * Emitted:
 *   - bali:command:select  → an item without an href was activated
 */
// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event name stays put when a host registers this controller under a
// different identifier.
const EVENT_PREFIX = 'bali:command'

export class CommandController extends Controller {
  static targets = [
    'surface', 'panel', 'backdrop', 'input', 'group', 'row', 'noResults', 'count'
  ]

  static values = {
    open: { type: Boolean, default: false }
  }

  connect () {
    this._handleKeydown = this._handleKeydown.bind(this)
    this._handleGlobalOpen = () => this.open()
    this._handleGlobalClose = () => this.close()
    this._handleGlobalToggle = () => (this.openValue ? this.close() : this.open())
    // A dialog answers a close request on its own. `_handleKeydown` cancels every
    // Escape it sees while the palette is open, so this only runs for a request
    // that never reached it — and it keeps `openValue` and the hidden classes in
    // step with the element instead of letting them drift apart.
    this._handleSurfaceCancel = event => {
      event.preventDefault()
      this.close()
    }

    if (this.hasSurfaceTarget) {
      this.surfaceTarget.addEventListener('cancel', this._handleSurfaceCancel)
    }

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

    if (this.hasSurfaceTarget) {
      this.surfaceTarget.removeEventListener('cancel', this._handleSurfaceCancel)
    }
  }

  open (event) {
    event?.preventDefault()
    if (this.openValue) return
    this.openValue = true
    this._showSurface()
    this.panelTarget.classList.remove('hidden')
    this.backdropTarget.classList.remove('hidden')
    this.filter()
    window.requestAnimationFrame(() => this.inputTarget.focus())
  }

  close (event) {
    event?.preventDefault()
    if (!this.openValue) return
    this.openValue = false
    this.panelTarget.classList.add('hidden')
    this.backdropTarget.classList.add('hidden')
    this._hideSurface()
    if (this.hasInputTarget) this.inputTarget.value = ''
  }

  // The palette is painted in the top layer or it is painted under the drawer
  // whose field the user was filling in. Guarded rather than assumed so a host
  // that hand-writes the markup without the dialog keeps working on the classes
  // alone, exactly as it did before.
  _showSurface () {
    if (!this.hasSurfaceTarget) return
    const surface = this.surfaceTarget
    if (typeof surface.showModal !== 'function' || surface.open) return

    try {
      surface.showModal()
    } catch {
      // Not connected yet; the hidden classes still show the palette.
    }
  }

  _hideSurface () {
    if (!this.hasSurfaceTarget) return
    if (this.surfaceTarget.open) this.surfaceTarget.close()
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
      const text = (row.dataset.search || row.textContent).toLowerCase()
      const matches = !isEmpty && text.includes(query)
      let visible

      if (mode === 'action') {
        visible = true
      } else if (mode === 'recent') {
        visible = isEmpty
      } else if (mode === 'navigation') {
        // The whole list while the query is empty, narrowed once the user
        // types. `action` is deliberately NOT this: it survives every query so
        // its command stays reachable under the no-results message, which is
        // why a directory of pages declared as `action` never filtered.
        visible = isEmpty || matches
      } else {
        visible = matches
      }

      row.classList.toggle('hidden', !visible)
      if (visible) visibleCount++

      // Both halves of "this row answered the query": it counts against the
      // no-results message and gets its match highlighted. `action` rows stay
      // out of the count — they are always on screen, so counting them would
      // suppress the message for a query that nothing actually matched.
      if (matches && (mode === 'searchable' || mode === 'navigation')) {
        regularResultsCount++
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
      // Prefer Turbo navigation when available so we stay inside the SPA shell;
      // fall back to a hard navigation when Turbo isn't loaded.
      if (window.Turbo && typeof window.Turbo.visit === 'function') {
        window.Turbo.visit(href)
      } else {
        window.location.href = href
      }
      return
    }
    // Custom event so consumers can hook actions without an href
    this.dispatch('select', {
      prefix: EVENT_PREFIX,
      detail: { row, value: row.dataset.value }
    })
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
      if (this.openValue) {
        this.close()
      } else {
        this.open()
      }
      return
    }
    // Esc closes the palette when it's open (even when input doesn't have focus)
    if (e.key === 'Escape' && this.openValue) {
      e.preventDefault()
      this.close()
    }
  }
}
