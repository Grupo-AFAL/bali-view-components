# frozen_string_literal: true

module Bali
  module SortableList
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :list, SortableList::Component

        def initialize(update_url:, item_pull: true, **options)
          @item_pull = item_pull
          @update_url = update_url
          @class = options.delete(:class)
          @options = options
        end

        def classes
          class_names('sortable-item', @class)
        end

        def data_attributes
          {
            'sortable-item-pull': @item_pull,
            'sortable-update-url': @update_url
          }
        end
      end
    end
  end
end
