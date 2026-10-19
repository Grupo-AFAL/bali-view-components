# frozen_string_literal: true

module Bali
  module Inbox
    # The topbar icon's two numbers: what is waiting on the person, and their unread notices that
    # announce nothing. Cached per person for a minute, so a page with a warm cache runs one cache
    # read and no provider or notice query.
    class Badge < Data.define(:pending, :unread)
      TTL = 1.minute

      class << self
        # Cached as a Hash, not the object: an entry written by the previous deploy still reads.
        def for(owner)
          new(**Rails.cache.fetch(key(owner), expires_in: TTL) { compute(owner).to_h }.symbolize_keys)
        end

        def compute(owner)
          new(pending: Query.new(owner).count, unread: Bali::Notice.unread.listed.addressed_to(owner).count)
        end

        def write(owner, badge) = Rails.cache.write(key(owner), badge.to_h, expires_in: TTL)

        def expire(owner) = Rails.cache.delete(key(owner))

        # Expires, then tells the person's open pages to fetch their badge again. The message
        # carries no count, so writing a notice to thousands of people computes nothing for
        # anyone who is not looking.
        def refresh(owner)
          expire(owner)
          return unless defined?(Turbo::StreamsChannel)

          signal = Bali::Topbar::Inbox::Component
          Turbo::StreamsChannel.broadcast_replace_to(owner, :bali_inbox, target: signal::SIGNAL_ID, html: signal.signal_tag)
        end

        def key(owner) = "bali/inbox/badge/#{owner.to_gid_param}"
      end

      def unread? = unread.positive?
    end
  end
end
