# frozen_string_literal: true

# The reference host controller `docs/guides/engine-models.md` ("Dashboard
# widgets") describes — copy THIS, not `WidgetLayoutsController`. That one
# exists only to make the Lookbook preview's fetch succeed outside a real
# session (see its own comments for why) and deliberately skips forgery
# protection; this controller runs inside the dummy app's real session and
# keeps CSRF protection on, like any host would.
class DashboardWidgetsController < ApplicationController
  def index
    @layout = layout
  end

  def update
    layout.arrange(permitted_layout)
    head :no_content
  end

  private

  def layout
    @layout ||= Bali::Widget::Layout.new(
      owner: current_user,
      context: "",
      dashboard_key: "demo",
      offering: offering
    )
  end

  def offering
    @offering ||= DemoWidgets.authorized_for(current_user)
  end

  # THE BOUNDARY. A submitted key becomes a widget only by looking it up in
  # the already-authorized offering — an unauthorized or retired key finds
  # nothing and is silently dropped. That is the design's entire security
  # property; see `Bali::Widget::Layout`.
  #
  # The blank check runs BEFORE `params.expect`, deliberately: `expect` raises
  # `ActionController::ParameterMissing` on both an omitted `widgets` key and
  # an empty `widgets: []` — and an empty submission is not an error here, it
  # is the reset gesture (`Layout#arrange([])` drops every row).
  def permitted_layout
    return [] if params[:widgets].blank?

    by_key = offering.index_by(&:key)
    params.expect(widgets: [ %i[key size] ]).filter_map do |item|
      widget = by_key[item[:key].to_s]
      { widget: widget, size: item[:size] } if widget
    end
  end
end
