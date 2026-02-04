# frozen_string_literal: true

module Bali
  module DataTable
    module SimpleFilters
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Simple inline filters for CRUD views.
        # Unlike the complex Filters component, SimpleFilters renders as inline
        # select dropdowns without popovers, AND/OR groupings, or operator selection.
        #
        # @param status select { choices: ["", active, inactive] }
        # @param category select { choices: ["", electronics, books, clothing] }
        def default(status: '', category: '')
          filters = [
            {
              attribute: :status,
              collection: [['Active', 'active'], ['Inactive', 'inactive']],
              blank: 'All Statuses',
              label: 'Status',
              value: status.presence
            },
            {
              attribute: :category,
              collection: [['Electronics', 'electronics'], ['Books', 'books'], ['Clothing', 'clothing']],
              blank: 'All Categories',
              label: 'Category',
              value: category.presence
            }
          ]

          render Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: status.present? || category.present?
          )
        end

        # @label With Default Values
        # Filters can have default values that are pre-selected.
        def with_defaults
          filters = [
            {
              attribute: :status,
              collection: [['Active', 'active'], ['Inactive', 'inactive'], ['Pending', 'pending']],
              blank: 'All Statuses',
              label: 'Status',
              default: 'active',
              value: nil
            },
            {
              attribute: :priority,
              collection: [['High', 'high'], ['Medium', 'medium'], ['Low', 'low']],
              blank: 'All Priorities',
              label: 'Priority',
              default: nil,
              value: nil
            }
          ]

          render Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: false
          )
        end

        # @label Single Filter
        # SimpleFilters works with just one filter too.
        # @param status select { choices: ["", active, inactive, pending] }
        def single_filter(status: '')
          filters = [
            {
              attribute: :status,
              collection: [['Active', 'active'], ['Inactive', 'inactive'], ['Pending', 'pending']],
              blank: 'All',
              label: 'Status',
              value: status.presence
            }
          ]

          render Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: status.present?
          )
        end
      end
    end
  end
end
