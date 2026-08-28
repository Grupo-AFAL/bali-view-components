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
    store.arrange(submitted_layout)

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
    store.choose(submitted_widgets)
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

  # MEMOISED, so the picker's checkboxes and the store are built from one
  # copy. Two calls to `authorized_for` could disagree if a flag flipped
  # between them.
  def offering
    @offering ||= DemoWidgets.authorized_for(current_user)
  end

  # Looked up in the arrangement we just wrote, so it comes back at its NEW size.
  # Nil for every gesture that is not a resize, and for a key outside the
  # offering — the same boundary `arrange` enforced a line earlier.
  def resized_widget
    key = params[:resized_key].presence
    return if key.nil?

    store.widgets.find { |placement| placement.key == key }
  end

  # JUST THE WIRE FORMAT, handed over as-is. No lookup, no `Placement`, no
  # offering, and nothing to unpack: `arrange` takes `{ key:, size: }` items,
  # resolves them against the offering itself, and drops anything it cannot
  # find. All a host owns is the shape of its own params.
  #
  # The `blank?` guard runs BEFORE `expect`, deliberately: `expect` raises
  # `ParameterMissing` — a 400 — on an omitted `widgets` key AND on an empty
  # `widgets: []`, and only one of those is an error. Removing the last card
  # submits nothing at all, and that is the RESET gesture.
  #
  # `expect` rather than reading `params[:widgets]` directly, for the case the
  # guard does not cover: `?widgets=lol` is a String, and indexing it with
  # `[:key]` raises `TypeError` — a 500 for a malformed request that deserves a
  # 400. Nothing here is mass-assigned, so permitting buys no safety; the SHAPE
  # check is the whole reason it is worth the call.
  def submitted_layout
    return [] if params[:widgets].blank?

    params.expect(widgets: [ [ :key, :size ] ])
  end

  # The picker submits membership, not an arrangement — `Store#choose` decides
  # order and preserves stored sizes. Widgets rather than keys, because `choose`
  # takes the objects; `arrange`, which it calls through, does the gating.
  def submitted_widgets
    by_key = Bali::Widget.by_key(offering)
    Array(params[:widget_keys]).filter_map { |key| by_key[key.to_s] }
  end
end
