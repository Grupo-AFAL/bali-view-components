# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      renders_many :tabs, ->(**options) {
        Tab::Component.new(full_page_reload: @full_page_reload, **options)
      } 

      def initialize(full_page_reload: false, **options)
        @full_page_reload = full_page_reload

        @options = prepend_class_name(options, 'tabs-component')
        @options = prepend_controller(options, 'tabs')

        @tabs_class = @options.delete(:tabs_class)
      end
    end
  end
end
