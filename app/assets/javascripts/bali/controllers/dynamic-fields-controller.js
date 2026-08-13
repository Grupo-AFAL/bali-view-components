import { Controller } from '@hotwired/stimulus'
import { getTimestamp } from '../utils/time.js'
import {
  replaceInFragment,
  removeNonHiddenFormElements,
  previousSibling,
  nextSibling
} from '../utils/domHelpers.js'

// Contract frozen by cypress/e2e/dynamic-fields-controller.cy.js (#155/#715).

export class DynamicFieldsController extends Controller {
  static targets = ['template', 'container', 'button', 'ordinal']
  static values = {
    size: Number,
    fieldsSelector: String,
    removeDuplicates: { type: Boolean, default: false }
  }

  connect () {
    if (this.isAtMaximumSize()) {
      this.buttonTarget.setAttribute('disabled', true)
    }
  }

  addFields (e) {
    e.preventDefault()
    if (this.isAtMaximumSize()) return false

    this.sizeValue += 1

    const template = this.removeDuplicatesValue
      ? this.templateFragmentWithoutDuplicates()
      : this.templateFragment()

    this.containerTarget.appendChild(template)
    this.renumber()

    if (this.isAtMaximumSize()) {
      this.buttonTarget.setAttribute('disabled', true)
    }
  }

  // A row the user never saved has nothing to destroy server-side, so it leaves
  // the DOM outright; only a persisted one is hidden and flagged, because the
  // server needs its id back to know what to delete.
  removeFields (e) {
    e.preventDefault()
    this.sizeValue -= 1

    const fieldsContainer = e.target.closest(this.fieldsSelectorValue)

    const idInput = this.idInputFor(fieldsContainer)

    if (idInput && idInput.value !== '') {
      fieldsContainer.style.display = 'none'
      removeNonHiddenFormElements(fieldsContainer)

      const destroyFlag = fieldsContainer.querySelector('.destroy-flag')
      if (destroyFlag) destroyFlag.value = true
    } else {
      // A blank id would submit as a new, empty record once the row it belongs
      // to is gone.
      if (idInput && !fieldsContainer.contains(idInput)) idInput.remove()
      fieldsContainer.remove()
    }

    this.renumber()

    if (this.hasButtonTarget && this.buttonTarget.hasAttribute('disabled')) {
      this.buttonTarget.removeAttribute('disabled')
    }
  }

  // A record the server already knows about carries its primary key in a hidden
  // input, and Rails emits that input only for a persisted record — so finding
  // one with a value is what separates "hide and flag for destruction" from
  // "drop the row".
  //
  // It is not necessarily inside the row: `fields_for` appends it *after* the
  // block it renders, so it lands as a sibling unless the partial emitted it
  // itself. What both placements share is the row's name prefix, so that is
  // what this matches on rather than a position in the DOM.
  idInputFor (fieldsContainer) {
    const inside = fieldsContainer.querySelector("input[name$='[id]']")
    if (inside) return inside

    const named = fieldsContainer.querySelector('[name]')
    if (!named) return null

    const prefix = named.getAttribute('name').replace(/\[[^[\]]*\]$/, '')
    // Array mode (`movie[steps][][role]`) has no per-row prefix to match on,
    // and no ids either.
    if (prefix === '' || prefix.endsWith('[]')) return null

    return this.element.querySelector(`input[name="${prefix}[id]"]`)
  }

  moveUp (e) {
    e.preventDefault()

    const fieldsContainer1 = e.target.closest(this.fieldsSelectorValue)
    const fieldsContainer2 = previousSibling(
      fieldsContainer1,
      this.fieldsSelectorValue
    )

    this.swapElements(fieldsContainer1, fieldsContainer2)
    this.renumber()
  }

  moveDown (e) {
    e.preventDefault()

    const fieldsContainer1 = e.target.closest(this.fieldsSelectorValue)
    const fieldsContainer2 = nextSibling(
      fieldsContainer1,
      this.fieldsSelectorValue
    )

    this.swapElements(fieldsContainer1, fieldsContainer2)
    this.renumber()
  }

  swapElements (elm1, elm2) {
    if (elm2 == null) return

    const parent = elm1.parentNode
    const next1 = elm1.nextElementSibling
    const next2 = elm2.nextElementSibling

    parent.insertBefore(elm2, next1)
    parent.insertBefore(elm1, next2)
  }

  // Both numberings count only the rows still in play: a row hidden by
  // removeFields is on its way to being destroyed, so leaving it in the count
  // would open a gap in the positions the server persists and skip a number in
  // the list the user reads.
  renumber () {
    this.resetPositionValues()
    this.resetOrdinals()
  }

  resetPositionValues () {
    this.liveRows().forEach((fields, index) => {
      const positionInput = fields.querySelector('[data-position]')
      if (positionInput) positionInput.value = index + 1
    })
  }

  // The target holds the number alone. Any punctuation around it ("1.", "#1")
  // belongs to the markup outside the target, so it survives renumbering.
  //
  // Queried straight off the row rather than through `ordinalTargets`: Stimulus
  // registers targets from a MutationObserver, so a row appended microseconds
  // ago is not in that list yet.
  resetOrdinals () {
    this.liveRows().forEach((fields, index) => {
      const ordinal = fields.querySelector(
        '[data-dynamic-fields-target~="ordinal"]'
      )
      if (ordinal) ordinal.textContent = index + 1
    })
  }

  liveRows () {
    return Array.from(
      this.element.querySelectorAll(this.fieldsSelectorValue)
    ).filter(row => row.style.display !== 'none')
  }

  templateFragment () {
    return replaceInFragment(this.templateTarget, /new_record/g, getTimestamp())
  }

  templateFragmentWithoutDuplicates () {
    // Get currently selected values
    const selectedValues = Array.from(
      this.element.querySelectorAll(`${this.fieldsSelectorValue} select`)
    ).map(node => node.value)

    // Remove already selected values
    const template = this.templateFragment()
    template.querySelectorAll('select option').forEach(option => {
      if (selectedValues.includes(option.value)) {
        option.remove()
      }
    })

    return template
  }

  dropdownOptionsSize () {
    return this.templateFragment().querySelectorAll('select option').length
  }

  // When removeDuplicatesValue is disabled user can potentially add as
  // unlimited number of dynamic fields
  isAtMaximumSize () {
    return (
      this.removeDuplicatesValue &&
      this.dropdownOptionsSize() === this.sizeValue
    )
  }
}
