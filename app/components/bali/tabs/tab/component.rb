# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        attr_reader :active, :icon, :title, :src, :reload, :options, :href

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
          @href = options.delete(:href)

          @options = options
          @options = prepend_class_name(@options, 'hidden') unless @active
        end

        def call
          content
        end
      end
    end
  end
end
