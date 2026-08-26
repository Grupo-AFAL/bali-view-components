# frozen_string_literal: true

module Bali
  module Widget
    # What the card's context region charts — the history behind the headline.
    #
    # `type` is a `Bali::Chart` type rather than a Bali-invented vocabulary, so a
    # widget that wants bars instead of a line says `:bar` and the card passes it
    # straight through. Defaults to `:line`, because the sparkline is the case
    # this exists for.
    #
    # `labels` may be empty: at `medium` the chart draws without axes, so there
    # is nothing to label, and requiring them would be asking every widget to
    # produce data for a surface that will not render it.
    Series = Data.define(:labels, :values, :type) do
      def initialize(values:, labels: [], type: :line)
        super
      end

      def any? = values.present?
    end
  end
end
