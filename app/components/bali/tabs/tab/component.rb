# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        attr_reader :active, :icon, :title, :href, :options

        # @param active [Boolean] Whether the tab is active
        # @param icon [String] The name of the icon to use
        # @param title [String] The title of the tab
        # @param href [String] Hyperlink to the tab content
        def initialize(active: false, icon: nil, title: '', href: nil, **options)
          @active = active
          @href = href
          @icon = icon
          @title = title

          @options = options
          @options = prepend_class_name(@options, 'is-hidden') unless @active
        end

        def call
          content
        end
      end
    end
  end
end
