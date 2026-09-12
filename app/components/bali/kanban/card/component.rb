# frozen_string_literal: true

module Bali
  module Kanban
    module Card
      class Component < ApplicationViewComponent
        # @param update_url [String, nil] URL to PATCH when card is dropped (position + list_id)
        # @param label [String, nil] Short name for the card, used when a drop is
        #   announced. Defaults to the card's own text, which is right for a card
        #   whose first line is its title and wrong for one that leads with a
        #   date or an avatar.
        def initialize(update_url: nil, label: nil, **options)
          @update_url = update_url
          @label = label
          @options = options
        end

        private

        attr_reader :update_url, :label, :options

        # Host options pass through — `data:` MERGES under the component's own
        # keys instead of being dropped (#1027): the column-lock recipe
        # components.md documents (`data: { sortable_item_pull: "false" }`)
        # depends on it reaching the card element.
        def html_attributes
          attrs = options.except(:class, :data)
          attrs[:class] = class_names("card bg-base-100 card-border p-3", options[:class])
          attrs[:role] ||= "listitem"
          data = (options[:data] || {}).dup
          data[:sortable_update_url] = update_url if update_url
          data[:kanban_card_label] = label if label
          attrs[:data] = data if data.any?
          attrs
        end
      end
    end
  end
end
