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

    # Whether the app declared a dark theme, which is what puts the switch in the UserMenu.
    def self.dark_mode?
      Bali.themes&.dig(:dark).present?
    end

    def self.dark?(request)
      dark_mode? && request.cookies[COOKIE] == DARK
    end

    def bali_theme
      themes = Bali.themes || raise(ArgumentError, UNCONFIGURED)
      ThemeHelper.dark?(request) ? themes[:dark] : themes[:light]
    end
  end
end
