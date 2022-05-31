# frozen_string_literal: true

module Bali
  module TreeView
    module Item
      class Component < ApplicationViewComponent
        renders_many :items, ->(name:, path:, **options) do
          Item::Component.new(
            name: name,
            path: path,
            current_path: @current_path,
            **options
          )
        end

        def initialize(name:, path:, current_path:, root: false, **options)
          @name = name
          @path = path
          @root = root
          @current_path = current_path
          @options = prepend_class_name(options, 'tree-view-item-component')
          @options = prepend_controller(options, 'tree-view-item')
          @options = prepend_action(options, 'click->tree-view-item#navigateTo')
          @options[:data]['tree-view-item-url-value'] = path
        end

        def display_children?
          return false unless items?

          active? || active_child?
        end

        def active?
          @active ||= active_path?(@path, @current_path, match: :exact)
        end

        def active_child?
          @active_child ||= items.any? { |i| i.active? || i.active_child? }
        end
      end
    end
  end
end
