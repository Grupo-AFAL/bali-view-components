# frozen_string_literal: true

module Bali
  module ViewSwitch
    class Preview < ApplicationViewComponentPreview
      # Icon + label (the AFAL default — more discoverable), two views.
      # `active:` is autodetected from the current URL when omitted; previews
      # pass it explicitly because Lookbook renders under /lookbook.
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def default(size: :sm)
        render ViewSwitch::Component.new(aria_label: "Views", size: size) do |switch|
          switch.with_view(name: "List", icon: "list", href: "/lookbook", active: true)
          switch.with_view(name: "Board", icon: "grid", href: "/lookbook?view=board")
        end
      end

      # Three views (e.g. a project plan: tree / board / schedule).
      def three_views
        render ViewSwitch::Component.new(aria_label: "Views") do |switch|
          switch.with_view(name: "Plan", icon: "list", href: "/lookbook")
          switch.with_view(name: "Board", icon: "grid", href: "/lookbook?view=board", active: true)
          switch.with_view(name: "Schedule", icon: "calendar", href: "/lookbook?view=schedule")
        end
      end

      # Compact icon-only mode for spots that compete for space (tabs row,
      # DataTable toolbar). The name becomes the native tooltip (title) and
      # the accessible label. Shows two- and three-view groups.
      def icon_only
        render_with_template
      end

      # Views accept extra HTML options, e.g. data: { turbo_action: 'replace' }
      # so switching views replaces (not pushes) the history entry.
      def with_turbo_action
        render ViewSwitch::Component.new(aria_label: "Views") do |switch|
          switch.with_view(name: "List", icon: "list", href: "/lookbook",
                           active: true, data: { turbo_action: "replace" })
          switch.with_view(name: "Board", icon: "grid", href: "/lookbook?view=board",
                           data: { turbo_action: "replace" })
        end
      end
    end
  end
end
