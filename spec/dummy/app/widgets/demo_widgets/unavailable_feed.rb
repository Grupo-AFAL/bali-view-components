# frozen_string_literal: true

module DemoWidgets
  # THE DEGRADED CARD, so the showcase has one.
  #
  # `Bali::Widget::Unavailable` rather than a bare `raise`: a widget whose source
  # is down is reporting a FACT, and the card degrades without re-raising in
  # development. A plain exception is a BUG, and development would rightly show
  # it — which would take this showcase down rather than demonstrate the tile it
  # exists to demonstrate.
  class UnavailableFeed < Bali::Widget::ValueBase
    default_size :small

    value { raise Bali::Widget::Unavailable, "the box office feed is down" }
  end
end
