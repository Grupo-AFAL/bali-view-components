# frozen_string_literal: true

module Bali
  module Topbar
    module IconAction
      # One icon button for the Topbar's `with_action` slot — the notification
      # bell packaged. A `<button>` by default, an `<a>` when given `href:`,
      # always with an accessible name (`label:` is required: an icon-only
      # control without one has no name at all).
      #
      # The badge is a Turbo-Stream-updatable target and nothing more: pass
      # `badge_id:` and the indicator `<span>` gets that DOM id for the host to
      # `turbo_stream.replace` — the component brings no polling and no channel.
      # With `badge_id:` and no `badge:` it renders the span empty and hidden,
      # so a stream can light it up later without a full re-render.
      class Component < ApplicationViewComponent
        BUTTON_CLASSES = "btn btn-ghost btn-sm btn-square"

        # The bell-dot of the Topbar preview, verbatim: the `border-base-100`
        # ring is what keeps the dot legible over the icon's strokes.
        DOT_CLASSES = "bali-topbar-badge absolute top-1.5 right-1.5 size-2 " \
                      "rounded-full bg-error border-2 border-base-100"

        COUNT_CLASSES = "bali-topbar-badge absolute -top-1 -right-1"

        # @param icon [String, Symbol] icon name (Bali::Icon pipeline).
        # @param label [String] accessible name, e.g. t-ed "Notifications".
        # @param href [String, nil] renders an `<a>` (navigation) instead of a
        #   `<button>` (action) — the Button-vs-Link doctrine, one keyword.
        # @param badge [true, Integer, String, nil] `true` draws the small dot;
        #   a number or string draws a count pill; `nil` draws nothing.
        # @param badge_id [String, nil] DOM id of the indicator span, so a Turbo
        #   Stream can replace it.
        # rubocop:disable Metrics/ParameterLists
        def initialize(icon:, label:, href: nil, badge: nil, badge_id: nil, **options)
          # rubocop:enable Metrics/ParameterLists
          @icon = icon
          @label = label
          @href = href
          @badge = badge
          @badge_id = badge_id
          @options = options
        end

        def call
          inner = safe_join([
                              render(Bali::Icon::Component.new(@icon, class: "size-5")),
                              badge_html
                            ].compact)

          content_tag(tag_name, inner, **root_attributes)
        end

        private

        def tag_name
          @href.present? ? :a : :button
        end

        def root_attributes
          attrs = @options.except(:class)
          attrs[:class] = class_names(BUTTON_CLASSES, ("relative" if badge?), @options[:class])
          attrs[:"aria-label"] ||= @label
          attrs[:title] ||= @label
          @href.present? ? attrs.merge(href: @href) : { type: "button" }.merge(attrs)
        end

        def badge?
          !@badge.nil? || @badge_id.present?
        end

        # The badge is decoration over an already-labelled control: the
        # accessible name is `label:`, so the span stays `aria-hidden` — a host
        # that wants "3 unread" announced puts it in `label:` (or streams it).
        def badge_html
          return unless badge?

          if @badge == true
            tag.span(id: @badge_id, class: DOT_CLASSES, "aria-hidden": true)
          elsif @badge.nil?
            tag.span(id: @badge_id, class: "bali-topbar-badge", hidden: true,
                     "aria-hidden": true)
          else
            # Rendered into a local first — a block that calls `render` itself
            # comes back empty under `capture` (see ActionsDropdown's note).
            pill = render(Bali::Tag::Component.new(text: @badge.to_s, color: :error, size: :xs))
            tag.span(pill, id: @badge_id, class: COUNT_CLASSES, "aria-hidden": true)
          end
        end
      end
    end
  end
end
