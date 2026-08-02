# frozen_string_literal: true

module Bali
  module FlashNotifications
    # Deprecated in v3, removed in v4. Renamed to {Bali::ToastContainer::Component},
    # which this subclasses.
    #
    # The rename comes with the reason for it: this took `notice:` and `alert:`, two
    # keywords, so `flash[:warning]` and `flash[:info]` had nowhere to go and were
    # silently dropped by every caller that passed the flash through. The
    # replacement takes the hash — `flash:` — and maps every key it knows.
    #
    # It is also the fixed container now, which it was not before: it rendered two
    # inline notifications and left the positioning to whoever wrapped it, which is
    # why `Bali::AppLayout` carried a hand-written copy of that wrapper.
    class Component < Bali::ToastContainer::Component
      def initialize(notice: nil, alert: nil, **options)
        Bali.deprecator.warn(
          "Bali::FlashNotifications::Component is deprecated and is removed in 4.0. " \
          "Use Bali::ToastContainer::Component, which takes the whole hash — " \
          "`flash: flash` — instead of `notice:`/`alert:`. " \
          "See docs/guides/migration-v2-to-v3.md."
        )

        super(flash: { notice: notice, alert: alert }.compact, **options)
      end
    end
  end
end
