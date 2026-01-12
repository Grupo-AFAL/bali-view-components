# frozen_string_literal: true

module Bali
  module SideMenu
    module List
      class Component < ApplicationViewComponent
        renders_many :items, ->(href: nil, name: nil, icon: nil, authorized: true, **options) do
          Item::Component.new(
            name: name,
            href: href,
            icon: icon,
            authorized: authorized,
            current_path: @current_path,
            **options
          )
        end

        attr_reader :title

        def initialize(current_path:, title: nil, **options)
          @title = title
          @current_path = current_path
          @options = options
        end

        def title_class
          class_names('menu-title', @options.delete(:title_class))
        end
      end
    end
  end
end
