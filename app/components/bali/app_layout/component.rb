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

      # Target of the skip link. Also the id of <main>, which carries
      # `tabindex="-1"` so the jump actually moves focus and the next Tab
      # continues inside the content instead of restarting at the top.
      MAIN_ID = "main-content"

      # @param fixed_sidebar [Boolean] Sidebar is pinned to the viewport and the content
      #   is offset to clear it. Must agree with the `fixed:` of the SideMenu rendered in
      #   the slot — they share a default (both true) and a mismatch raises in development.
      # @param viewport_locked [Boolean, nil] When true, the layout locks to viewport
      #   height and only the inner <main> scrolls (Linear/Notion app-shell pattern).
      #   When false, the page scrolls naturally and the topbar scrolls with content.
      #   When nil (default), follows the *effective* fixed sidebar — the typical app-shell
      #   wants both — but you can decouple them, e.g. `fixed_sidebar: true,
      #   viewport_locked: false` for a fixed sidebar with normal page scroll (long forms,
      #   marketing-style content).
      # @param skip_link [Boolean] Render the "skip to main content" link as the first
      #   focusable element of the page.
      # @param app_name [String, nil] Title shown next to the hamburger in the
      #   auto-rendered mobile topbar. Only used when `fixed_sidebar:` is true,
      #   a sidebar is present, and no `topbar` slot was provided.
      def initialize(fixed_sidebar: true, viewport_locked: nil,
                     flash: nil, modal: true, drawer: true,
                     modal_size: nil, drawer_size: nil,
                     body_container: :wide, app_name: nil, skip_link: true,
                     **options)
        @fixed_sidebar = fixed_sidebar
        @viewport_locked = viewport_locked
        @flash = flash
        @modal = modal
        @drawer = drawer
        @modal_size = modal_size
        @drawer_size = drawer_size
        @body_container = body_container
        @app_name = app_name
        @skip_link = skip_link
        @options = options
      end

      private

      # `fixed_sidebar: true` only means something once a sidebar is actually in
      # the slot. Everything downstream — the content offset, the default scroll
      # model, the mobile hamburger — keys off this, not off the raw flag, so a
      # layout with no sidebar is unaffected by the parameter's default.
      def fixed_sidebar?
        @fixed_sidebar && sidebar?
      end

      def viewport_locked?
        @viewport_locked.nil? ? fixed_sidebar? : @viewport_locked
      end

      # Auto-render a mobile-only topbar (hamburger + optional app name) when the
      # consumer pinned the sidebar but didn't supply their own topbar — without
      # this fallback, the sidebar is unreachable on mobile.
      def render_default_mobile_topbar?
        fixed_sidebar? && !topbar?
      end

      def render_skip_link?
        @skip_link
      end

      def main_id
        MAIN_ID
      end

      def skip_link_label
        I18n.t("bali_view.app_layout.skip_to_content")
      end

      def default_menu_id
        Bali::SideMenu::Component::DEFAULT_ID
      end

      # Rendered once, then checked against `fixed_sidebar:` before it goes out.
      def sidebar_markup
        @sidebar_markup ||= sidebar.to_s.tap { |markup| check_sidebar_sync!(markup) }
      end

      # A pinned sidebar overlays the content; an inline one takes up flow space.
      # The layout offsets the content for the first and not the second, so the
      # two flags have to agree or the page is either overlapped or padded into
      # a gap — and neither failure says why. The slot takes arbitrary markup
      # (`render 'layouts/admin_sidebar'`), so the only thing AppLayout can read
      # is what the slot rendered; the check therefore stays out of production
      # and stays silent unless it positively identifies a Bali SideMenu.
      def check_sidebar_sync!(markup)
        return unless Rails.env.development? || Rails.env.test?
        return unless markup.include?("side-menu-component")

        sidebar_is_fixed = markup.include?("side-menu-component--fixed")
        return if sidebar_is_fixed == @fixed_sidebar

        raise ArgumentError,
              "Bali::AppLayout::Component was given `fixed_sidebar: #{@fixed_sidebar}` but the " \
              "sidebar slot rendered a Bali::SideMenu::Component with `fixed: #{sidebar_is_fixed}`. " \
              "Both must agree: `fixed_sidebar: true` pins the sidebar to the viewport and offsets " \
              "the content to clear it, `false` leaves it in the document flow."
      end

      def container_classes
        class_names(
          "app-layout",
          "flex flex-col",
          "min-h-screen",
          "bg-base-200",
          { "app-layout--has-fixed-sidebar" => fixed_sidebar? },
          { "app-layout--has-navbar" => navbar? },
          { "app-layout--has-sidebar" => sidebar? },
          { "app-layout--viewport-locked" => viewport_locked? },
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
