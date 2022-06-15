# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      renders_many :tabs, Tab::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'tabs-component tabs')
      end
    end
  end
end
