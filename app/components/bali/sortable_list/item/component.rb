# frozen_string_literal: true

module Bali
  module SortableList
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :list, SortableList::Component

        def initialize(update_url:, item_pull: true, **options)
          @options = prepend_class_name(options, 'sortable-item')
          @options = prepend_data_attribute(@options, 'sortable-item-pull', item_pull)
          @options = prepend_data_attribute(@options, 'sortable-update-url', update_url)
        end
      end
    end
  end
end
