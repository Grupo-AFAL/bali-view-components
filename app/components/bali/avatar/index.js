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
      this.outputTarget.src = URL.createObjectURL(file)
      this.outputTarget.style.objectFit = 'cover'
    }
  }
}
