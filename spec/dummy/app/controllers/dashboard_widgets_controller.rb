# frozen_string_literal: true

# The reference host controller `docs/guides/engine-models.md` ("Dashboard
# widgets") describes — copy THIS, not `WidgetLayoutsController`. That one
# exists only to make the Lookbook preview's fetch succeed outside a real
# session (see its own comments for why) and deliberately skips forgery
# protection; this controller runs inside the dummy app's real session and
# keeps CSRF protection on, like any host would.
#
# The whole integration is the two declarations below. Every action, every
# params filter and the picker page come from the concern; this app supplies
# a catalog, an owner, and one overridden template.
class DashboardWidgetsController < ApplicationController
  include Bali::Concerns::Controllers::DashboardWidgets

  dashboard_widgets catalog: DemoWidgets::ALL, dashboard_key: "demo"

  private

  def widget_owner = current_user

  # NO `edit` TEMPLATE IN THIS APP — the picker below is Bali's own, rendered
  # through `_prefixes`. `show` IS overridden, in `app/views/dashboard_widgets/`,
  # because the demo wants a page header explaining itself. Between them the two
  # halves of the view contract are exercised: default, and override.
end
