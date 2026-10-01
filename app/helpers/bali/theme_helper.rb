# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer), for the layout's root:
  #
  #   <html data-theme="<%= bali_theme %>">
  #
  # Decided on the server so a dark page arrives dark instead of flashing light first.
  module ThemeHelper
    # Written by the theme-toggle controller (app/components/bali/topbar/user_menu/index.js),
    # which takes the cookie name from the UserMenu's data values and writes "dark" or "light".
    COOKIE = "bali_theme"
    DARK = "dark"

    UNCONFIGURED = "bali_theme needs the app's themes: set " \
                   '`Bali.themes = { light: "afal", dark: "afal-dark" }` in ' \
                   "config/initializers/bali.rb (`dark:` is optional)."

    def self.themes
      Bali.themes.presence || raise(ArgumentError, UNCONFIGURED)
    end

    def self.dark?(request)
      Bali.themes&.dig(:dark).present? && request.cookies[COOKIE] == DARK
    end

    def bali_theme
      themes = ThemeHelper.themes
      ThemeHelper.dark?(request) ? themes[:dark] : themes.fetch(:light)
    end
  end
end
