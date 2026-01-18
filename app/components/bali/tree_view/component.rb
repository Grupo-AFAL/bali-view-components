# frozen_string_literal: true

module Bali
  module TreeView
    class Component < ApplicationViewComponent
      # Base class for the component wrapper
      BASE_CLASSES = 'tree-view-component'

      renders_many :items, ->(name:, path:, **options) do
        Item::Component.new(
          name: name,
          path: path,
          current_path: current_path,
          root: true,
          **options
        )
      end

      def initialize(current_path: nil, **options)
        @current_path = current_path
        @options = options
      end

      private

      attr_reader :current_path, :options

      def component_classes
        class_names(BASE_CLASSES, options[:class])
      end

      def component_options
        options.except(:class).merge(
          class: component_classes,
          role: 'tree'
        )
      end
    end
  end
end
