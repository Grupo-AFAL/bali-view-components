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
      def with_icons
        render(Tabs::Component.new(style: :lift)) do |c|
          c.with_tab(title: 'Tab 1', active: true, icon: 'poo') do
            tag.p('Tab with icon')
          end

          c.with_tab(icon: 'report') do
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
    end
  end
end
