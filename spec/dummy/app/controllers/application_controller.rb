# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Un solo lugar decide que un `?layout=false` es el Modal/Drawer trayéndose la vista: el
  # concern apaga el layout y expone `drawer_request?` a las vistas, que es de donde los page
  # components autodetectan su `context:`. Antes cada acción lo escribía a mano
  # (`render layout: !drawer_request?`) sobre su propia copia del predicado. Un controller con
  # layout propio lo declara con `self.conditional_layout = "..."`, no con `layout "..."`:
  # `layout` en la subclase pisa al del concern y se lleva puesto el apagado.
  include Bali::LayoutConcern
  # `filter_form(Klass, scope)` con el circuito de la persistencia cerrado (#999):
  # storage_id derivado, cookie leída, context desde `Bali.filter_context`.
  include Bali::Filterable

  around_action :switch_locale

  helper_method :current_user

  private

  # Identidad única del demo, la misma que resuelve `Bali.saved_views_owner` para el
  # controller del engine: el dueño de las vistas guardadas y el nombre del topbar son el
  # mismo hecho, escrito una vez.
  def current_user
    @current_user ||= User.demo
  end

  # La caché de persistencia de filtros se llama `class;context;storage_id`: SIN `context:` un
  # único key sirve a TODAS las visitas del proceso, así que los filtros —y el texto de la
  # búsqueda rápida— de un visitante se le restauran al siguiente. Con el `:null_store` esto no
  # se veía porque no se guardaba nada; con una caché real el dummy tiene que demostrar el
  # patrón AISLADO, que es el que una app host va a copiar. El demo tiene un solo usuario, así
  # que la identidad que separa acá es el navegador.
  # Lo lee `Bali.filter_context` (ver config/initializers/bali.rb): el demo tiene un solo
  # usuario, así que la identidad que separa la persistencia es el navegador.
  def filter_context
    session[:visitor_token] ||= SecureRandom.hex(8)
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
