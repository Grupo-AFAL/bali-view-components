# frozen_string_literal: true

module Bali
  module Breadcrumb
    module Item
      class Component < ApplicationViewComponent
        attr_reader :href, :name, :icon_name, :options

        def initialize(href:, name:, icon_name: nil, active: false, **options)
          @name = name
          @href = href
          @icon_name = icon_name
          @options = prepend_class_name(options, 'breadcrumb-item-component')
          @options = prepend_class_name(@options, 'is-active') if active
        end
      end
    end
  end
end
