import { Controller } from '@hotwired/stimulus'

export class RateController extends Controller {
  static targets = ['star']

  submit (event) {
    const rating = parseInt(event.target.value)

    this.starTargets.forEach(star => {
      const starRating = parseInt(star.value)
      const labelNode = star.closest('label')

      if (rating >= starRating) {
        labelNode.querySelector('.icon').classList.add('solid')
      } else {
        labelNode.querySelector('.icon').classList.remove('solid')
      }
    })
  }
}
