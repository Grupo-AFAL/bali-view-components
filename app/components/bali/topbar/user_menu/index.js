import { Controller } from '@hotwired/stimulus'

// The UserMenu's dark-mode switch. Every name it touches comes from the server:
// the theme pair from `Bali.themes` and the cookie from Bali::ThemeHelper::COOKIE
// (app/helpers/bali/theme_helper.rb), which reads back the "dark" or "light" written
// here to paint the next page already dark.
const YEAR_IN_SECONDS = 60 * 60 * 24 * 365

export class ThemeToggleController extends Controller {
  static values = { light: String, dark: String, cookie: String }

  toggle () {
    const dark = this.element.getAttribute('aria-checked') !== 'true'

    document.documentElement.setAttribute('data-theme', dark ? this.darkValue : this.lightValue)
    this.element.setAttribute('aria-checked', String(dark))

    const secure = window.location.protocol === 'https:' ? '; secure' : ''
    document.cookie = `${this.cookieValue}=${dark ? 'dark' : 'light'}; path=/; max-age=${YEAR_IN_SECONDS}; samesite=lax${secure}`
  }
}
