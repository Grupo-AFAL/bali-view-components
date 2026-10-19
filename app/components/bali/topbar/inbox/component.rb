# frozen_string_literal: true

module Bali
  module Topbar
    module Inbox
      # #1512 — the one topbar icon for «Te toca» and «Avisos», in place of an inbox and a bell.
      # A plain click opens a popover over the page and loads it then; a modified click, or no
      # JavaScript, follows the link to the full page.
      #
      #   <% topbar.with_action do %>
      #     <%= render Bali::Topbar::Inbox::Component.new(
      #           badge: inbox_badge, href: inbox_path, popover_url: popover_inbox_path,
      #           badge_url: badge_inbox_path, stream: current_user) %>
      #   <% end %>
      #
      # `badge` is `Bali::Inbox::Badge` (`inbox_badge` from
      # Bali::Concerns::Controllers::InboxBadge); without one nothing renders. `stream:` subscribes
      # the page to the owner's notices, and each new one makes the icon fetch `badge_url` again.
      class Component < ApplicationViewComponent
        # The topbar-inbox controller reads these from the DOM it is given, never by name.
        BADGE_FRAME_ID = "bali-inbox-badge"
        POPOVER_FRAME_ID = "bali-inbox-popover"
        PANEL_ID = "bali-inbox-panel"

        SKELETON_ROWS = 3

        # @param badge [Bali::Inbox::Badge, nil] the two numbers; nil renders nothing.
        # @param href [String] the full page.
        # @param popover_url [String] what the popover loads on its first open.
        # @param badge_url [String, nil] what the icon fetches when a new notice arrives.
        # @param stream [Object, nil] the owner, for `turbo_stream_from owner, :bali_inbox`.
        def initialize(badge:, href:, popover_url:, badge_url: nil, stream: nil, **options)
          @badge = badge
          @href = href
          @popover_url = popover_url
          @badge_url = badge_url
          @stream = stream
          @options = prepend_class_name(options, "bali-topbar-inbox")
        end

        # `!nil?`, not `present?`: a badge with nothing in it is `empty?`, and `present?` reads that.
        def render? = !@badge.nil?

        private

        def root_data
          { controller: "topbar-inbox", topbar_inbox_popover_url_value: @popover_url,
            topbar_inbox_badge_url_value: @badge_url }.compact
        end
      end
    end
  end
end
