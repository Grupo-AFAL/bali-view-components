# frozen_string_literal: true

module Bali
  module Tabs
    module Trigger
      class Component < ApplicationViewComponent
        # @param navigation [Boolean] true when the parent renders a `<nav>`
        #   because every tab has an `href:`. The link then carries
        #   `aria-current` instead of the tab roles, which would describe a
        #   widget that is not on the page.
        def initialize(tab, index = 0, navigation: false)
          @index = index
          @navigation = navigation
          @icon = tab.icon
          @title = tab.title
          @reload = tab.reload
          @active = tab.active
          @explicit_active = tab.explicit_active
          @src = tab.src
          @href = tab.href
        end

        private

        attr_reader :index, :href, :icon, :title, :src, :reload, :active, :explicit_active

        def navigation?
          @navigation
        end

        def active?
          if href.present?
            explicit_active ? active : active_path?(request.fullpath, href)
          else
            active
          end
        end

        def trigger_attributes
          navigation? ? navigation_attributes : tab_attributes
        end

        def navigation_attributes
          {
            href: href,
            class: classes,
            'aria-current': active? ? "page" : nil
          }.compact
        end

        def tab_attributes
          {
            role: "tab",
            id: "tab-#{index}",
            class: classes,
            'aria-selected': active,
            'aria-controls': "tabpanel-#{index}",
            tabindex: active ? 0 : -1,
            data: {
              'tabs-target': "tab",
              'tabs-index-param': index,
              'tabs-src-param': src,
              'tabs-reload-param': reload,
              action: "click->tabs#open"
            }
          }
        end

        def classes
          class_names(
            "tab",
            "tab-active" => active?
          )
        end
      end
    end
  end
end
