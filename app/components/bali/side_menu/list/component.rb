# frozen_string_literal: true

module Bali
  module SideMenu
    module List
      class Component < ApplicationViewComponent
        renders_many :items, Item::Component

        attr_reader :title

        def initialize(title:, **options)
          @title = title
          @options = options
        end

        def title_class
          class_names(['menu-label', @options.delete(:title_class)].compact)
        end

        def list_class
          class_names(['menu-list', @options.delete(:list_class)].compact)
        end
      end
    end
  end
end
