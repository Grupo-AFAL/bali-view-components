# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      delegate :icon_tag, to: :helpers

      renders_many :tabs, 'TabComponent'

      def initialize(**options)
        @options = options
        @class = options.delete(:class)
      end

      def classes
        class_names('tabs', @class)
      end

      class TabComponent < ViewComponent::Base
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
