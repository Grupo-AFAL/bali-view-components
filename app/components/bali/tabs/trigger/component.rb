# frozen_string_literal: true

module Bali
  module Tabs
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :index, :href, :icon, :title, :src, :reload, :options, :active

        def initialize(
          index = 0, icon: nil, title: '', reload: false, active: false, **options
        )
          @index = index
          @icon = icon
          @title = title
          @reload = reload
          @active = active
          @src = options.delete(:src)
          @href = options.delete(:href)
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
            'tabs-trigger-component',
            'is-active': href.present? ? active_path?(request.fullpath, href) : active
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
