# frozen_string_literal: true

module DemoWidgets
  # THE DEGRADED CARD, so the showcase has one.
  #
  # It DECLARES the state rather than raising to produce it. A widget whose data
  # actually raises gets here through `Base#safely`, but `raise_load_errors?` is
  # true in development — the safety net working as designed — so a demo widget
  # that really raised would take this page down instead of showing the tile it
  # exists to show. The rescue is covered in `test/bali/widget/base_test.rb`,
  # where the environment can be stubbed.
  class UnavailableFeed < Bali::Widget::ValueBase
    default_size :small

    value { 0 }

    def failed? = true
  end
end
