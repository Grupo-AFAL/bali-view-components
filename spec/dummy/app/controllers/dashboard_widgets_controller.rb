# frozen_string_literal: true

# The reference host controller `docs/guides/engine-models.md` ("Dashboard
# widgets") describes — copy THIS, not `WidgetLayoutsController`. That one
# exists only to make the Lookbook preview's fetch succeed outside a real
# session (see its own comments for why) and deliberately skips forgery
# protection; this controller runs inside the dummy app's real session and
# keeps CSRF protection on, like any host would.
class DashboardWidgetsController < ApplicationController
  def index
    @store = store
  end

  # A resize changes the card's SHAPE, and the card's interior is server-rendered
  # — so `head :no_content` leaves a grown card showing the body it had at its old
  # size: an axis-less sparkline stretched across a `large` cell, or a hero number
  # alone in a 2x2. The grid sends `resized_key` for exactly this, and answering
  # with a stream costs one widget query on an already-debounced write.
  #
  # Every other gesture still answers 204: reorder and remove change position, not
  # shape, and the DOM the browser already has is correct.
  def update
    store.arrange(permitted_layout)

    resized = resized_widget
    return head :no_content unless resized

    render turbo_stream: turbo_stream.replace(
      Bali::Widget::Component.dom_id(resized.key),
      renderable: Bali::Widget::Component.new(resized.widget, size: resized.size)
    )
  end

  # The picker: EVERY authorized widget, not just the chosen ones — `store`
  # only reads what's already stored, and `offering` is what the picker's
  # checkboxes have to be built from instead. `Store#offering` is private on
  # purpose (see its own comments), so the controller hands the view its own
  # copy rather than reaching around that boundary.
  def picker
    @store = store
    @offering = offering
  end

  def update_picker
    store.choose(permitted_widgets)
    redirect_to dashboard_widgets_path, notice: t('.success')
  end

  def reset
    store.reset
    redirect_to dashboard_widgets_path, notice: t('.success')
  end

  private

  def store
    @store ||= Bali::DashboardWidget::Store.new(
      owner: current_user,
      dashboard_key: "demo",
      offering: offering
    )
  end

  # MEMOISED, and both `permitted_layout` and `store` read this one copy. Two
  # calls to `authorized_for` could disagree if a flag flipped between them,
  # and a key that passed the params filter would then vanish in the store.
  def offering
    @offering ||= DemoWidgets.authorized_for(current_user)
  end

  # Looked up in the arrangement we just wrote, so it comes back at its NEW size.
  # Nil for every gesture that is not a resize, and for a key outside the
  # offering — the same boundary `permitted_layout` enforces.
  def resized_widget
    key = params[:resized_key].presence
    return if key.nil?

    store.widgets.find { |placement| placement.key == key }
  end

  # THE BOUNDARY. A submitted key becomes a widget only by being FOUND in the
  # already-authorized offering: an unauthorized, retired or hand-edited key
  # finds nothing and is DROPPED rather than rejected. Silently, because a role
  # revoked between rendering the page and submitting it should degrade quietly,
  # and because refusing a made-up key would confirm which keys are real.
  #
  # `Store#arrange` gates against the offering again on its own — it is the
  # primitive a controller can reach directly — so this is the outer of two
  # independent boundaries rather than the only one.
  #
  # The `blank?` guard runs BEFORE any parsing, deliberately: `params.expect`
  # raises `ParameterMissing` on both an omitted `widgets` key AND an empty
  # `widgets: []`, and only one of those is an error. Removing the last card
  # submits nothing at all, which is the RESET gesture — 400ing there is a bug.
  def permitted_layout
    submitted = params[:widgets]
    return [] if submitted.blank?

    by_key = Bali::Widget.by_key(offering)
    submitted.filter_map do |item|
      widget = by_key[item[:key].to_s]
      Bali::Widget::Placement.new(widget: widget, size: item[:size].presence) if widget
    end
  end

  # The picker's payload. Membership only — `Store#choose` decides order and
  # preserves stored sizes, so no `Placement` here.
  def permitted_widgets
    by_key = Bali::Widget.by_key(offering)
    Array(params[:widget_keys]).filter_map { |key| by_key[key.to_s] }
  end
end
