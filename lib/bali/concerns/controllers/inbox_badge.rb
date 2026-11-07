# frozen_string_literal: true

module Bali
  module Concerns
    module Controllers
      # THE TOPBAR ICON'S NUMBERS, for every page. Include it in the host's ApplicationController:
      #
      #   class ApplicationController < ActionController::Base
      #     include Bali::Concerns::Controllers::InboxBadge
      #   end
      #
      #   <%= render Bali::Topbar::Inbox::Component.new(badge: inbox_badge, …) %>
      #
      # `inbox_badge` is nil without an owner, and the icon then renders nothing. Any request
      # the owner makes that is not a GET or HEAD expires their badge, so resolving something
      # lowers the number on the very next page.
      #
      # Seams: `inbox_owner`, `current_user` by default, and `owner_reading?`, false while someone
      # acts as the owner (bali-auth's `impersonating?`). The inbox controller
      # (`Bali::Concerns::Controllers::Inbox`) reads the same two. While someone acts as the owner
      # the badge is counted on every request and never cached: a host may list that session less
      # than the owner, and the owner would see its number on their next page.
      module InboxBadge
        extend ActiveSupport::Concern

        included do
          helper_method :inbox_badge
          after_action :expire_inbox_badge, unless: -> { request.get? || request.head? }
        end

        private

        def inbox_badge
          return @inbox_badge if defined?(@inbox_badge)

          owner = inbox_owner
          @inbox_badge = owner && (owner_reading? ? Bali::Inbox::Badge.for(owner) : Bali::Inbox::Badge.compute(owner))
        end

        # `current_user` is usually private, which `try` does not reach.
        def inbox_owner
          current_user if respond_to?(:current_user, true)
        end

        def owner_reading? = !(respond_to?(:impersonating?, true) && impersonating?)

        # For a host screen that opens a record itself, such as a panel in a drawer. A prefetch marks
        # nothing (Turbo sends `X-Sec-Purpose`, a browser's speculation rules `Sec-Purpose`), but
        # Turbo serves the click from it, so a page link to such a screen still opts out of prefetch.
        def mark_inbox_seen(record)
          owner = inbox_owner
          return unless owner && owner_reading?
          return if %w[X-Sec-Purpose Sec-Purpose].any? { request.headers[it].to_s.include?("prefetch") }

          Bali::Inbox::Query.new(owner).mark_record_seen!(record)
        end

        def expire_inbox_badge
          owner = inbox_owner
          Bali::Inbox::Badge.expire(owner) if owner
        end
      end
    end
  end
end
