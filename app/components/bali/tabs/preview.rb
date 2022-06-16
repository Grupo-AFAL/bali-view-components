# frozen_string_literal: true

module Bali
  module Tabs
    class Preview < ApplicationViewComponentPreview
      # Tabs
      # ----
      # Use the default tabs component whenever you need to display tabs.
      def default
        render(Tabs::Component.new) do |c|
          c.tab(title: 'Tab 1', active: true) do
            tag.p('Tab one content')
          end

          c.tab(title: 'Tab 2') do
            tag.p('Tab two content')
          end

          c.tab(title: 'Tab 3') do
            tag.p('Tab three content')
          end
        end
      end

      # Tabs with icon
      # --------------
      # Add an icon to make it easier to identify the tab.
      # (Title is also optional)
      def with_icons
        render(Tabs::Component.new) do |c|
          c.tab(title: 'Tab 1', active: true, icon: 'poo') do
            tag.p('Tab with icon')
          end

          c.tab(icon: 'report') do
            tag.p('Tab with another icon')
          end
        end
      end

      # Tabs with custom class
      # ----------------------
      # Add a custom class to the tabs component whenever you need to customize it.
      # @param _class select [is-centered, is-right, is-small, is-medium, is-large, is-boxed, is-toggle, is-toggle is-toggle-rounded, is-fullwidth]
      def with_custom_class(_class: 'is-centered')
        render(Tabs::Component.new(class: _class)) do |c|
          c.tab(title: 'Tab 1', active: true) do
            tag.p('Tab one content')
          end

          c.tab(title: 'Tab 2') do
            tag.p('Tab two content')
          end

          c.tab(title: 'Tab 3') do
            tag.p('Tab three content')
          end
        end
      end

      # Tabs with on demand content
      # ---------------------------
      # Set a hyperlink to the tab, to load it's content on demand.
      # @param src url
      # @param reload_on_click toggle
      def on_demand_content(src: 'https://dog.ceo/api/breeds/image/random', reload_on_click: false)
        render(Tabs::Component.new) do |c|
          c.tab(title: 'Tab 1', src: src, reload_on_click: reload_on_click, active: true)
          c.tab(title: 'Tab 2', src: src, reload_on_click: reload_on_click)
          c.tab(title: 'Tab 3', src: src, reload_on_click: reload_on_click)
        end
      end
    end
  end
end
