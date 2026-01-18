# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        # Public accessors needed by Trigger::Component
        attr_reader :active, :icon, :title, :src, :reload, :href, :options

        # @param active [Boolean] Whether the tab is active
        # @param icon [String] The name of the icon to use
        # @param title [String] The title of the tab
        # @param src [String] Hyperlink to the tab content
        # @param reload [Boolean] Whether the tab content should be reloaded
        #                             when the tab is clicked
        # @param href [String] Full page navigation URL (mutually exclusive with src)
        # rubocop:disable Metrics/ParameterLists
        def initialize(active: false, icon: nil, title: '', src: nil, reload: false, href: nil,
                       **options)
          @active = active
          @icon = icon
          @title = title
          @src = src
          @reload = reload
          @href = href

          @options = options.except(:href)
          @options = prepend_class_name(@options, 'hidden') unless @active
        end
        # rubocop:enable Metrics/ParameterLists

        def call
          content
        end
      end
    end
  end
end
