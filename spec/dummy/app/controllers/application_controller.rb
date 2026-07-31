# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  around_action :switch_locale

  helper_method :current_user

  private

  # Identidad única del demo, la misma que resuelve `Bali.saved_views_owner` para el
  # controller del engine: el dueño de las vistas guardadas y el nombre del topbar son el
  # mismo hecho, escrito una vez.
  def current_user
    @current_user ||= User.demo
  end

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
