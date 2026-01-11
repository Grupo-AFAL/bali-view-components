# frozen_string_literal: true

module Bali
  module Tabs
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :index, :href, :icon, :title, :src, :reload, :active

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

        def data
          return {} if href.present?

          {
            'tabs-target': 'tab',
            'tabs-index-param': index,
            'tabs-src-param': src,
            'tabs-reload-param': reload,
            action: 'click->tabs#open'
          }
        end

        def classes
          class_names(
            'tab',
            'tab-active': href.present? ? active_path?(request.fullpath, href) : active
          )
        end

        def link_options
          return { href: href } if href.present?

          {}
        end
      end
    end
  end
end
