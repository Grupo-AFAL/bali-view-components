# frozen_string_literal: true

module Bali
  # Dashboard widgets: the contract a host's widget classes implement, and the
  # value objects they return. `Bali::Widget::Component` renders one of them and
  # `Bali::WidgetGrid::Component` arranges many.
  #
  # This file exists so the namespace is EXPLICIT and can hold constants —
  # without it Zeitwerk would define `Bali::Widget` implicitly from the two
  # directories that extend it (`app/lib/bali/widget/` and
  # `app/components/bali/widget/`) and `SIZES` would have nowhere to live.
  module Widget
    # Semantic, not Tailwind — and 2-D, adapted from iOS: `small` is 1x1,
    # `medium` 2x1, `large` 2x2, `wide` 4x1. `large` is `medium`'s WIDTH at
    # double HEIGHT, which is why it earns more rows rather than wider ones.
    SIZES = %i[small medium large wide].freeze

    # Subtitles read "A · B" everywhere. The separator lives here rather than
    # baked into translator-editable strings.
    SEPARATOR = " · "

    class << self
      # Blank parts drop out, so a widget with only one half doesn't render a
      # dangling separator.
      def subtitle(*parts)
        parts.compact_blank.join(SEPARATOR)
      end

      # Whether a widget whose `#call` raises should take the request down with
      # it. True in development and test, so a widget bug is loud where someone
      # can fix it — this is what keeps `Base`'s rescue from being the blanket
      # kind that turns a bug into a permanent shrug. False in production, where
      # the person looking at the dashboard cannot fix it and the other tiles
      # are still worth rendering.
      #
      # A method, not a constant: `Rails.env` is read per call so a test can
      # stub this without freezing the answer at boot.
      def raise_load_errors? = Rails.env.local?

      # The gate. Un-called widget instances, so it costs only whatever the
      # host's `visible?` costs — never a widget query.
      def authorized_for(widgets)
        widgets.select(&:visible?)
      end
    end
  end
end
