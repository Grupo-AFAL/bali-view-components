import { Controller } from '@hotwired/stimulus'

export class SideMenuController extends Controller {
  static targets = ['container', 'overlay', 'link']

  connect () {
    this.scrollToActiveLinkPreviousPosition()

    if (this.hasOverlayTarget) {
      this.overlayTarget.addEventListener('click', this.closeMenu)
    }
  }

  disconnect () {
    if (this.hasOverlayTarget) {
      this.overlayTarget.removeEventListener('click', this.closeMenu)
    }
  }

  toggleMenu (e) {
    e.stopPropagation()

    if (this.hasContainerTarget) {
      this.containerTarget.classList.toggle('is-active')
    }
  }

  toggleCollapse (e) {
    e.stopPropagation()

    if (this.hasContainerTarget) {
      this.containerTarget.classList.toggle('is-collapsed')
    }
  }

  closeMenu = e => {
    const closestLink = e.target.closest('.link-component')
    if (closestLink && closestLink.dataset.sideMenuTarget === 'link') {
      const { top } = closestLink.getBoundingClientRect()
      window.sessionStorage.setItem('activeLinkPreviousPosition', top)
    }

    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove('is-active')
    }
  }

  scrollToActiveLinkPreviousPosition () {
    const activeLinkPrevPosition = window.sessionStorage.getItem('activeLinkPreviousPosition')
    const activeLink = this.linkTargets.findLast((element) => element.classList.contains('is-active'))
    if (!activeLinkPrevPosition || !activeLink) return

    const { top } = activeLink.getBoundingClientRect()
    this.containerTarget.scrollTo(
      { top: top - parseFloat(activeLinkPrevPosition), behavior: 'instant' }
    )
  }
}
