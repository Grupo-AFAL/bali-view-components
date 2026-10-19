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
      # Seam: `inbox_owner`, `current_user` by default. The inbox controller
      # (`Bali::Concerns::Controllers::Inbox`) reads the same one.
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
          @inbox_badge = owner && Bali::Inbox::Badge.for(owner)
        end

        # `current_user` is usually private, which `try` does not reach.
        def inbox_owner
          current_user if respond_to?(:current_user, true)
        end

        def expire_inbox_badge
          owner = inbox_owner
          Bali::Inbox::Badge.expire(owner) if owner
        end
      end
    end
  end
end
