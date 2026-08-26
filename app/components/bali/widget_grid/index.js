import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'

// Turns grid gestures into a persisted layout: drag or arrow keys to reorder,
// the remove button to drop a card, a glyph to resize.
//
// Every gesture is the SAME operation as far as the server is concerned: each
// sends the whole layout — which widgets, in what order, at what size — and they
// differ only in what they do to the DOM first. One endpoint, one write path,
// one queue.
//
// Entering edit mode is `EditModeController`'s job; the two are composed on one
// element and share no state.
export class WidgetGridController extends Controller {
  static targets = ['grid', 'announcer']
  static values = {
    url: String,
    movedText: String,
    removedOneText: String,
    removedOtherText: String,
    removedLastText: String,
    failedText: String,
    resizedText: String
  }

  // A queued write belongs to a grid that no longer exists: without this, a
  // Turbo navigation during the debounce window fires a PATCH describing a DOM
  // that has already been replaced.
  disconnect () {
    clearTimeout(this.timer)
  }

  // Fired by Bali's sortable-list controller after a drop. Its per-item PATCH is
  // deliberately not wired up (the cards carry no `data-sortable-update-url`):
  // it posts 1-based positions for one item where we write a 0-based whole
  // sequence. The whole sequence is one write.
  reordered () {
    this.persist()
  }

  remove (event) {
    const card = event.target.closest('[data-widget-key]')
    if (!card) return

    const label = card.dataset.widgetTitle
    // Focus has to be placed BEFORE the card leaves, or it falls to `<body>` and
    // a keyboard user loses their place in a twelve-card grid. Deleting is the
    // gesture where losing your place costs most.
    const cards = this.cards
    const next = cards[cards.indexOf(card) + 1] ?? cards[cards.indexOf(card) - 1]

    card.remove()
    this.focusHandle(next)
    // `cards` was read before the removal, so it still counts the card that just
    // left — the new total is one less.
    this.announce(this.removalText(label, cards.length - 1))
    this.persist()
  }

  // `move` announces "position 3 of 9"; removing used to announce only the
  // widget name. That is where a running count matters MOST: a screen-reader
  // user emptying a dashboard has no grid to glance at, so without this they
  // learn how many are left only by counting them again.
  //
  // Three strings rather than one with a count interpolated into it, because
  // Spanish does not share a verb across them — "queda 1 widget" against
  // "quedan 3 widgets" — and the component resolves i18n at `initialize`, where
  // the count cannot be known.
  removalText (label, remaining) {
    if (remaining === 0) return this.removedLastTextValue.replace('%{widget}', label)

    const template = remaining === 1 ? this.removedOneTextValue : this.removedOtherTextValue

    return template.replace('%{widget}', label).replace('%{total}', remaining)
  }

  // The size is swapped locally first so the card resizes under the cursor. The
  // server is being told, not asked — and told the same thing every other
  // gesture tells it, since the card carries its size into the payload.
  resize (event) {
    const button = event.target.closest('[data-widget-size]')
    const card = button?.closest('[data-widget-key]')
    if (!card) return

    const size = button.dataset.widgetSize
    if (size === this.currentSize(card)) return

    this.applySize(card, size)
    // The interior is SERVER-rendered — `applySize` writes one attribute and the
    // regions inside the card do not move. Growing a charted `medium` to `large`
    // would otherwise keep an axis-less sparkline and no breakdown; growing a
    // hero card would leave one number in a 2x2 cell. So the write says which
    // card changed shape, and a host that answers with a turbo-stream gets the
    // right card back. A host that keeps answering 204 is unaffected.
    this.resizedKey = card.dataset.widgetKey
    this.announce(
      this.resizedTextValue
        .replace('%{widget}', card.dataset.widgetTitle)
        .replace('%{size}', button.getAttribute('aria-label'))
    )

    this.persist()
  }

  currentSize (card) {
    return card.querySelector('[data-widget-size][aria-checked="true"]')?.dataset.widgetSize
  }

