/**
 * Bali custom confirmation dialog
 *
 * Replaces Turbo's default window.confirm with a DaisyUI-styled native <dialog>.
 * It renders as real DOM in the top layer, so automated browser tools (e.g. Claude
 * in Chrome) can operate it — unlike the native window.confirm modal.
 *
 * installConfirmDialog() wires it into Turbo (Turbo.config.forms.confirm) and remembers the
 * link clicked last, for a link with data-turbo-method (below).
 *
 * Per-trigger customization via data-attributes on the submitter, the form, or a link
 * with data-turbo-method:
 *   data-bali-confirm-title, data-bali-confirm-variant (danger|warning|info),
 *   data-bali-confirm-accept, data-bali-confirm-cancel
 */

import { inLanguageOf } from '../utils/language.js'

const VARIANT_CLASSES = {
  danger: 'btn-error',
  warning: 'btn-warning',
  info: 'btn-info'
}

const DEFAULT_ACCEPT_CLASS = 'btn-primary'

// A button the trigger gives no `data-bali-confirm-accept`/`-cancel` shows the label passed to
// installConfirmDialog({ acceptText, cancelText }), in any language, or else LABELS in the
// dialog's language. That is read when the dialog opens, since a Turbo visit can change
// `<html lang>`, and off the dialog rather than the trigger, which Modal leaves out and a caller
// may pass as a plain `{ dataset }`.
const LABELS = {
  en: { accept: 'OK', cancel: 'Cancel' },
  es: { accept: 'Aceptar', cancel: 'Cancelar' }
}
const installedLabels = {}

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

// Turbo submits a link with `data-turbo-method` or `data-turbo-stream` through a <form> it
// builds, which copies no `data-bali-confirm-*`, and asks for the confirm with no submitter
// (FormLinkClickObserver in @hotwired/turbo 8). The link clicked last stands in for the
// submitter, for its own question only and once.
let clickedLink = null

function rememberClickedLink (event) {
  clickedLink = event.composedPath()[0].closest?.('a[data-turbo-confirm]') || null
}

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

  const trigger = submitter || (clickedLink?.dataset.turboConfirm === message ? clickedLink : null)
  clickedLink = null
  const title = dataValue(trigger, formElement, 'baliConfirmTitle')
  const variant = dataValue(trigger, formElement, 'baliConfirmVariant')

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

  const fallback = { ...inLanguageOf(dialog, LABELS), ...installedLabels }
  acceptBtn.textContent = dataValue(trigger, formElement, 'baliConfirmAccept') || fallback.accept
  cancelBtn.textContent = dataValue(trigger, formElement, 'baliConfirmCancel') || fallback.cancel

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
  if (options.acceptText) installedLabels.accept = options.acceptText
  if (options.cancelText) installedLabels.cancel = options.cancelText

  if (typeof window === 'undefined' || window.BALI_DISABLE_CONFIRM_DIALOG) return
  if (installed) return
  installed = true
  document.addEventListener('click', rememberClickedLink, true)

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
