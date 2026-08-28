# frozen_string_literal: true

module Bali
  module Widget
    # A WIDGET AT A SIZE — one tile of an owner's arrangement.
    #
    # Size is not a property of a widget. It is a per-owner arrangement fact,
    # stored per owner and per dashboard, and the same widget class is `small`
    # for one person and `large` for another. A widget that carried its own size
    # had to be `dup`ed on every render to avoid writing it onto a class
    # attribute — resizing the widget for every user in the process until the
    # next deploy.
    #
    # So the pairing lives here instead, and `Bali::Widget::Component` is told
    # which size to draw rather than asking the widget.
    #
    # ONE SHAPE FOR BOTH DIRECTIONS: `Store#widgets` returns these and
    # `Store#arrange` consumes them, so the read path and the write path speak
    # the same language.
    Placement = Data.define(:widget, :size) do
      # RESOLVED AT CONSTRUCTION, so nothing downstream has to ask whether a size
      # is real. The name arrives from a database column, so it can describe a
      # size retired between the save and the read — or be nil, on a row written
      # before the column existed. A dashboard that will not render is a worse
      # answer than one drawn at its default.
      def initialize(widget:, size: nil)
        chosen = size&.to_sym
        chosen = widget.class.default_size unless widget.supported_sizes.include?(chosen)

        super(widget: widget, size: chosen)
      end

      # So a placement can be looked up and ordered the way a widget was.
      def key = widget.key
    end
  end
end
