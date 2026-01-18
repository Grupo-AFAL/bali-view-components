# frozen_string_literal: true

module Bali
  module TreeView
    module Item
      class Component < ApplicationViewComponent
        # Component constants
        BASE_CLASSES = 'tree-view-item-component'
        CONTROLLER_NAME = 'tree-view-item'

        # Item styling classes
        ITEM_CLASSES = %w[
          py-1 px-2 cursor-pointer
          text-ellipsis overflow-hidden whitespace-nowrap
          hover:bg-base-200
        ].join(' ').freeze

        # Caret styling classes
        CARET_CLASSES = %w[
          cursor-pointer select-none p-1 mr-1 rounded text-sm
          before:content-['▶'] before:text-base-content/80
          before:inline-block hover:bg-base-300
        ].join(' ').freeze

        # Children container indentation
        CHILDREN_CLASSES = 'children pl-4'

        renders_many :items, ->(name:, path:, **options) do
          Item::Component.new(
            name: name,
            path: path,
            current_path: current_path,
            **options
          )
        end

        def initialize(name:, path:, current_path:, root: false, **options)
          @name = name
          @path = path
          @root = root
          @current_path = current_path
          @options = options
        end

        def display_children?
          return false unless items?

          active? || active_child?
        end

        def active?
          @active ||= active_path?(path, current_path, match: :exact)
        end

        def active_child?
          @active_child ||= items.any? { |i| i.active? || i.active_child? }
        end

        private

        attr_reader :name, :path, :root, :current_path, :options

        def wrapper_options
          {
            class: wrapper_classes,
            role: 'treeitem',
            data: wrapper_data
          }.tap do |opts|
            opts[:'aria-expanded'] = display_children? if items?
          end
        end

        def wrapper_classes
          class_names(BASE_CLASSES, options[:class])
        end

        def wrapper_data
          {
            controller: CONTROLLER_NAME,
            action: "click->#{CONTROLLER_NAME}#navigateTo",
            "#{CONTROLLER_NAME}-url-value": path
          }.merge(options.fetch(:data, {}))
        end

        def item_classes
          class_names(
            'item',
            ITEM_CLASSES,
            'bg-base-200': active?,
            'is-active': active?,
            'is-childless': !items?,
            'is-root': root
          )
        end

        def caret_classes
          class_names(
            'caret',
            CARET_CLASSES,
            'caret-down before:rotate-90': display_children?,
            'before:text-base-content/30 hover:bg-base-200': !items?
          )
        end

        def caret_data
          {
            action: "click->#{CONTROLLER_NAME}#toggle",
            "#{CONTROLLER_NAME}-target": 'caret'
          }
        end

        def children_classes
          class_names(CHILDREN_CLASSES, hidden: !display_children?)
        end

        def children_data
          { "#{CONTROLLER_NAME}-target": 'children' }
        end
      end
    end
  end
end
