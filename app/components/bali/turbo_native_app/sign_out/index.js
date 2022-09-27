import { Controller } from '@hotwired/stimulus'

export class TurboNativeAppSignOut extends Controller {
  static values = { confirmationMessage: { type: String, default: 'Are you sure?' } }

  perform = (event) => {
    event.preventDefault()
    event.stopImmediatePropagation()

    if (window.confirm(this.confirmationMessageValue) === true && this._isTurboNativeApp) {
      window.TurboNativeBridge.postMessage('signOut')
    }
  }

  get _isTurboNativeApp () {
    return navigator.userAgent.indexOf('Turbo Native') !== -1
  }
}
