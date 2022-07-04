# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      renders_many :tabs, Tab::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'tabs-component')
        @options = prepend_controller(options, 'tabs')

        @tabs_class = @options.delete(:tabs_class)
      end
    end
  end
end
