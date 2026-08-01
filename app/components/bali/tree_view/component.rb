# frozen_string_literal: true

module Bali
  module TreeView
    class Component < ApplicationViewComponent
      # Base class for the component wrapper - DaisyUI menu-inspired
      BASE_CLASSES = "tree-view-component bg-base-200 rounded-box p-2"

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

      # No `role="tree"` — see docs/guides/migration-v2-to-v3.md. This is a list of
      # links with disclosure buttons, and a <ul> says exactly that without promising
      # the keyboard contract a tree owes a screen reader (roving tabindex, arrow
      # keys, type-ahead) and that this component has never implemented.
      def component_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