  // The size picker is a radiogroup, so the whole set is ONE tab stop and the
  // arrows move within it. Selection FOLLOWS FOCUS, per the APG pattern — and
  // here that is a feature rather than a concession: the card resizes live as
  // you arrow across the sizes, which is the same preview the mouse gets, and
  // `persist`'s debounce collapses the whole sweep into one write.
  //
  // Bound on the group rather than each button because "next" is only knowable
  // from the whole set. No conflict with `move`: that listens on `.handle`,
  // which is a different element, so an arrow key is either moving the card or
  // choosing a size and never both.
  sizeKeydown (event) {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[event.key]
    const edge = { Home: 'first', End: 'last' }[event.key]
    if (!step && !edge) return

    const buttons = Array.from(event.currentTarget.querySelectorAll('[data-widget-size]'))
    const from = buttons.indexOf(event.target.closest('[data-widget-size]'))
    if (from === -1) return

    // Otherwise the arrows scroll the page out from under the card being sized.
    event.preventDefault()

    // Wrapping, which the radiogroup pattern calls for: four sizes is a short
    // ring, and stopping dead at `wide` makes `small` feel unreachable from it.
    const to = edge
      ? (edge === 'first' ? 0 : buttons.length - 1)
      : (from + step + buttons.length) % buttons.length

    // `click`, not a direct `applySize`: `resize` already owns applying a size,
    // announcing it and queueing the write, and one path means the keyboard and
    // the mouse cannot drift apart.
    buttons[to].focus()
    buttons[to].click()
  }

  // ONE attribute for the geometry: the stylesheet owns what each size MEANS at
  // each breakpoint, so nothing here builds a class name — which is also why it
  // no longer matters that Tailwind cannot see class names built at runtime.
  //
  // And ONE attribute for the selection: every visual consequence is expressed
  // by `aria-checked:` and `group-aria-checked:` variants in the card template,
  // so there is no class list for the server and the client to disagree about,
  // and the accessible state and the visible state cannot drift.
  applySize (card, size) {
    card.dataset.size = size

    card.querySelectorAll('[data-widget-size]').forEach(button => {
      const chosen = button.dataset.widgetSize === size
      button.setAttribute('aria-checked', String(chosen))
      // The roving half of the roving tabindex: the group keeps exactly one tab
      // stop and the checked size is it, so tabbing out and back returns to the
      // size actually in force rather than to whichever button was first.
      button.tabIndex = chosen ? 0 : -1
    })
  }

  // No fallback when there is no card left: the grid is empty, which means the
  // sequence just sent was empty, which means `writeSequence` is about to reload
  // for the restored defaults.
  focusHandle (card) {
    card?.querySelector('.handle')?.focus()
  }

  // Bali's SortableList grew keyboard reordering, but it only acts on focused
  // `:scope > .sortable-item` children — which these cards deliberately are not,
  // because `SortableList::Item::Component` carries list-row styling that fights
  // the bento. So this is the entire keyboard path.
  //
  // All four arrow keys map to the same ±1: "earlier or later in DOM order",
  // not "up/down/left/right in the 2-D layout" — this controller has no notion
  // of grid geometry, columns, or rows. That is a deliberate simplification,
  // not a gap: true spatial movement is ill-defined the moment a 2x2 `large`
  // tile sits beside two 1x1 tiles, so there is no single "the cell above" to
  // move into. DOM order is the one answer that stays well-defined for every
  // mix of sizes, and it is what `writeSequence` persists regardless.
  move (event) {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[event.key]
    if (!step) return

    const card = event.target.closest('[data-widget-key]')
    const cards = this.cards
    const from = cards.indexOf(card)
    const to = from + step
    if (from === -1 || to < 0 || to >= cards.length) return

    event.preventDefault()
    if (step > 0) cards[to].after(card)
    else cards[to].before(card)

    // Focus follows the card, not the index — the DOM move blurs the button.
    this.focusHandle(card)
    this.announce(
      this.movedTextValue
        .replace('%{widget}', card.dataset.widgetTitle)
        .replace('%{position}', to + 1)
        .replace('%{total}', cards.length)
    )
    this.persist()
  }

  get cards () {
    return Array.from(this.gridTarget.querySelectorAll('[data-widget-key]'))
  }

  // Clearing first, exactly as `kanban` does: writing the same string twice is not
  // a DOM change, and a live region only announces changes — so arrowing a card
  // back to a position it already announced would go silent.
  announce (message) {
    if (!this.hasAnnouncerTarget || !message) return

    this.announcerTarget.textContent = ''
    window.requestAnimationFrame(() => {
      this.announcerTarget.textContent = message
    })
  }

