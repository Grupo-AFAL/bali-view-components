# frozen_string_literal: true

module Bali
  module Toast
    # A `Bali::Alert` that leaves on its own.
    #
    # Everything about how a toast *looks* -- the colour map, the icon, the close
    # button, the ARIA role -- comes from `Bali::Alert::Component`. What this adds
    # is the auto-dismiss default and the leaving animation, and what it removes is
    # the positioning: `Bali::ToastContainer` owns that now. v2's `Notification`
    # positioned itself with `fixed:`/`position:`, which is why every stack of them
    # had to be hand-assembled by the caller -- `Bali::AppLayout` carried its own
    # copy of that markup.
    class Component < ApplicationViewComponent
      BASE_CLASSES = "toast-component shadow-xl"

      # The class the Stimulus controller adds on the way out. A host can point the
      # controller at its own class through `data-alert-leaving-class`; the
      # controller reads the animation length back from the CSS, so a replacement
      # of any duration works without telling it how long it takes.
      LEAVING_CLASS = "toast-leaving"

      DEFAULT_DURATION = 3000

      # rubocop:disable Metrics/ParameterLists
      def initialize(color: :info, title: nil, style: nil, icon: true, role: nil,
                     closable: true, duration: DEFAULT_DURATION, **options)
        @color = color
        @title = title
        @style = style
        @icon = icon
        @role = role
        @closable = closable
        # `false` and `0` are both ways a caller says "never close on its own".
        @duration = duration.presence
        @options = prepend_class_name(options, BASE_CLASSES)
        @options[:data] = { alert_leaving_class: LEAVING_CLASS }.merge(@options[:data] || {})
      end
      # rubocop:enable Metrics/ParameterLists

      def alert
        Bali::Alert::Component.new(
          color: @color, title: @title, style: @style, icon: @icon, role: @role,
          closable: @closable, duration: @duration, **@options
        )
      end
    end
  end
end
