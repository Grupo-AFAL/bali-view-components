# frozen_string_literal: true

module Bali
  module AppLayout
    class Preview < ApplicationViewComponentPreview
      # @label Sidebar + Content
      # Config A: Admin layout with sidebar and content area.
      # In production, use `fixed: true` on the SideMenu and `fixed_sidebar: true` on AppLayout.
      # @param collapsible toggle
      # @param flash_notice text
      # @param modal toggle
      # @param drawer toggle
      def default(collapsible: true, flash_notice: "", modal: true, drawer: true)
        render_with_template(
          template: "bali/app_layout/previews/default",
          locals: {
            collapsible: collapsible,
            flash_notice: flash_notice.presence,
            modal: modal,
            drawer: drawer ? { size: :lg } : false
          }
        )
      end

      # @label Navbar + Sidebar + Content
      # Config B: Full admin with top navbar, optional impersonation banner, sidebar, and content.
      # @param collapsible toggle
      # @param show_banner toggle
      # @param flash_notice text
      # @param modal toggle
      # @param drawer toggle
      def with_navbar(collapsible: true, show_banner: false, flash_notice: "", modal: true, drawer: true)
        render_with_template(
          template: "bali/app_layout/previews/with_navbar",
          locals: {
            collapsible: collapsible,
            show_banner: show_banner,
            flash_notice: flash_notice.presence,
            modal: modal,
            drawer: drawer ? { size: :lg } : false
          }
        )
      end

      # @label Navbar + Content
      # Config C: Public/marketing layout with top navbar and full-width content.
      # @param flash_notice text
      def navbar_only(flash_notice: "")
        render_with_template(
          template: "bali/app_layout/previews/navbar_only",
          locals: {
            flash_notice: flash_notice.presence
          }
        )
      end

      # @label Content Only
      # Config D: Minimal layout for login, error, or onboarding pages.
      # @param flash_notice text
      def content_only(flash_notice: "")
        render_with_template(
          template: "bali/app_layout/previews/content_only",
          locals: {
            flash_notice: flash_notice.presence
          }
        )
      end
    end
  end
end
