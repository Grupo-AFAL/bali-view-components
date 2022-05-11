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

        def active?
          active_path?(@path)
        end

        def active_child?
          items.any?(&:active?)
        end
      end
    end
  end
end