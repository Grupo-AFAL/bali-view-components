# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        renders_many :child_items, 'Bali::SideMenu::Item::Component'

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

        def active?(base_path)
          base_path.include?(uri.path) || active_child_items?(base_path)
        end

        def active_child_items?(base_path)
          child_items.reject(&:disabled?).any? { |child_item| child_item.active?(base_path) }
        end
      end
    end
  end
end
