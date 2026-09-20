import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { name: String }

  switch () {
    const theme = this.nameValue
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('bali-theme', theme)
  }

  // Restore persisted theme on connect (placed on <html> or <body>)
  connect () {
    const saved = localStorage.getItem('bali-theme')
    if (saved) {
      document.documentElement.setAttribute('data-theme', saved)
    }
  }
}
