import { Controller } from '@hotwired/stimulus'

// TODO: Add tests (Issue: #140)
export class FocusOnConnectController extends Controller {
  connect () {
    this.element.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }
}
