import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'

// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event name stays put when a host registers this controller under a
// different identifier.
const EVENT_PREFIX = 'bali:sortable-list'

export class SortableListController extends Controller {
  static values = {
    resourceName: String,
    positionParamName: { type: String, default: 'position' },
    listParamName: { type: String, default: 'list_id' },
    responseKind: { type: String, default: 'html' },
    animation: { type: Number, default: 150 },
    handle: String,
    groupName: String,
    pull: { type: Boolean, default: true },
    disabled: { type: Boolean, default: false }
  }

  async connect () {
    this.setupKeyboardReordering()

    const { default: Sortable } = await import('sortablejs')

    this.sortable = new Sortable(this.element, {
      group: { name: this.groupNameValue, pull: this.pullValue },
      animation: this.animationValue,
      handle: this.handleValue || undefined,
      fallbackOnBody: true,
      swapThreshold: 0.65,
      disabled: this.disabledValue,
      onEnd: this.onEnd,
      onMove: this.onMove
    })
  }

  disconnect () {
    this.element.removeEventListener('keydown', this.onKeydown)
  }

  // Keyboard alternative to the drag (#1028, WCAG 2.1.1): each direct item
  // becomes focusable, and ArrowUp/ArrowDown moves the focused item one slot —
  // persisting and dispatching exactly like a drop. Arrows only act when the
  // ITEM ELEMENT itself has focus, so nested inputs and selects keep their own
  // arrow behaviour. Cross-list moves stay mouse-only for now.
  setupKeyboardReordering () {
    if (this.disabledValue) return

    this.element.querySelectorAll(':scope > .sortable-item').forEach((item) => {
      if (!item.hasAttribute('tabindex')) item.setAttribute('tabindex', '0')
    })
    this.element.addEventListener('keydown', this.onKeydown)
  }

  onKeydown = (event) => {
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return

    const item = event.target
    if (!item.classList || !item.classList.contains('sortable-item')) return
    if (item.parentElement !== this.element) return

    const up = event.key === 'ArrowUp'
    const sibling = up ? item.previousElementSibling : item.nextElementSibling
    if (!sibling || !sibling.classList.contains('sortable-item')) return

    event.preventDefault()

    const itemsBefore = this.items()
    const oldIndex = itemsBefore.indexOf(item)
    if (up) {
      this.element.insertBefore(item, sibling)
    } else {
      this.element.insertBefore(sibling, item)
    }
    item.focus()

    this.onEnd({
      item,
      from: this.element,
      to: this.element,
      oldIndex,
      newIndex: this.items().indexOf(item)
    })
  }

  items () {
    return Array.from(this.element.querySelectorAll(':scope > .sortable-item'))
  }

  onEnd = async ({ item, from, to, oldIndex, newIndex }) => {
    const positionParam = this.resourceNameValue
      ? `${this.resourceNameValue}[${this.positionParamNameValue}]`
      : this.positionParamNameValue

    const listIdParam = this.resourceNameValue
      ? `${this.resourceNameValue}[${this.listParamNameValue}]`
      : this.listParamNameValue

    const toListId = to.dataset.sortableListListIdValue || ''

    const data = new FormData()
    data.append(positionParam, newIndex + 1)
    data.append(listIdParam, toListId)

    this.dispatch('end', {
      prefix: EVENT_PREFIX,
      // `order` is the *source* list: SortableJS fires onEnd on the instance the
      // item left, so a listener that needs the destination has to read `to`.
      // That is why the moved element and both lists travel with the event.
      // `?.` guards the keyboard path racing SortableJS's async import.
      detail: { order: this.sortable?.toArray() ?? [], toListId, item, from, to, oldIndex, newIndex }
    })

    if (!item.dataset.sortableUpdateUrl) return

    await patch(item.dataset.sortableUpdateUrl, {
      body: data,
      responseKind: this.responseKindValue
    })
  }

  onMove = (event, _originalEvent) => {
    const itemPullDisabled = event.dragged.dataset.sortableItemPull === 'false'

    if (itemPullDisabled && this.itemChangedSortableList(event)) {
      return false
    }
  }

  itemChangedSortableList = event => {
    return (
      event.to.dataset.sortableListListIdValue !==
      event.from.dataset.sortableListListIdValue
    )
  }
}
