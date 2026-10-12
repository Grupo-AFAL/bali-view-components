# frozen_string_literal: true

module Bali
  module Tabs
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Tabs
      # ----
      # Use the default tabs component whenever you need to display tabs.
      # @param style [Symbol] select [default, border, box, lift]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def default(style: :border, size: :md)
        render(Tabs::Component.new(style: style, size: size)) do |c|
          c.with_tab(title: 'Tab 1', active: true) do
            tag.p('Tab one content')
          end

          c.with_tab(title: 'Tab 2') do
            tag.p('Tab two content')
          end

          c.with_tab(title: 'Tab 3') do
            tag.p('Tab three content')
          end
        end
      end

      # Tabs with icon
      # --------------
      # Add an icon to make it easier to identify the tab.
      # @param style [Symbol] select [default, border, box, lift]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def with_icons(style: :lift, size: :md)
        render(Tabs::Component.new(style: style, size: size)) do |c|
          c.with_tab(title: 'Tab 1', active: true, icon: 'home') do
            tag.p('Tab with icon')
          end

          c.with_tab(title: 'Tab 2', icon: 'file') do
            tag.p('Tab with another icon')
          end
        end
      end

      # @!endgroup

      # @!group Styles

      # Border Style
      # ---------------
      # Tabs with bottom border style
      def border_style
        render(Tabs::Component.new(style: :border)) do |c|
          c.with_tab(title: 'Tab 1', active: true) { tag.p('Border style content') }
          c.with_tab(title: 'Tab 2') { tag.p('Tab 2') }
          c.with_tab(title: 'Tab 3') { tag.p('Tab 3') }
        end
      end

      # Box Style
      # ---------------
      # Tabs with box container style
      def box_style
        render(Tabs::Component.new(style: :box)) do |c|
          c.with_tab(title: 'Tab 1', active: true) { tag.p('Box style content') }
          c.with_tab(title: 'Tab 2') { tag.p('Tab 2') }
          c.with_tab(title: 'Tab 3') { tag.p('Tab 3') }
        end
      end

      # Lift Style
      # ---------------
      # Tabs with elevated/floating style
      def lift_style
        render(Tabs::Component.new(style: :lift)) do |c|
          c.with_tab(title: 'Tab 1', active: true) { tag.p('Lift style content') }
          c.with_tab(title: 'Tab 2') { tag.p('Tab 2') }
          c.with_tab(title: 'Tab 3') { tag.p('Tab 3') }
        end
      end

      # @!endgroup

      # @!group On Demand

      # Tabs with on demand content
      # ---------------------------
      # Set a hyperlink to the tab, to load its content on demand.
      # @param reload toggle
      def on_demand_content(reload: false)
        render(Tabs::Component.new(style: :border)) do |c|
          c.with_tab(title: 'Tab 1', src: '/tab1', reload: reload, active: true)
          c.with_tab(title: 'Tab 2', src: '/tab2', reload: reload)
          c.with_tab(title: 'Tab 3', src: '/tab3', reload: reload)
        end
      end

      # Tabs with full page reload
      # ---------------------------
      # Set a hyperlink to the tab for full page navigation.
      def full_page_reload
        render(Tabs::Component.new(style: :border)) do |c|
          c.with_tab(title: 'Tab 1', href: '/tab1')
          c.with_tab(title: 'Tab 2', href: '/tab2')
          c.with_tab(title: 'Tab 3', href: '/tab3')
        end
      end

      # @!endgroup

      # @!group Navigation

      # Navigation with counters
      # ------------------------
      # The scopes pattern: tabs that navigate between filtered views of the
      # same listing (Mine / Team, statuses), each showing how many records
      # wait behind it. `count:` renders a badge after the title — `0` renders
      # too, an empty scope is information. Every link carries
      # `data-turbo-action="advance"` by default.
      #
      # A count is sometimes an alarm, not just an amount: `count_color:` takes
      # the same semantic table every other `color:` does, so "2 blocked" can
      # look like the warning it is while "12 mine" stays neutral.
      # @param style [Symbol] select [default, border, box, lift]
      def navigation_with_counts(style: :border)
        render(Bali::Tabs::Component.new(style: style, label: 'Inbox scopes')) do |c|
          c.with_tab(title: 'Mine', count: 12, href: '/tab1', active: true)
          c.with_tab(title: 'Blocked', count: 2, count_color: :warning, href: '/tab2')
          c.with_tab(title: 'Done', count: 0, href: '/tab3')
        end
      end

      # Tabs with panels and counters
      # -----------------------------
      # `count:` renders in panel mode too, with the same badge, and
      # `count_color:` paints it there as well.
      def panels_with_counts
        render(Bali::Tabs::Component.new(style: :border)) do |c|
          c.with_tab(title: 'Open', count: 7, active: true) { tag.p('Seven open items') }
          c.with_tab(title: 'Overdue', count: 3, count_color: :error) { tag.p('Three overdue items') }
          c.with_tab(title: 'Closed', count: 42) { tag.p('Forty-two closed items') }
        end
      end

      # @!endgroup
    end
  end
end
