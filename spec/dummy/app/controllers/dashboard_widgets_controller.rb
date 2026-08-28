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

  # A resize changes the card's SHAPE, and the card's interior is server-rendered
  # — so `head :no_content` leaves a grown card showing the body it had at its old
  # size: an axis-less sparkline stretched across a `large` cell, or a hero number
  # alone in a 2x2. The grid sends `resized_key` for exactly this, and answering
  # with a stream costs one widget query on an already-debounced write.
  #
  # Every other gesture still answers 204: reorder and remove change position, not
  # shape, and the DOM the browser already has is correct.
  def update
    layout.arrange(permitted_layout)

    resized = resized_widget
    return head :no_content unless resized

    render turbo_stream: turbo_stream.replace(
      Bali::Widget::Component.dom_id(resized.key),
      renderable: Bali::Widget::Component.new(resized.widget, size: resized.size)
    )
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
    @layout ||= Bali::DashboardWidget::Store.new(
      owner: current_user,
      dashboard_key: "demo",
      offering: offering
    )
  end

  def offering
    @offering ||= DemoWidgets.authorized_for(current_user)
  end

  # Looked up in the arrangement we just wrote, so it comes back at its NEW size.
  # Nil for every gesture that is not a resize, and for a key outside the
  # offering — the same boundary `permitted_layout` enforces.
  def resized_widget
    key = params[:resized_key].presence
    return if key.nil?

    layout.widgets.find { |placement| placement.key == key }
  end

  # THE BOUNDARY, both halves, and both of them library code now:
  # `Bali::Widget::Layout` does the lookup and this supplies the offering. A
  # submitted key becomes a widget only by being found in the already-authorized
  # set — an unauthorized, retired or hand-edited key finds nothing and is
  # dropped. That is the design's entire security property, and it used to be a
  # dozen lines every host retyped out of a guide.
  def permitted_layout = Bali::Widget::Layout.from(params, offering: offering)

  def permitted_widgets = Bali::Widget::Layout.chosen(params, offering: offering)
end
