# frozen_string_literal: true

module Bali
  module Widget
    # What every widget's `#call` returns. `Base` delegates the readers to it, so
    # `Bali::Widget::Component` talks to the widget and never sees this.
    #
    # `failed` is a field rather than a class-level declaration because a
    # declaration fifteen lines from the `#call` it describes can drift from what
    # `#call` actually returns; a field on the result cannot.
    #
    # `payload` carries pre-loaded data for a widget rendering custom content
    # through the card's `body` slot; list widgets leave it nil.
    Result = Data.define(:count, :items, :view_all_path, :payload, :failed) do
      def initialize(count: 0, items: [], view_all_path: nil, payload: nil, failed: false)
        super
      end

      # The degraded card a widget falls back to when its `#call` raises. A
      # FAILURE rather than a dropped widget on purpose: a tile that vanishes
      # reads as "nothing to see", which is the one thing a failure must not say.
      def self.failed = new(failed: true)

      def failed? = failed
    end
  end
end
