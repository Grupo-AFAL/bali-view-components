import { Controller } from '@hotwired/stimulus'

// The UserMenu's dark-mode switch. The theme names and the cookie's name come from the
// server; the cookie's value is "dark" or "light", which Bali::ThemeHelper
// (app/helpers/bali/theme_helper.rb, DARK) reads back to paint the next page dark.
//
// The page's <html data-theme> is the state, not the switch's own aria-checked: a Turbo
// restoration visit paints a snapshot taken before the theme changed, so the attribute can
// be stale, and a second UserMenu on the page never sees the first one's click.
const YEAR_IN_SECONDS = 60 * 60 * 24 * 365

export class ThemeToggleController extends Controller {
  static values = { light: String, dark: String, cookie: String }

  connect () {
    this.sync()
  }

  toggle () {
    const dark = !this.isDark

    document.documentElement.setAttribute('data-theme', dark ? this.darkValue : this.lightValue)
    this.sync()

    const secure = window.location.protocol === 'https:' ? '; secure' : ''
    document.cookie = `${this.cookieValue}=${dark ? 'dark' : 'light'}; path=/; max-age=${YEAR_IN_SECONDS}; samesite=lax${secure}`
  }

  get isDark () {
    return document.documentElement.getAttribute('data-theme') === this.darkValue
  }

  sync () {
    this.element.setAttribute('aria-checked', String(this.isDark))
  }
}
