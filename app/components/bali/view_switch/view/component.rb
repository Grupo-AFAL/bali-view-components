# frozen_string_literal: true

module Bali
  module ViewSwitch
    module View
      class Component < ApplicationViewComponent
        SIZES = {
          xs: "btn-xs",
          sm: "btn-sm",
          md: "",
          lg: "btn-lg",
          xl: "btn-xl"
        }.freeze

        # `aria-current` value per parent mode: the active view of a navigation
        # switch IS the current page; the active view of a selector is only the
        # current item of its set.
        ARIA_CURRENT = {
          navigation: "page",
          selector: "true"
        }.freeze

        # @param name [String] Label of the view (visible text, or the native
        #   tooltip + accessible label when the parent is icon_only)
        # @param icon [String, nil] Icon name rendered before the label; nil renders
        #   a text-only view (the norm in `mode: :selector`, where the options are
        #   values — "12 months", "Optimistic" — not views with an iconography)
        # @param href [String] Path this view links to
        # @param active [Boolean, nil] Explicit active state; when nil (default)
        #   it is autodetected by matching the request path against href
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, icon: nil, href:, active: nil, icon_only: false, size: :sm,
                       mode: :navigation, **options)
          @name = name
          @icon = icon
          @href = href
          @active = active
          @icon_only = icon_only
          @size = size&.to_sym
          @mode = mode&.to_sym
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        private

        attr_reader :name, :icon, :href, :options

        def icon_only?
          @icon_only == true
        end

        # `:responsive` collapses the text through CSS below sm, but emits title/aria-label
        # ALWAYS: hiding the label with a bare `max-sm:hidden` would leave a button with no
        # accessible name in exactly the viewport where only the icon shows.
        def responsive_icon_only?
          @icon_only == :responsive
        end

        def active?
          return @active unless @active.nil?

          active_path?(request.fullpath, href)
        end

        # `aria-current` and not `aria-pressed`: this is an `<a>` that NAVIGATES (role=link)
        # and the browser discards `pressed` on a link — the active mode was expressed by
        # color alone and the three links sounded identical ("Table, link / Cards, link").
        # `aria-current` is a global attribute, allowed on any role. It also applies to
        # `mode: :selector` (still a link that navigates): what changes is the VALUE
        # (`"true"`, the current item of a set) because the active option of a scoping
        # selector is not "the current page".
        def link_attributes
          attrs = options.except(:class).merge(class: link_classes)
          attrs[:"aria-current"] = ARIA_CURRENT.fetch(@mode, "page") if active?

          if icon_only? || responsive_icon_only?
            attrs[:title] ||= name
            attrs[:"aria-label"] ||= name
          end

          attrs
        end

        def link_classes
          class_names(
            "btn",
            "join-item",
            SIZES.fetch(@size, ""),
            icon_only? ? "btn-square" : "gap-1.5",
            ("max-sm:btn-square" if responsive_icon_only?),
            active? ? "btn-active btn-primary" : "btn-outline",
            options[:class]
          )
        end
      end
    end
  end
end
