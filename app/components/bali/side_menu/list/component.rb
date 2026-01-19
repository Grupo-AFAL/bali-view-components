# frozen_string_literal: true

module Bali
  module SideMenu
    module List
      class Component < ApplicationViewComponent
        renders_many :items, ->(href: nil, name: nil, icon: nil, authorized: true, disabled: false, **options) do
          Item::Component.new(
            name: name,
            href: href,
            icon: icon,
            authorized: authorized,
            disabled: disabled,
            current_path: @current_path,
            group_behavior: @group_behavior,
            **options
          )
        end

        attr_reader :title

        def initialize(current_path:, title: nil, group_behavior: :expandable, **options)
          @title = title
          @current_path = current_path
          @group_behavior = group_behavior
          @title_class = options.delete(:title_class)
          @options = options
        end

        def title_classes
          class_names('menu-label', 'px-2.5', 'pt-3', 'pb-1.5', @title_class)
        end
      end
    end
  end
end
