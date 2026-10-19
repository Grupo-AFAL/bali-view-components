# frozen_string_literal: true

module Bali
  module Topbar
    module Inbox
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # The one topbar icon of #1512, counter A: the number is what is waiting on you and the
        # dot says there are unread notices. A click opens the popover, which loads the dummy's
        # `/inbox/popover` then; a cmd-click opens the full page.
        # @param pending number
        # @param unread number
        def default(pending: 6, unread: 2)
          render_with_template(template: "bali/topbar/inbox/previews/default",
                               locals: { badge: Bali::Inbox::Badge.new(pending: pending.to_i, unread: unread.to_i) })
        end

        # @label States
        # The four counters side by side: nothing, pending only, unread only, both — and 99+.
        def states
          render_with_template(template: "bali/topbar/inbox/previews/states")
        end
      end
    end
  end
end
