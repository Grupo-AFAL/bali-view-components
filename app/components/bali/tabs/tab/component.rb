module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        attr_reader :title, :icon, :active

        def initialize(title:, icon: nil, active: false)
          @title = title
          @icon = icon
          @active = active
        end

        def call
          content
        end
      end
    end
  end
end
