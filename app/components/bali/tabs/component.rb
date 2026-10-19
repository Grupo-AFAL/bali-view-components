# frozen_string_literal: true

module Bali
  module Tabs
    # Two components share this name because they share a look, and only one of
    # them is a tab set.
    #
    # Tabs with panels are the ARIA tabs pattern: `role="tablist"`, `role="tab"`,
    # `role="tabpanel"`, and a Stimulus controller that swaps which panel is
    # visible without leaving the page.
    #
    # Tabs with `href:` navigate. Nothing about them is a tab — the click leaves
    # the document, there is no panel to control, and `role="tab"` with no
    # `aria-controls` is a promise the markup cannot keep. Those render a `<nav>`
    # with `aria-current="page"`, which is what a screen reader user needs: a set
    # of links, one of which is where they already are.
    class Component < ApplicationViewComponent
      STYLES = {
        default: "",
        border: "tabs-border",
        box: "tabs-box",
        lift: "tabs-lift"
      }.freeze

      SIZES = {
        xs: "tabs-xs",
        sm: "tabs-sm",
        md: "",
        lg: "tabs-lg",
        xl: "tabs-xl"
      }.freeze

      renders_many :tabs, Tab::Component

      # @param style [Symbol] One of STYLES
      # @param size [Symbol] One of SIZES
      # @param label [String, nil] Accessible name of the `<nav>` in navigation
      #   mode. Two navs on one page need telling apart; pass it whenever there
      #   is more than one. Ignored when the tabs have panels.
      # @param id_prefix [String, nil] Prefix for the tab and panel ids
      #   (`<prefix>-tab-0`, `<prefix>-tabpanel-0`). Two sets of panel tabs on one
      #   page need one each, or the second set's `aria-controls` names the first
      #   set's panels. Without it the ids are `tab-0` and `tabpanel-0`.
      def initialize(style: :border, size: :md, label: nil, id_prefix: nil, **options)
        @style = style&.to_sym
        @size = size&.to_sym
        @label = label
        @id_prefix = id_prefix
        @options = prepend_class_name(options, "tabs-component")
      end

      def tab_id(index) = [ @id_prefix, "tab-#{index}" ].compact.join("-")

      def panel_id(index) = [ @id_prefix, "tabpanel-#{index}" ].compact.join("-")

      def before_render
        reject_mixed_triggers!
      end

      # Empty is not navigation: with no tabs there is nothing to navigate, and
      # the tab branch keeps rendering the same empty tablist it always did.
      def navigation?
        tabs.any? && tabs.all? { |tab| tab.href.present? }
      end

      def nav_label
        @label || I18n.t("bali_view.tabs.navigation")
      end

      private

      attr_reader :options

      # The two modes cannot be interleaved: half the triggers would be links
      # leaving the page and half would be tabs controlling panels, inside one
      # `role="tablist"` where every child claims to be a tab. Nothing in ARIA
      # describes that, and it used to render without a word.
      def reject_mixed_triggers!
        return unless tabs.any? { |tab| tab.href.present? }
        return if tabs.all? { |tab| tab.href.present? }

        raise ArgumentError,
              "#{self.class}: cannot mix tabs that navigate (`href:`) with tabs that own " \
              "a panel in the same component. Give every tab an `href:` to render a <nav> " \
              "of links, or drop `href:` from all of them — `src:` is the way to have a " \
              "panel load its content on demand without leaving the page."
      end

      def container_attributes
        return options if navigation?

        prepend_values(prepend_controller(detach_data(options), "tabs"), "tabs", translations: translations_json)
      end

      # What tabs/index.js writes into a panel whose `src:` failed to load.
      def translations_json
        { load_failed: I18n.t("bali_view.tabs.load_failed") }.to_json
      end

      def tabs_classes
        class_names(
          "tabs",
          STYLES.fetch(@style, ""),
          SIZES.fetch(@size, "")
        )
      end
    end
  end
end
