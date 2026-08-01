import { Controller } from '@hotwired/stimulus'

const MAX_CARD_LABEL_LENGTH = 60

export class KanbanController extends Controller {
  static targets = ['liveRegion']
  static values = { announcement: String }

  // Fires on `sortable-list:onEnd`, which bubbles up from each column's
  // SortableList. A drop moves the DOM and nothing else: focus stays put and no
  // text changes, so this is the only thing a screen reader has to go on.
  announce ({ detail }) {
    if (!this.hasLiveRegionTarget || !detail?.item || !detail?.to) return

    const { item, to, newIndex } = detail
    const message = this.announcementValue
      .replace('%{card}', this.cardLabel(item))
      .replace('%{column}', to.dataset.kanbanColumnTitle || '')
      .replace('%{position}', newIndex + 1)
      .replace('%{total}', to.children.length)

    // Writing the same string twice is not a change, and a live region only
    // announces changes — dropping a card back where it came from would go
    // silent. Clearing first makes every drop a change.
    this.liveRegionTarget.textContent = ''
    window.requestAnimationFrame(() => {
      this.liveRegionTarget.textContent = message
    })
  }

  cardLabel (item) {
    if (item.dataset.kanbanCardLabel) return item.dataset.kanbanCardLabel

    const text = item.textContent.replace(/\s+/g, ' ').trim()
    return text.length > MAX_CARD_LABEL_LENGTH
      ? `${text.slice(0, MAX_CARD_LABEL_LENGTH)}…`
      : text
  }
}
