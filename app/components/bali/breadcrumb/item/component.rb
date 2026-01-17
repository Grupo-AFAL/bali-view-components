# frozen_string_literal: true

module Bali
  module Breadcrumb
    module Item
      class Component < ApplicationViewComponent
        attr_reader :href, :name, :icon_name

        def initialize(name:, href: nil, icon_name: nil, active: nil, **options)
          @name = name
          @href = href
          @icon_name = icon_name
          @active = active.nil? ? href.nil? : active
          @options = options
        end

        def link?
          @href.present? && !active?
        end

        def active?
          @active
        end

        private

        def item_classes
          class_names(@options[:class])
        end

        def link_classes
          class_names(
            'inline-flex items-center gap-1',
            'no-underline hover:underline'
          )
        end

        def current_classes
          class_names(
            'inline-flex items-center gap-1',
            'cursor-default',
            'no-underline hover:no-underline'
          )
        end
      end
    end
  end
end
