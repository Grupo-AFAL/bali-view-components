# frozen_string_literal: true

module Bali
  module Breadcrumb
    module Item
      class Component < ApplicationViewComponent
        attr_reader :href, :name, :icon_name

        def initialize(href:, name:, icon_name: nil, active: false, **options)
          @name = name
          @href = href
          @icon_name = icon_name
          @active = active
          @options = options
        end

        def item_classes
          class_names(
            'breadcrumb-item-component',
            @options[:class]
          )
        end

        def link_classes
          class_names(
            @active && 'font-semibold'
          )
        end

        def active?
          @active
        end
      end
    end
  end
end
