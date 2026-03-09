import { Controller } from '@hotwired/stimulus'

export class DocumentPageController extends Controller {
  static targets = ['tocPanel', 'tocToggle', 'metadataPanel', 'metadataToggle']

  static values = {
    tocOpen: { type: Boolean, default: true },
    metadataOpen: { type: Boolean, default: true }
  }

  toggleToc () {
    this.tocOpenValue = !this.tocOpenValue
  }

  toggleMetadata () {
    this.metadataOpenValue = !this.metadataOpenValue
  }

  tocOpenValueChanged () {
    if (this.hasTocPanelTarget) {
      this.tocPanelTarget.classList.toggle('hidden', !this.tocOpenValue)
    }
    if (this.hasTocToggleTarget) {
      this.tocToggleTarget.classList.toggle('btn-active', this.tocOpenValue)
    }
  }

  metadataOpenValueChanged () {
    if (this.hasMetadataPanelTarget) {
      this.metadataPanelTarget.classList.toggle('hidden', !this.metadataOpenValue)
    }
    if (this.hasMetadataToggleTarget) {
      this.metadataToggleTarget.classList.toggle('btn-active', this.metadataOpenValue)
    }
  }
}
