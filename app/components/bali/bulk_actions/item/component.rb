# frozen_string_literal: true

module Bali
  module BulkActions
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(record_id:, **options)
          @options = prepend_class_name(options, 'bulk-actions-component--item cursor-pointer')
          @options = prepend_data_attribute(@options, :record_id, record_id)
          @options = prepend_data_attribute(@options, :bulk_actions_target, :item)
          @options = prepend_data_attribute(@options, :action, 'click->bulk-actions#toggle')
        end

        def call
          tag.div(**options) do
            content
          end
        end
      end
    end
  end
end
