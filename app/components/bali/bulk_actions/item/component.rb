# frozen_string_literal: true

module Bali
  module BulkActions
    module Item
      class Component < ApplicationViewComponent
        attr_reader :record_id

        def initialize(record_id:, **options)
          @record_id = record_id
          @options = options
        end

        # Selected state uses border + bg instead of ring to avoid overlap
        ITEM_CLASSES = [
          'bulk-actions-item cursor-pointer transition-colors',
          'border-2 border-transparent',
          '[&.selected]:border-primary [&.selected]:bg-primary/5'
        ].join(' ').freeze

        def call
          tag.div(**item_attributes) do
            content
          end
        end

        private

        def item_classes
          class_names(ITEM_CLASSES, @options[:class])
        end

        def item_attributes
          @options.except(:class).merge(
            class: item_classes,
            data: merge_data_attributes(
              @options[:data],
              record_id: record_id,
              bulk_actions_target: 'item',
              action: 'click->bulk-actions#toggle'
            )
          )
        end

        def merge_data_attributes(existing, **new_attrs)
          (existing || {}).merge(new_attrs)
        end
      end
    end
  end
end
