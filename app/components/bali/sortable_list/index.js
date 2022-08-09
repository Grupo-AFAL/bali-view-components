import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import { patch } from '@rails/request.js'
import useDispatch from '../../../javascript/bali/utils/use-dispatch'

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

  connect () {
    useDispatch(this)

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

  onEnd = async ({ item, newIndex, to }) => {
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

    const order = this.sortable.toArray()
    this.dispatch('onEnd', { item, newIndex, to, toListId, order })

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
