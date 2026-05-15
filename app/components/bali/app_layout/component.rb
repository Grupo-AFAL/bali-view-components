# frozen_string_literal: true

module Bali
  module AppLayout
    # Renders the <body> element directly. Intended for use in layout files
    # between <head> and </html>. Do NOT nest inside another <body> tag.
    class Component < ApplicationViewComponent
      renders_one :banner
      renders_one :navbar
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      BODY_CONTAINERS = {
        wide:      "p-4 md:p-6",
        contained: "max-w-7xl px-4 md:px-6 py-4 mx-auto",
        narrow:    "max-w-xl px-4 py-4 mx-auto",
        full:      ""
      }.freeze

      # @param viewport_locked [Boolean, nil] When true, the layout locks to viewport
      #   height and only the inner <main> scrolls (Linear/Notion app-shell pattern).
      #   When false, the page scrolls naturally and the topbar scrolls with content.
      #   When nil (default), follows `fixed_sidebar` — the typical app-shell wants both,
      #   but you can decouple them, e.g. `fixed_sidebar: true, viewport_locked: false`
      #   for a fixed sidebar with normal page scroll (long forms, marketing-style content).
      # @param app_name [String, nil] Title shown next to the hamburger in the
      #   auto-rendered mobile topbar. Only used when `fixed_sidebar:` is true,
      #   a sidebar is present, and no `topbar` slot was provided.
      def initialize(fixed_sidebar: false, viewport_locked: nil,
                     flash: nil, modal: true, drawer: true,
                     modal_size: nil, drawer_size: nil,
                     body_container: :wide, app_name: nil, **options)
        @fixed_sidebar = fixed_sidebar
        @viewport_locked = viewport_locked.nil? ? fixed_sidebar : viewport_locked
        @flash = flash
        @modal = modal
        @drawer = drawer
        @modal_size = modal_size
        @drawer_size = drawer_size
        @body_container = body_container
        @app_name = app_name
        @options = options
      end

      private

      # Auto-render a mobile-only topbar (hamburger + optional app name) when the
      # consumer pinned the sidebar but didn't supply their own topbar — without
      # this fallback, the sidebar is unreachable on mobile.
      def render_default_mobile_topbar?
        @fixed_sidebar && sidebar? && !topbar?
      end

      def default_mobile_trigger_id
        Bali::SideMenu::Component::MOBILE_TRIGGER_ID
      end

      def toggle_mobile_label
        I18n.t("bali.side_menu.toggle_mobile", default: "Toggle sidebar")
      end

      def container_classes
        class_names(
          "app-layout",
          "flex flex-col",
          "min-h-screen",
          "bg-base-200",
          { "app-layout--has-fixed-sidebar" => @fixed_sidebar && sidebar? },
          { "app-layout--has-navbar" => navbar? },
          { "app-layout--has-sidebar" => sidebar? },
          { "app-layout--viewport-locked" => @viewport_locked },
          @options[:class]
        )
      end

      def container_attributes
        @options.except(:class)
      end

      def render_toast?
        flash_notice.present? || flash_alert.present?
      end

      def body_container_classes
        class_names(
          "app-layout-body-container",
          BODY_CONTAINERS.fetch(@body_container)
        )
      end

      def main_attributes
        controllers = []
        controllers << "modal" if @modal
        controllers << "drawer" if @drawer
        return {} if controllers.empty?

        { data: { controller: controllers.join(" ") } }
      end

      def flash_notice
        @flash && @flash[:notice]
      end

      def flash_alert
        @flash && @flash[:alert]
      end
    end
  end
end
