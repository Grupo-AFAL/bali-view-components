# frozen_string_literal: true

module Bali
  module SideMenu
    module BottomGroup
      class Component < ApplicationViewComponent
        renders_many :items, Item::Component.renderable(group_behavior: :expandable)

        attr_reader :name, :icon

        def initialize(name:, icon: nil, current_path: nil, **options)
          @name = name
          @icon = icon
          @current_path = current_path
          @options = options
        end

        def active?
          items.any?(&:active?)
        end
      end
    end
  end
end
