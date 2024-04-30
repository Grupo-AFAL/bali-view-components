import { Controller } from '@hotwired/stimulus'

/*
 * Print Controller
 *
 * This controller is responsible for printing the current page.
 */

// TODO: Add tests (Issue: #142)
export class PrintController extends Controller {
  connect () {
    window.print()
    window.onfocus = window.close
  }
}
