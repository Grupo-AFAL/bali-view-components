# frozen_string_literal: true

# Route helpers for widgets, as a CONCERN rather than a base class.
#
# `Bali::Widget::Base` deliberately hands you none — an engine reaching into a
# host's routes at class-definition time is a load-order problem waiting to
# happen. Before the pattern bases, a host answered that with one
# `ApplicationWidget < Bali::Widget::Base`. It cannot now: the parent is
# dictated by the pattern, so a single host base class would have to be four.
#
# A module is the substitute. Same one line per widget, but named.
module WidgetRoutes
  include Rails.application.routes.url_helpers

  # `url_helpers` asks for these on every call. Empty is right for a dashboard:
  # every path a widget builds is relative, and a host wanting absolute URLs
  # overrides this in its own concern.
  def default_url_options = {}
end
