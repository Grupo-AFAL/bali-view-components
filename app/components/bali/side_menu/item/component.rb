# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        renders_many :child_items, 'SideMenu::Item::Component'

        attr_reader :href

        def initialize(name:, href:, icon: nil, authorized: true, **options)
          @name = name
          @href = href
          @icon = icon
          @authorized = authorized
          @options = options
        end

        def render?
          @authorized
        end

        def uri
          URI(@href)
        end

        def disabled?
          @href.blank?
        end

        def active_child_items?
          child_items.reject(&:disabled?).any? do |item|
            request.path.include?(item.uri.path)
          end
        end
      end
    end
  end
end
