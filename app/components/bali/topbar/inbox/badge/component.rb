# frozen_string_literal: true

module Bali
  module Topbar
    module Inbox
      module Badge
        # What goes inside the icon's badge frame — and what the `badge` action answers with, so
        # a refresh redraws the number, the dot and the link's name together. The name is the
        # sr-only text: the pill and the dot only repeat it for the eye.
        class Component < ApplicationViewComponent
          DOT_CLASSES = "bali-topbar-inbox-dot"

          # @param badge [Bali::Inbox::Badge]
          def initialize(badge:)
            @badge = badge
          end

          def call
            safe_join([ tag.span(label, class: "sr-only"), count_pill, dot ].compact)
          end

          private

          def label
            pending = @badge.pending
            if pending.positive? && @badge.unread?
              t("bali_view.inbox.icon.pending_and_unread", count: pending)
            elsif pending.positive?
              t("bali_view.inbox.icon.pending", count: pending)
            elsif @badge.unread?
              t("bali_view.inbox.icon.unread")
            else
              t("bali_view.inbox.title")
            end
          end

          def count_pill
            return unless @badge.pending.positive?

            max = Bali::Topbar::IconAction::Component::MAX_COUNT
            text = @badge.pending > max ? "#{max}+" : @badge.pending.to_s
            pill = render(Bali::Tag::Component.new(text: text, color: :error, size: :xs))
            tag.span(pill, class: Bali::Topbar::IconAction::Component::COUNT_CLASSES, "aria-hidden": true)
          end

          def dot
            tag.span(class: DOT_CLASSES, "aria-hidden": true) if @badge.unread?
          end
        end
      end
    end
  end
end
