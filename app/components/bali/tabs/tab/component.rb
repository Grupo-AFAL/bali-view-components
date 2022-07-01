# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        attr_reader :active, :icon, :title, :src, :reload, :navigation_action, :options

        # @param active [Boolean] Whether the tab is active
        # @param icon [String] The name of the icon to use
        # @param title [String] The title of the tab
        # @param src [String] Hyperlink to the tab content
        # @param reload [Boolean] Whether the tab content should be reloaded
        #                             when the tab is clicked
        def initialize(
          active: false, icon: nil, title: '', src: nil, reload: false, **options
        )
          @active = active
          @icon = icon
          @title = title
          @src = src
          @reload = reload
          @navigation_action = options.delete(:navigation_action)

          @options = options
          @options = prepend_class_name(@options, 'is-hidden') unless @active
        end

        def trigger(index = 0)
          tag.li(data: trigger_li_data(index), class: trigger_li_classes) do
            tag.a(**trigger_a_options) do
              safe_join([
                          icon ? render(Bali::Icon::Component.new(icon)) : nil,
                          tag.span { title }
                        ])
            end
          end
        end

        def call
          content
        end

        private

        def navigation_advance?
          navigation_action == :advance
        end

        def trigger_li_data(index)
          return {} if navigation_advance?

          {
            'tabs-target': 'tab',
            'tabs-index-param': index,
            'tabs-src-param': src,
            'tabs-reload-param': reload,
            action: 'click->tabs#open'
          }
        end

        def trigger_li_classes
          return class_names('is-active': active) unless navigation_advance?

         
          class_names('is-active': active_path?(request.fullpath, src))
        end

        def trigger_a_options
          return { href: src } if navigation_advance?

          {}
        end
      end
    end
  end
end
