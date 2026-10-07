# frozen_string_literal: true

module Bali
  module Topbar
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Topbar with all four zones populated: search, two icon actions, and a
      # user dropdown.
      def default
        render_with_template(template: "bali/topbar/previews/default")
      end

      # @label Search Only
      # Minimal topbar with just a global search input.
      def search_only
        render_with_template(template: "bali/topbar/previews/search_only")
      end

      # @label Without Search
      # Topbar without a search input — actions and user menu only.
      def without_search
        render_with_template(template: "bali/topbar/previews/without_search")
      end

      # @label Without Mobile Trigger
      # Topbar for layouts that have no sidebar: pass `menu_id: nil` and no hamburger renders.
      def without_mobile_trigger
        render_with_template(template: "bali/topbar/previews/without_mobile_trigger")
      end

      # @label User Menu
      # The prefabricated user dropdown (`Bali::Topbar::UserMenu::Component`) for the
      # `with_user_menu` slot: avatar (photo, or initials with a deterministic colour),
      # name/email header, your items, and a sign-out entry.
      #
      # `sign_out:` has **no default route** — the item only renders when you pass
      # `sign_out: { href: ... }` (`method:` defaults to `:delete` and submits a real
      # form). With bali-auth: `sign_out: { href: bali_auth.sign_out_path }`.
      def user_menu
        render_with_template(template: "bali/topbar/previews/user_menu")
      end

      # @label Icon Actions
      # `Bali::Topbar::IconAction::Component` — one icon button for the `with_action`
      # slot. `badge: true` draws the dot, a number draws a count pill, and `badge_id:`
      # names the indicator `<span>` so the host can `turbo_stream.replace` it (the
      # component brings no polling and no channel — only the target).
      def icon_actions
        render_with_template(template: "bali/topbar/previews/icon_actions")
      end

      # @label Six Actions
      # A full bar: the Command palette's trigger in the search slot, then Opina, inbox,
      # help, tools, notifications and the user menu. Narrow the viewport to see the search
      # fold down to its icon when the actions leave it no room.
      def six_actions
        render_with_template(template: "bali/topbar/previews/six_actions")
      end

      # @label Tools Menu
      # Topbar with the internal tools menu: a mounted tool that brings its own chrome (new
      # tab), a mounted tool that keeps the host chrome (same tab), a second one with its own
      # chrome, and an external link.
      def tools_menu
        render_with_template(template: "bali/topbar/previews/tools_menu")
      end
    end
  end
end
