import { Controller } from '@hotwired/stimulus'
import {
  topLayerHost,
  enterTopLayer,
  leaveTopLayer
} from '../../../assets/javascripts/bali/utils/top-layer.js'

/**
 * Keeps the toast stack readable over an overlay that lives in the top layer.
 *
 * The stacking scale promises `--bali-z-toast: 700` above `--bali-z-modal: 400`,
 * and inside the document it delivers. But Modal, Drawer and Command open with
 * `showModal()`, so they are painted in the top layer — above every z-index there
 * is — and they make everything outside their own subtree inert. A flash that
 * arrives while one of them is open is exactly the case that breaks: it is the
 * usual shape of a failed submit, which by design leaves the panel open.
 *
 * The only move the top layer leaves is to join it, and joining it means moving
 * into the open overlay's subtree — a top-layer element that is not a descendant
 * of the blocking dialog is still inert (measured in
 * `docs/guides/overlays-and-the-top-layer.md`). So the stack travels into the
 * overlay for as long as the overlay lasts and goes back where it was on close.
 * The node moves; its id does not, so a host's
 * `turbo_stream.append "toast-notifications"` keeps landing in the same place.
 *
 * Deliberately stateless: moving an element makes Stimulus disconnect and
 * reconnect the controller, so anything remembered on `this` would be thrown
 * away by the very move that needs remembering. What has to survive is held by
 * the closure listening for the host's `close` event instead.
 */
export class ToastContainerController extends Controller {
  connect () {
    // Toasts arrive one at a time, from a Turbo stream or a host's own script,
    // long after this connected. Watching the stack itself is exact and cheap;
    // watching the document for them would be neither.
    this._observer = new window.MutationObserver(() => this.sync())
    this._observer.observe(this.element, { childList: true })

    this.sync()
  }

  disconnect () {
    this._observer.disconnect()
  }

  // Idempotent, and safe to call on every mutation: it is a no-op unless there is
  // something to show and an overlay that would swallow it.
  sync () {
    if (this.element.childElementCount === 0) return

    const host = this.overlayHost()
    if (!host || host.contains(this.element)) return

    const parent = this.element.parentElement
    const next = this.element.nextElementSibling

    if (!enterTopLayer(this.element, host)) return

    host.addEventListener('close', () => this.release(parent, next), { once: true })
  }

  release (parent, next) {
    leaveTopLayer(this.element)

    if (!parent || !parent.isConnected) {
      document.body.appendChild(this.element)
      return
    }

    parent.insertBefore(this.element, next && next.parentElement === parent ? next : null)
  }

  // The overlay the toast has to clear is the one the user is inside, and a modal
  // dialog holds the focus by construction — which also picks the right one when
  // two are stacked, something the top layer gives no way to query. The document
  // order fallback covers the case where nothing is focused.
  overlayHost () {
    const focused = topLayerHost(document.activeElement)
    if (focused) return focused

    const dialogs = Array.from(document.querySelectorAll('dialog')).filter(dialog =>
      dialog.matches(':modal')
    )

    return dialogs[dialogs.length - 1] || null
  }
}
