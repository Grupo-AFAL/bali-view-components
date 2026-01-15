# frozen_string_literal: true

module Bali
  module TreeView
    class Component < ApplicationViewComponent
      renders_many :items, ->(name:, path:, **options) do
        Item::Component.new(
          name: name,
          path: path,
          current_path: @current_path,
          root: true,
          **options
        )
      end

      def initialize(current_path: nil, **options)
        @current_path = current_path
        @options = prepend_class_name(options, tree_view_classes)
      end

      private

      def tree_view_classes
        class_names(
          'tree-view-component',
          '[&_.tree-view-item-component]:block',
          '[&_.item]:py-1 [&_.item]:px-2 [&_.item]:cursor-pointer [&_.item]:text-ellipsis [&_.item]:overflow-hidden [&_.item]:whitespace-nowrap',
          '[&_.item:hover]:bg-base-200 [&_.is-active]:bg-base-200',
          '[&_.children_.item]:pl-5 [&_.children_.children_.item]:pl-8 [&_.children_.children_.children_.item]:pl-11',
          '[&_.caret]:cursor-pointer [&_.caret]:select-none [&_.caret]:p-1 [&_.caret]:mr-1 [&_.caret]:rounded [&_.caret]:text-sm',
          "[&_.caret]:before:content-['▶'] [&_.caret]:before:text-base-content/80 [&_.caret]:before:inline-block",
          '[&_.caret:hover]:bg-base-300',
          '[&_.is-childless_.caret]:before:text-base-content/30 [&_.is-childless_.caret:hover]:bg-base-200',
          '[&_.caret-down]:before:rotate-90'
        )
      end
    end
  end
end
