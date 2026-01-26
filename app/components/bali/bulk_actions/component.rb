# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      renders_many :actions, Action::Component
      renders_many :items, Item::Component

      # Consolidated class definitions for floating action bar
      CLASSES = {
        floating_bar: 'fixed bottom-4 left-1/2 -translate-x-1/2 z-40 hidden',
        floating_bar_inner: 'flex items-center shadow-xl rounded-lg overflow-hidden',
        counter: 'bg-primary text-primary-content font-bold text-2xl px-4 py-2 rounded-l-lg',
        actions_wrapper: 'flex gap-2 px-3 py-2 bg-base-100 rounded-r-lg'
      }.freeze

      def initialize(**options)
        @options = options
      end

      private

      def component_classes
        class_names('bulk-actions-component', @options[:class])
      end

      def component_attributes
        @options.except(:class).merge(
          class: component_classes,
          data: merge_data_attributes(@options[:data], controller: 'bulk-actions')
        )
      end

      def merge_data_attributes(existing, **new_attrs)
        (existing || {}).merge(new_attrs)
      end
    end
  end
end
