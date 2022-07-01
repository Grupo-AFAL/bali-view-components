# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      renders_many :tabs, ->(**options) {
        Tab::Component.new(navigation_action: @navigation_action, **options)
      }

      def initialize(navigation_action: :replace, **options)
        @navigation_action = navigation_action.to_sym

        @options = prepend_class_name(options, 'tabs-component')
        @options = prepend_controller(options, 'tabs')

        @tabs_class = @options.delete(:tabs_class)
      end
    end
  end
end
