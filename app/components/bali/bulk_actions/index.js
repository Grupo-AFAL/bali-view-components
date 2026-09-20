import { Controller } from '@hotwired/stimulus'
import { toInt } from '../../../assets/javascripts/bali/utils/formatters.js'

const IGNORED_TAG_NAMES = ['select', 'input']
const SELECTED_CLASS = 'selected'

export class BulkActionsController extends Controller {
  static targets = [
    'item',
    'bulkAction',
    'actionsContainer',
    'announcement',
    'selectedCount',
    'selectedLabelOne',
    'selectedLabelOther',
    'selectAll',
    'toolbar',
    'selectAllOffer',
    'selectAllNotice',
    'selectAllFilteredField'
  ]

  static values = {
    selectedIds: { type: Array, default: [] },
    // Runtime state, not server state: it always starts off. N does come from the server,
    // but in a data attribute on the offer node itself and not as a value, because inside a
    // DataTable the controller lives on the table container — a value would have to be
    // emitted from two different components and they could disagree.
    selectAllFiltered: { type: Boolean, default: false }
  }

  connect () {
    // The DOM wins: after a Turbo cache restore the rows come back with their `selected`
    // class set but the controller's value starts empty. Deriving it from the DOM keeps the
    // counter and the actions from drifting out of sync with what is on screen.
    this.syncSelectedIds()

    this.element.addEventListener('dblclick', this.handleDoubleClick)
  }

  disconnect () {
    this.element.removeEventListener('dblclick', this.handleDoubleClick)
  }

  handleDoubleClick = (event) => {
    if (IGNORED_TAG_NAMES.includes(event.target.tagName.toLowerCase())) return

    const item = event.target.closest('[data-bulk-actions-target="item"]')

    if (item) { this.toggle(item) }
  }

  toggle = (eventOrItem) => {
    const item = eventOrItem.currentTarget || eventOrItem
    if (!item.dataset.recordId) return

    this.setSelected(item, !item.classList.contains(SELECTED_CLASS))
    this.syncSelectedIds()
  }

  // The row's checkbox is not the item: walk up to the `<tr>`, which carries the record id.
  toggleItem = (event) => {
    const item = event.target.closest('[data-bulk-actions-target="item"]')

    if (item) this.toggle(item)
  }

  // A `selectAll` carrying `data-bulk-actions-group` only reaches the rows that declare that
  // id; without the attribute it reaches every row, which is the plain select-all. That way N
  // listings fit under ONE controller — one counter, one bar — with no nested instances, which
  // Stimulus would split by nearest ancestor, leaving the bar with no rows.
  toggleAll = (event) => {
    const items = this.itemsInGroup(event.target.dataset.bulkActionsGroup)

    items.forEach(item => this.setSelected(item, event.target.checked))
    this.syncSelectedIds()
  }

  clear = () => {
    // The ✕ lives INSIDE the bar it hides: unless focus is moved out first, the browser
    // drops it on <body> and the keyboard user loses their place. It is read BEFORE
    // syncing, because by then the bar is already display:none.
    const focusWasInBar = this.hasActionsContainerTarget &&
      this.actionsContainerTarget.contains(document.activeElement)

    this.selectableItems.forEach(item => this.setSelected(item, false))
    this.syncSelectedIds()

    if (focusWasInBar) this.focusAfterClear()
  }

  // The destination equivalent to the ✕: the select-all, the selection control left standing;
  // if the table does not have one, the first control of the just-restored toolbar.
  focusAfterClear = () => {
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.focus({ preventScroll: true })
      return
    }

    if (!this.hasToolbarTarget) return

