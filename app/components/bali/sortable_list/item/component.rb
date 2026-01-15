# frozen_string_literal: true

module Bali
  module SortableList
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :list, SortableList::Component

        def initialize(update_url:, item_pull: true, **options)
          @options = prepend_class_name(options,
                                        'sortable-item p-2 bg-base-100 border border-base-300 first:rounded-t last:rounded-b [&_.sortable-list-component]:pl-4 [&_.sortable-list-component]:pt-2')
          @options = prepend_data_attribute(@options, 'sortable-item-pull', item_pull)
          @options = prepend_data_attribute(@options, 'sortable-update-url', update_url)
        end
      end
    end
  end
end
