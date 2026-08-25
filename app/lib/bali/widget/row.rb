# frozen_string_literal: true

module Bali
  module Widget
    # One row shape for every list widget: a title, linked when the row carries
    # an href, with a subtitle under it. Typed rather than a bare Hash because a
    # renamed key across a dozen widgets would otherwise render a blank cell
    # instead of raising.
    Row = Data.define(:title, :subtitle, :href) do
      def initialize(title:, subtitle: nil, href: nil)
        super
      end
    end
  end
end
