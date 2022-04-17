# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      delegate :icon_tag, to: :helpers

      renders_many :tabs, Tab::Component

      def initialize(**options)
        @options = options
        @class = options.delete(:class)
      end

      def classes
        class_names('tabs', @class)
      end
    end
  end
end
