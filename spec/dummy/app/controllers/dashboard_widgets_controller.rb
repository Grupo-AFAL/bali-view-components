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

  # The picker: EVERY authorized widget, not just the chosen ones — `layout`
  # only reads what's already stored, and `offering` is what the picker's
  # checkboxes have to be built from instead. `Layout#offering` is private on
  # purpose (see its own comments), so the controller hands the view its own
  # copy rather than reaching around that boundary.
  def picker
    @layout = layout
    @offering = offering
  end

  def update_picker
    layout.choose(permitted_widgets)
    redirect_to dashboard_widgets_path, notice: t('.success')
  end

  def reset
    layout.reset
    redirect_to dashboard_widgets_path, notice: t('.success')
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

  # THE BOUNDARY, again, for the picker: a submitted key becomes a widget only
  # by lookup in the already-authorized offering. An unauthorized, retired or
  # hand-edited key finds nothing here and is silently dropped — never
  # rejected — so a role revoked between rendering the picker and submitting
  # it degrades quietly instead of 422ing, and a made-up key can't be used to
  # probe whether it names a real widget.
  def permitted_widgets
    by_key = offering.index_by(&:key)
    Array(params[:widget_keys]).filter_map { |key| by_key[key.to_s] }
  end
end
