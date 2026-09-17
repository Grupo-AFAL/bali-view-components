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

  # THE CATALOG IS THIS DASHBOARD'S DEFAULT LAYOUT, which is why it lives here
  # rather than in a `DemoWidgets::ALL` constant off to one side. Its ORDER is
  # what a user with no stored rows sees, top-left to bottom-right — and a
  # second dashboard would be a second ordering, not a second reader of one
  # app-wide list.
  #
  # Ordered so it walks the ladders rather than the alphabet: the compact facts
  # first, then the metric widgets that argue opposite directions, then the
  # ring, then the list widgets it all grew out of.
  dashboard_widgets dashboard_key: "demo", catalog: [
    DemoWidgets::OverdueTasks,
    DemoWidgets::ProductionBudget,
    DemoWidgets::UnavailableFeed,
    DemoWidgets::ReleaseReadiness,
    DemoWidgets::SchemaHealth,
    DemoWidgets::RatingsAudit,
    DemoWidgets::ModernStudios,
    DemoWidgets::CatalogCoverage,
    DemoWidgets::StudioSizes,
    DemoWidgets::IndieStudios,
    DemoWidgets::StudioFoundings,
    DemoWidgets::TaskLoad,
    DemoWidgets::ProjectProgress,
    DemoWidgets::RecentMovies,
    DemoWidgets::ActiveStudios,
    DemoWidgets::UpcomingTasks,
    DemoWidgets::TopBudgetMovies
  ]

  private

  def widget_owner = current_user

  # NO `edit` TEMPLATE IN THIS APP — the picker below is Bali's own, rendered
  # through `_prefixes`. `show` IS overridden, in `app/views/dashboard_widgets/`,
  # because the demo wants a page header explaining itself. Between them the two
  # halves of the view contract are exercised: default, and override.
end
