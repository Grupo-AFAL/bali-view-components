# frozen_string_literal: true

module Bali
  module Widget
    module Degraded
      # THE APOLOGY, rendered by `Bali::Widget::Component`'s error boundary when
      # a widget raises.
      #
      # Its own component, and deliberately the dumbest one in the feature: it
      # reads a title off the widget's CLASS — copy, never data — so there is
      # nothing here that can fail while reporting a failure.
      #
      # It carries the widget's own name because a bare "couldn't load" in a
      # bento of twelve cards does not say WHICH one failed.
      #
      # `text-warning`, not the `/40` grey the empty state uses: those are
      # opposite messages, and the muted one already means "nothing to do". No
      # retry link either — the reload is the retry, and a button that re-runs
      # the same broken query promises a recovery this card cannot make.
      class Component < ApplicationViewComponent
        def initialize(widget)
          @widget = widget
          super()
        end

        def call
          tag.div(class: "flex flex-1 flex-col items-center justify-center gap-1 px-2 text-center") do
            safe_join([
              tag.p(short_title, class: "text-sm font-medium text-base-content/70"),
              tag.p(t("bali_view.widgets.load_error"), class: "text-xs text-warning")
            ])
          end
        end

        private

        # Rescued rather than assumed: a widget whose i18n key is missing must
        # not raise from inside the thing that exists to report a raise.
        def short_title
          @widget.short_title
        rescue StandardError
          @widget.class.name.to_s.demodulize.underscore.humanize
        end
      end
    end
  end
end
