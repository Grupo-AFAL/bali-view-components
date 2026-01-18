# frozen_string_literal: true

module Bali
  module Tabs
    module Trigger
      class Component < ApplicationViewComponent
        def initialize(tab, index = 0)
          @index = index
          @icon = tab.icon
          @title = tab.title
          @reload = tab.reload
          @active = tab.active
          @src = tab.src
          @href = tab.href
        end

        private

        attr_reader :index, :href, :icon, :title, :src, :reload, :active

        def trigger_attributes
          base = {
            role: 'tab',
            id: "tab-#{index}",
            class: classes
          }

          if href.present?
            # Full page navigation - regular link behavior
            base.merge(
              href: href,
              'aria-selected': active_path?(request.fullpath, href)
            )
          else
            # Client-side tab switching
            base.merge(
              'aria-selected': active,
              'aria-controls': "tabpanel-#{index}",
              tabindex: active ? 0 : -1,
              data: {
                'tabs-target': 'tab',
                'tabs-index-param': index,
                'tabs-src-param': src,
                'tabs-reload-param': reload,
                action: 'click->tabs#open'
              }
            )
          end
        end

        def classes
          class_names(
            'tab',
            'tab-active' => (href.present? ? active_path?(request.fullpath, href) : active)
          )
        end
      end
    end
  end
end
