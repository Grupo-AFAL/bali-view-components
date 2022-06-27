# frozen_string_literal: true

module Bali
  module SideMenu
    module Link
      class Component < ApplicationViewComponent
        def initialize(name:, href:, icon: nil, **options)
          @name = name
          @icon = icon
          @href = href
          @options = options
        end

        def options
          @options.merge!(href: @href) if @href.present?
          @options.merge(class: classes)
        end

        def classes
          class_names(@options[:class], 'is-active': active?)
        end

        def active?
          active_path?(@href, request.path, match: @options[:match])
        end
      end
    end
  end
end
