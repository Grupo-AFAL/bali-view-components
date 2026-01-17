# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      renders_many :actions, Action::Component
      renders_many :items, Item::Component

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

      def floating_bar_classes
        class_names(
          'fixed bottom-4 left-1/2 -translate-x-1/2 z-40',
          'hidden' # Stimulus toggles visibility
        )
      end

      def floating_bar_inner_classes
        'flex items-center shadow-xl rounded-lg overflow-hidden'
      end

      def counter_classes
        'bg-primary text-primary-content font-bold text-2xl px-4 py-2 rounded-l-lg'
      end

      def actions_wrapper_classes
        'flex gap-2 px-3 py-2 bg-base-100 rounded-r-lg'
      end

      def merge_data_attributes(existing, **new_attrs)
        (existing || {}).merge(new_attrs)
      end
    end
  end
end
