# frozen_string_literal: true

module Bali
  module TreeView
    class Component < ApplicationViewComponent
      renders_many :items, ->(name:, path:, **options) do
        Item::Component.new(name: name, path: path, root: true, **options)
      end

      def initialize(**options)
        @options = prepend_class_name(options, 'tree-view-component')
      end
    end
  end
end
