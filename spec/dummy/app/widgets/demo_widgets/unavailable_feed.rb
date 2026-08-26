# frozen_string_literal: true

module DemoWidgets
  # THE DEGRADED CARD, so the showcase has one.
  #
  # It returns `Result.failed` rather than raising, and that is deliberate.
  # `Bali::Widget.raise_load_errors?` is TRUE in development and test — which is
  # the correct production safety net working as designed: a widget bug is loud
  # where someone can fix it. A demo widget that actually raised would therefore
  # take this whole page down in the environment the page is read in, rather than
  # showing the degraded tile it exists to show.
  #
  # So this demonstrates the CARD, not the rescue. The rescue is covered by
  # `test/bali/widget/base_test.rb`, where the environment can be stubbed.
  class UnavailableFeed < Bali::Widget::Base
    sized :small

    def call
      Bali::Widget::Result.failed
    end
  end
end
