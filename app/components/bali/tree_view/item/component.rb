# frozen_string_literal: true

module Bali
  module TreeView
    module Item
      class Component < ApplicationViewComponent
        renders_many :items, 'Bali::TreeView::Item::Component'

        def initialize(name:, path:, root: false, **options)
          @name = name
          @path = path
          @root = root
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
          @active ||= active_path?(@path, match: :exact)
        end

        def active_child?
          @active_child ||= items.any? { |i| i.active? || i.active_child? }
        end
      end
    end
  end
end
