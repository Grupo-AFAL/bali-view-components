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
        @options = prepend_class_name(options, 'tree-view-component')
      end
    end
  end
end
