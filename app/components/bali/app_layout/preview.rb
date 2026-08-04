# frozen_string_literal: true

module Bali
  module AppLayout
    class Preview < ApplicationViewComponentPreview
      layout "app_layout_preview"
      # @label Sidebar + Content
      # Config A: Admin layout with sidebar and content area.
      # In production, use `fixed: true` on the SideMenu and `fixed_sidebar: true` on AppLayout.
      # On mobile (lg breakpoint), AppLayout auto-renders a hamburger topbar so the
      # sidebar stays reachable — set `app_name:` to label it.
      # @param collapsible toggle
      # @param flash_notice text
      # @param modal toggle
      # @param drawer toggle
      # @param body_container select { choices: [wide, contained, narrow, full] }
      # @param app_name text
      def default(collapsible: true, flash_notice: "", modal: true, drawer: true,
                  body_container: "wide", app_name: "MovieDB")
        render_with_template(
          template: "bali/app_layout/previews/default",
          locals: {
            collapsible: collapsible,
            flash_notice: flash_notice.presence,
            modal: modal,
            drawer: drawer,
            drawer_size: drawer ? :lg : nil,
            body_container: body_container.to_sym,
            app_name: app_name.presence
          }
        )
      end

      # @label Topbar + Sidebar + Content
      # Config B: Full admin — sidebar as THE navigation, and a Bali::Topbar over the
      # content column as the account bar (search, notifications, user menu), plus an
      # optional impersonation banner. Topbar and not Navbar: with the sidebar carrying
      # the destinations, the top strip is chrome (a `<header>`/banner), not a second
      # `<nav>` landmark. When the top bar IS the navigation, that is the
      # "Navbar + Content" scenario.
      # @param collapsible toggle
      # @param show_banner toggle
      # @param flash_notice text
      # @param modal toggle
      # @param drawer toggle
      # @param body_container select { choices: [wide, contained, narrow, full] }
      def with_topbar(collapsible: true, show_banner: false, flash_notice: "", modal: true, drawer: true, body_container: "wide")
        render_with_template(
          template: "bali/app_layout/previews/with_topbar",
          locals: {
            collapsible: collapsible,
            show_banner: show_banner,
            flash_notice: flash_notice.presence,
            modal: modal,
            drawer: drawer,
            drawer_size: drawer ? :lg : nil,
            body_container: body_container.to_sym
          }
        )
      end

      # @label Navbar + Content
      # Config C: Public/marketing layout with top navbar and full-width content —
      # the layout where the top bar IS the navigation, which is what makes Navbar
      # (a `<nav>`) the right component here and Topbar the right one in Config B.
      # @param flash_notice text
      # @param body_container select { choices: [contained, wide, narrow, full] }
      def navbar_only(flash_notice: "", body_container: "contained")
        render_with_template(
          template: "bali/app_layout/previews/navbar_only",
          locals: {
            flash_notice: flash_notice.presence,
            body_container: body_container.to_sym
          }
        )
      end

      # @label Content Only
      # Config D: Minimal layout without sidebar or navbar. Useful for settings, onboarding, or standalone pages.
      # @param flash_notice text
      # @param body_container select { choices: [narrow, contained, wide, full] }
      def content_only(flash_notice: "", body_container: "narrow")
        render_with_template(
          template: "bali/app_layout/previews/content_only",
          locals: {
            flash_notice: flash_notice.presence,
            body_container: body_container.to_sym
          }
        )
      end

      # @label Login Page
      # Config D reference: a realistic login page using content-only layout with Bali components.
      # @param flash_notice text
      def login(flash_notice: "")
        render_with_template(
          template: "bali/app_layout/previews/login",
          locals: {
            flash_notice: flash_notice.presence
          }
        )
      end

      # @label Registration Page
      # Config D reference: a realistic registration page using content-only layout with Bali components.
      # @param flash_notice text
      def register(flash_notice: "")
        render_with_template(
          template: "bali/app_layout/previews/register",
          locals: {
            flash_notice: flash_notice.presence
          }
        )
      end
    end
  end
end