    this.toolbarTarget
      .querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      ?.focus({ preventScroll: true })
  }

  setSelected = (item, selected) => {
    item.classList.toggle(SELECTED_CLASS, selected)

    const checkbox = item.querySelector('input[type="checkbox"]')
    if (checkbox) checkbox.checked = selected
  }

  // Leaves select-all-filtered mode as soon as the selection stops covering the whole page —
  // the Gmail move: unchecking a row takes you back to page selection instead of locking you
  // into a state only the ✕ can leave. That is why the checkboxes are NOT disabled while the
  // mode is on.
  selectAllFiltered = () => {
    if (this.totalCount <= 0) return

    this.selectAllFilteredValue = true
    this.update()
  }

  // Derived, never incremental: select-all and clear move many rows at once, and an
  // incremental counter would fill up with duplicates or with phantom ids.
  syncSelectedIds = () => {
    this.selectedIdsValue = this.selectableItems
      .filter(item => item.classList.contains(SELECTED_CLASS))
      .map(item => toInt(item.dataset.recordId))

    if (this.selectAllFilteredValue && !this.pageFullySelected) {
      this.selectAllFilteredValue = false
    }

    this.update()
  }

  get selectableItems () {
    return this.itemTargets.filter(item => item.dataset.recordId)
  }

  // A row's group ids are a space-separated LIST, like classes: a row can be in its table's
  // group and in its sub-header's group at the same time, and each select-all sees its own.
  // With no group, the universe is the whole selection.
  itemsInGroup = (group) => {
    if (!group) return this.selectableItems

    return this.selectableItems.filter(item => this.groupsOf(item).includes(group))
  }

  groupsOf = (item) => (item.dataset.bulkActionsGroup || '').split(/\s+/).filter(Boolean)

  get pageFullySelected () {
    const total = this.selectableItems.length

    return total > 0 && this.selectedIdsValue.length === total
  }

  // How many records the whole filtered result has. The server paints it on the offer node;
  // with no offer there is no mode, and the mode cannot be turned on.
  get totalCount () {
    if (!this.hasSelectAllOfferTarget) return 0

    return toInt(this.selectAllOfferTarget.dataset.totalCount)
  }

  get selectionCount () {
    return this.selectAllFilteredValue ? this.totalCount : this.selectedIdsValue.length
  }

  update = () => {
    this.updateBulkActionsSelectedIds()
    this.updateSelectAllFilteredFields()
    this.updateActionsContainer()
    this.updateSelectedCount()
    this.updateSelectAll()
    this.updateSelectAllFilteredBar()
    this.updateToolbar()
    this.announceSelection()
    this.notifySelectionChange()
  }

  // One event, emitted here and not at the end of `syncSelectedIds`, because `update` is the
  // only point ALL the paths go through — including `selectAllFiltered`, which touches no ids.
  // A consumer hooked to each checkbox's `change` misses the ones that write
  // `checkbox.checked` by assignment (double click, the ✕, select-all-filtered): assigning the
  // property does not fire the native event. With this one, the consumer declares itself in
  // the HTML:
  //
  //   data-action="bulk-actions:change@window->my-controller#sync"
  notifySelectionChange = () => {
    this.dispatch('change', {
      detail: {
        selectedIds: this.selectedIdsValue,
        selectAllFiltered: this.selectAllFilteredValue,
        count: this.selectionCount
      }
    })
  }

  // In select-all-filtered mode the ids are emptied on purpose: the server re-derives the
  // scope from the `q[...]` travelling in the same POST, so a list of ids from the visible
  // page could only contradict it.
  updateBulkActionsSelectedIds = () => {
    const ids = JSON.stringify(this.selectAllFilteredValue ? [] : this.selectedIdsValue)

    this.bulkActionTargets.forEach(action => {
      if (action.tagName.toLowerCase() === 'a') {
        const url = new URL(action.href)
        url.searchParams.set('selected_ids', ids)
        if (this.hasSelectAllOfferTarget) {
          url.searchParams.set('select_all_filtered', String(this.selectAllFilteredValue))
        }

        action.href = url.href
      } else {
        action.value = ids
      }
    })
  }

  updateSelectAllFilteredFields = () => {
    this.selectAllFilteredFieldTargets.forEach(field => {
      field.value = String(this.selectAllFilteredValue)
    })
  }

  // The offer only makes sense when the whole page is selected and there are more results
  // behind it; the notice replaces it while the mode is on.
  updateSelectAllFilteredBar = () => {
    if (!this.hasSelectAllOfferTarget) return

    const offered = !this.selectAllFilteredValue && this.pageFullySelected &&
      this.totalCount > this.selectableItems.length

    this.selectAllOfferTarget.classList.toggle('hidden', !offered)

    if (this.hasSelectAllNoticeTarget) {
      this.selectAllNoticeTarget.classList.toggle('hidden', !this.selectAllFilteredValue)
    }
  }

  updateActionsContainer = () => {
    if (!this.hasActionsContainerTarget) return

    if (this.selectionCount > 0) {
      this.actionsContainerTarget.classList.remove('hidden')
    } else {
      this.actionsContainerTarget.classList.add('hidden')
    }
  }

  updateSelectedCount = () => {
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.innerText = this.selectionCount
    }

    if (!this.hasSelectedLabelOneTarget || !this.hasSelectedLabelOtherTarget) return

    // The plural comes from the server in two nodes: here we only pick which one shows, so
    // there is no i18n to interpolate in JS.
    const one = this.selectionCount === 1
    this.selectedLabelOneTarget.classList.toggle('hidden', !one)
    this.selectedLabelOtherTarget.classList.toggle('hidden', one)
  }

  // Every select-all, each against ITS OWN universe: the table header's against its rows, a
  // group header's against that group's rows. Counted over the class and not over
  // `selectedIdsValue`, which is the whole selection and knows nothing about groups.
  updateSelectAll = () => {
    this.selectAllTargets.forEach(checkbox => {
      const items = this.itemsInGroup(checkbox.dataset.bulkActionsGroup)
      const selected = items.filter(item => item.classList.contains(SELECTED_CLASS)).length

      checkbox.checked = items.length > 0 && selected === items.length
      checkbox.indeterminate = selected > 0 && selected < items.length
    })
  }

  // A selection change does not move focus, so without announcing it a screen reader user
  // checks N rows with no confirmation at all that the selection exists.
  announceSelection = () => {
    if (!this.hasAnnouncementTarget) return

    const count = this.selectionCount
    if (count === 0) {
      this.announcementTarget.textContent = ''
      return
    }

    // Entering select-all-filtered mode is a change of MODE, not one more count. Announcing
    // only the number, the screen reader went from "5 selected" to "1248 selected" with
    // nothing saying that the selection is no longer the page being looked at. The full
    // sentence comes from the server in the notice, so it is reused instead of built in JS.
    if (this.selectAllFilteredValue && this.hasSelectAllNoticeTarget) {
      this.announcementTarget.textContent = this.selectAllNoticeTarget.textContent.trim()
      return
    }

    const { selectedOne, selectedOther } = this.announcementTarget.dataset
    this.announcementTarget.textContent = `${count} ${count === 1 ? selectedOne : selectedOther}`.trim()
  }

  // The contextual row REPLACES the toolbar: same slot, never both at once.
  updateToolbar = () => {
    if (!this.hasToolbarTarget) return

    this.toolbarTarget.classList.toggle('hidden', this.selectionCount > 0)
  }
}
