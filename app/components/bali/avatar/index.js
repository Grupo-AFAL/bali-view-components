import { Controller } from '@hotwired/stimulus'

/*
  Avatar Controller
  Replaces image from img tag with the target output so that a preview of the image can be seen

  It expects the following structure:

  <div data-controller"avatar">
    <img data-avatar-target"output" src="[some url]">
    <input data-avatar-target="input" data-action="change->avatar#showImage" />
  </div>

*/
export class AvatarController extends Controller {
  static targets = ['output', 'input']

  showImage () {
    const file = this.inputTarget.files[0]
    if (file) {
      // Only the previous one, never on `disconnect`: Turbo's snapshot for Back still shows it.
      if (this.blobUrl) URL.revokeObjectURL(this.blobUrl)

      this.blobUrl = URL.createObjectURL(file)
      this.outputTarget.src = this.blobUrl
      this.outputTarget.style.objectFit = 'cover'
    }
  }
}
