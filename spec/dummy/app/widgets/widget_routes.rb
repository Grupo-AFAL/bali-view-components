# frozen_string_literal: true

# Route helpers for widgets, as a CONCERN rather than a base class.
#
# `Bali::Widget::Base` deliberately hands you none — an engine reaching into a
# host's routes at class-definition time is a load-order problem waiting to
# happen. Before the pattern bases, a host answered that with one
# `ApplicationWidget < Bali::Widget::Base`. It cannot now: the parent is
# dictated by the pattern, so a single host base class would have to be four.
#
# A concern is the substitute. Same one line per widget, but named — and
# `ActiveSupport::Concern` rather than a plain module on purpose: losing
# `ApplicationWidget` costs a host its class-level shared behaviour too, and only
# the `included do` / `class_methods do` form can give that back. A house
# `i18n_scope`, a default `supports`, a shared `visible?` policy all go here.
module WidgetRoutes
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  # `url_helpers` asks for these on every call. Empty is right for a dashboard:
  # every path a widget builds is relative, and a host wanting absolute URLs
  # overrides this in its own concern.
  def default_url_options = {}
end
