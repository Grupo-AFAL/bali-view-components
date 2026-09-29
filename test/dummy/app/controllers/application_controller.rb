# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  # A single place decides that a `?layout=false` is the Modal/Drawer fetching the view: the
  # concern turns the layout off and exposes `drawer_request?` to the views, which is where the
  # page components autodetect their `context:`. Each action used to write it by hand
  # (`render layout: !drawer_request?`) over its own copy of the predicate. A controller with a
  # layout of its own declares it with `self.conditional_layout = "..."`, not with
  # `layout "..."`: `layout` in the subclass overrides the concern's and takes the shutoff
  # down with it.
  include Bali::LayoutConcern
  # `filter_form(Klass, scope)` with the persistence loop closed (#999):
  # storage_id derived, cookie read, context from `Bali.filter_context`.
  include Bali::Filterable

  around_action :switch_locale

  helper_method :current_user

  private

  # The demo's single identity, the same one `Bali.saved_views_owner` resolves for the
  # engine's controller: the owner of the saved views and the name in the topbar are the
  # same fact, written once.
  def current_user
    @current_user ||= User.demo
  end

  # The filter persistence cache key is `class;context;storage_id`: WITHOUT `context:` a
  # single key serves ALL the visits in the process, so one visitor's filters —and their quick
  # search text— get restored to the next one. With the `:null_store` this was invisible
  # because nothing was stored; with a real cache the dummy has to demonstrate the ISOLATED
  # pattern, which is the one a host app is going to copy. Read by `Bali.filter_context` (see
  # config/initializers/bali.rb). The demo has a single user, so the identity that separates
  # here is the browser.
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
