# frozen_string_literal: true

module Bali
  module SideMenu
    module BottomGroup
      class Component < ApplicationViewComponent
        renders_many :items,
                     lambda { |href: nil, name: nil, icon: nil,
                               authorized: true, disabled: false, target: nil, **options|
                       Item::Component.new(
                         name: name,
                         href: href,
                         icon: icon,
                         authorized: authorized,
                         disabled: disabled,
                         target: target,
                         current_path: @current_path,
                         group_behavior: :expandable,
                         **options
                       )
                     }

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
