# frozen_string_literal: true

module Bali
  module SortableList
    module Item
      class Component < ApplicationViewComponent
        renders_one :list, SortableList::Component

        BASE_CLASSES = 'sortable-item p-2 bg-base-100 border border-base-300 ' \
                       'first:rounded-t last:rounded-b ' \
                       '[&_.sortable-list-component]:pl-4 [&_.sortable-list-component]:pt-2'

        def initialize(update_url:, item_pull: true, **options)
          @options = build_options(options, update_url, item_pull)
        end

        private

        attr_reader :options

        def build_options(opts, update_url, item_pull)
          result = prepend_class_name(opts, BASE_CLASSES)
          result = prepend_data_attribute(result, 'sortable-item-pull', item_pull)
          prepend_data_attribute(result, 'sortable-update-url', update_url)
        end
      end
    end
  end
end
