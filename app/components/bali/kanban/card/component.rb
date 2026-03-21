# frozen_string_literal: true

module Bali
  module Kanban
    module Card
      class Component < ApplicationViewComponent
        # @param update_url [String, nil] URL to PATCH when card is dropped (position + list_id)
        def initialize(update_url: nil, **options)
          @update_url = update_url
          @options = options
        end

        private

        attr_reader :update_url, :options

        def html_attributes
          attrs = {
            class: class_names("card bg-base-100 card-border p-3", options[:class])
          }
          attrs[:data] = { sortable_update_url: update_url } if update_url
          attrs
        end
      end
    end
  end
end