  // Debounced AND serialized, for two different failures.
  //
  // Debounced because arrow keys auto-repeat: holding one fires a gesture every
  // few milliseconds, and each would otherwise be a full PATCH. The trailing
  // edge collapses a held key into the one write that describes where the card
  // came to rest.
  //
  // Serialized because every gesture sends a full snapshot, so two in-flight
  // requests are two complete and DIFFERENT answers to "what is the
  // arrangement", and nothing about HTTP guarantees the later one commits last.
  // Drag a card, immediately remove another, and the stale snapshot can win —
  // resurrecting the widget you just deleted.
  //
  // The snapshot is read when the request is BUILT, not when it is queued, so a
  // queued write still sends the latest DOM.
  persist () {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.enqueue(() => this.writeSequence()), 250)
  }

  // The `.catch` is the whole reason this is safe, and it has to come AFTER
  // `.then(write)`: a handler passed as `.then(write, onRejected)` only catches a
  // rejection of the INCOMING queue, never one produced by `write` itself.
  //
  // Without it, one rejected write poisons `this.queue` permanently — every later
  // `.then(write)` skips its callback and re-propagates, so the grid stops saving
  // for the life of the page, silently. Nothing rejects today (`send` try/catches
  // and always resolves a boolean), but that is an invariant held in another
  // method, and `this.cards` throwing on a missing `gridTarget` would land here as
  // a rejection. Announcing rather than swallowing keeps the design's promise that
  // a failure is never silent.
  enqueue (write) {
    this.queue = Promise.resolve(this.queue)
      .then(write)
      .catch(error => {
        console.error(error)
        this.announce(this.failedTextValue)
      })
    return this.queue
  }

  // The whole layout, read out of the DOM: order from the card order, size from
  // whichever glyph is pressed. Submitting the order on a resize is not an
  // overreach — this IS the order, and the server has no better source for it.
  async writeSequence () {
    const body = new FormData()
    this.cards.forEach(card => {
      body.append('widgets[][key]', card.dataset.widgetKey)
      body.append('widgets[][size]', this.currentSize(card) ?? '')
    })

    // Consumed here rather than in `resize`, because the debounce collapses a
    // sweep across the size picker into one write and only the size it came to
    // rest on needs re-rendering.
    const resized = this.resizedKey
    this.resizedKey = null
    if (resized) body.append('resized_key', resized)

    // A keyboard resize has focus inside the card that is about to be replaced.
    const refocus = document.activeElement?.dataset.widgetSize

    if (!await this.send(this.urlValue, body)) return

    if (resized) this.restoreFocus(resized, refocus)

    // Removing the LAST widget sends an empty sequence, and no rows means "never
    // chose" — so the server answers by restoring every authorized widget. The
    // `204` contract means nothing comes back to render, which would leave an
    // empty grid on screen over a full dashboard in the database, wrong until
    // the next reload. This is the one gesture that has to go back for markup.
    if (this.cards.length === 0) this.reload()
  }

  // Failures are announced, never swallowed. The whole design rests on the DOM
  // being truthful — no draft, no save button — so the one moment it stops being
  // truthful is the one moment the user has to be told.
  async send (url, body) {
    try {
      // `turbo-stream` in the Accept header, not a demand: the contract is still
      // "any 2xx means saved". A host answering `head :no_content` behaves
      // exactly as before; one answering with a stream gets it rendered, which
      // is how a resized card's server-rendered interior catches up with its new
      // shape.
      const response = await patch(url, { body, responseKind: 'turbo-stream' })
      if (!response.ok) this.announce(this.failedTextValue)
      else await this.renderStream(response)

      return response.ok
    } catch {
      this.announce(this.failedTextValue)

      return false
    }
  }

  // Its own method so a test can observe it, and guarded because 204 is still
  // the common answer: `text` on an empty body is "" and rendering that is a
  // no-op, but asking Turbo to parse nothing is noise either way.
  async renderStream (response) {
    if (!window.Turbo) return

    const body = await response.text
    if (body?.includes('<turbo-stream')) window.Turbo.renderStreamMessage(body)
  }

  // A keyboard resize leaves focus on a size button inside the card the stream
  // just replaced, and a replaced element takes its focus with it — the user
  // lands on `<body>` mid-edit. Puts them back on the same size in the new card.
  restoreFocus (key, size) {
    if (!size) return

    const card = this.gridTarget.querySelector(`[data-widget-key="${key}"]`)
    card?.querySelector(`[data-widget-size="${size}"]`)?.focus()
  }

  // Its own method so a test can observe and stub it.
  //
  // `isConnected` because the response can land after a Turbo navigation: remove
  // the last card, navigate away inside the round trip, and an unguarded reload
  // reloads whatever page the user is on NOW, not the grid they left.
  reload () {
    if (this.element.isConnected) window.location.reload()
  }
}
