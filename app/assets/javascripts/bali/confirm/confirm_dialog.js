/**
 * Bali custom confirmation dialog
 *
 * Replaces Turbo's default window.confirm with a DaisyUI-styled native <dialog>.
 * It renders as real DOM in the top layer, so automated browser tools (e.g. Claude
 * in Chrome) can operate it — unlike the native window.confirm modal.
 *
 * Wired into Turbo via: Turbo.config.forms.confirm = confirmDialog
 *
 * Per-trigger customization via data-attributes on the submitter or form:
 *   data-bali-confirm-title, data-bali-confirm-variant (danger|warning|info),
 *   data-bali-confirm-accept, data-bali-confirm-cancel
 */

const VARIANT_CLASSES = {
  danger: 'btn-error',
  warning: 'btn-warning',
  info: 'btn-info'
}

const DEFAULT_ACCEPT_CLASS = 'btn-primary'

// Fallback button labels for the bare `data-turbo-confirm` case (no per-trigger
// labels). DeleteLink always supplies localized labels. Apps that use bare
// `data-turbo-confirm` in a non-English locale should localize these once via
// installConfirmDialog({ acceptText, cancelText }).
const labels = {
  accept: 'OK',
  cancel: 'Cancel'
}

let dialog = null
let boxEl = null
let titleEl = null
let messageEl = null
let acceptBtn = null
let cancelBtn = null
let activeResolve = null
let confirmed = false
let previouslyFocused = null
let installed = false

function buildDialog () {
  dialog = document.createElement('dialog')
  dialog.className = 'modal'
  dialog.dataset.baliConfirm = ''
  dialog.innerHTML = `
    <div class="modal-box" role="alertdialog" aria-describedby="bali-confirm-message">
      <h3 id="bali-confirm-title" class="text-lg font-bold"></h3>
      <p id="bali-confirm-message" class="py-4"></p>
      <div class="modal-action">
        <button type="button" class="btn btn-ghost" id="bali-confirm-cancel-btn"></button>
        <button type="button" class="btn" id="bali-confirm-accept-btn"></button>
      </div>
    </div>
    <form method="dialog" class="modal-backdrop">
      <button tabindex="-1" aria-hidden="true">close</button>
    </form>
  `

  boxEl = dialog.querySelector('.modal-box')
  titleEl = dialog.querySelector('#bali-confirm-title')
  messageEl = dialog.querySelector('#bali-confirm-message')
  cancelBtn = dialog.querySelector('#bali-confirm-cancel-btn')
  acceptBtn = dialog.querySelector('#bali-confirm-accept-btn')

  acceptBtn.addEventListener('click', () => {
    confirmed = true
    dialog.close()
  })

  cancelBtn.addEventListener('click', () => {
    confirmed = false
    dialog.close()
  })

  // The close event fires for button clicks, ESC, and backdrop submit.
  dialog.addEventListener('close', () => {
    const resolve = activeResolve
    activeResolve = null
    if (previouslyFocused && previouslyFocused.focus) previouslyFocused.focus()
    previouslyFocused = null
    if (resolve) resolve(confirmed)
  })

  document.body.appendChild(dialog)
}

function dataValue (submitter, formElement, key) {
  if (submitter && submitter.dataset[key]) return submitter.dataset[key]
  if (formElement && formElement.dataset[key]) return formElement.dataset[key]
  return null
}

export function confirmDialog (message, formElement, submitter) {
  // Only one confirm at a time — bail rather than orphan the pending promise.
  if (activeResolve) return Promise.resolve(false)
  // Rebuild if missing OR detached (Turbo Drive replaces document.body on full visits).
  if (!dialog || !dialog.isConnected) buildDialog()

  const title = dataValue(submitter, formElement, 'baliConfirmTitle')
  const variant = dataValue(submitter, formElement, 'baliConfirmVariant')

  titleEl.textContent = title || ''
  titleEl.hidden = !title

  // Label the dialog by its title when present; otherwise by the message text.
  if (title) {
    boxEl.setAttribute('aria-labelledby', 'bali-confirm-title')
    boxEl.removeAttribute('aria-label')
  } else {
    boxEl.removeAttribute('aria-labelledby')
    boxEl.setAttribute('aria-label', message || '')
  }

  messageEl.textContent = message || ''

  acceptBtn.textContent = dataValue(submitter, formElement, 'baliConfirmAccept') || labels.accept
  cancelBtn.textContent = dataValue(submitter, formElement, 'baliConfirmCancel') || labels.cancel

  acceptBtn.className = 'btn'
  acceptBtn.classList.add(VARIANT_CLASSES[variant] || DEFAULT_ACCEPT_CLASS)

  confirmed = false
  previouslyFocused = document.activeElement

  return new Promise(resolve => {
    activeResolve = resolve
    dialog.showModal()
    cancelBtn.focus()
  })
}

export function installConfirmDialog (options = {}) {
  if (options.acceptText) labels.accept = options.acceptText
  if (options.cancelText) labels.cancel = options.cancelText

  if (typeof window === 'undefined' || window.BALI_DISABLE_CONFIRM_DIALOG) return
  if (installed) return
  installed = true

  const apply = () => {
    if (window.Turbo && window.Turbo.config && window.Turbo.config.forms) {
      window.Turbo.config.forms.confirm = confirmDialog
      return true
    }
    return false
  }

  if (!apply()) {
    const onLoad = () => {
      document.removeEventListener('turbo:load', onLoad)
      apply()
    }
    document.addEventListener('turbo:load', onLoad)
  }
}
