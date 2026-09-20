import { Controller } from '@hotwired/stimulus'

// Folds and unfolds the rows of each group of a `Bali::Table(collapsible_groups: true)`.
//
// The state lives in the DOM and not in the controller: each band's button carries
// `aria-expanded` and the group's rows carry the `hidden` attribute. That way a Turbo cache
// restore preserves it, and without JS nothing is hidden: the server never emits `hidden`,
// not even for the groups born folded — this controller folds them on connect, reading the
// `aria-expanded="false"` its button was rendered with.
//
// A group value that reappears further down is THE SAME group (same token, as in the
// selection): folding one of its bands folds both runs and syncs both buttons.
export class TableGroupsController extends Controller {
  static targets = ['trigger', 'row']

  // Covers the initial load and the rows that arrive later —a Turbo Stream replacing the
  // run—, so that they show up folded if their group is.
  rowTargetConnected (row) {
    const trigger = this.triggerFor(row.dataset.groupToken)

    if (trigger) row.hidden = !this.isExpanded(trigger)
  }

  toggle (event) {
    const token = event.currentTarget.dataset.groupToken
    const expanded = !this.isExpanded(event.currentTarget)

    this.triggersFor(token).forEach(trigger => trigger.setAttribute('aria-expanded', expanded))
    this.rowsFor(token).forEach(row => { row.hidden = !expanded })
  }

  isExpanded (trigger) {
    return trigger.getAttribute('aria-expanded') !== 'false'
  }

  triggerFor (token) {
    return this.triggersFor(token)[0]
  }

  triggersFor (token) {
    return this.triggerTargets.filter(trigger => trigger.dataset.groupToken === token)
  }

  rowsFor (token) {
    return this.rowTargets.filter(row => row.dataset.groupToken === token)
  }
}
