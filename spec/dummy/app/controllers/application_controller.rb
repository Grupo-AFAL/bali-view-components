# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  around_action :switch_locale

  private

  def switch_locale(&)
    # Check for locale param (for switching), then session, then default
    if params[:locale].present? && I18n.available_locales.map(&:to_s).include?(params[:locale])
      session[:locale] = params[:locale]
    end

    locale = session[:locale] || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
