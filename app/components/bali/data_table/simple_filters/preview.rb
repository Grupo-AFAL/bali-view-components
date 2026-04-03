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
              collection: [%w[Active active], %w[Inactive inactive]],
              blank: 'All Statuses',
              label: 'Status',
              value: status.presence
            },
            {
              attribute: :category,
              collection: [%w[Electronics electronics], %w[Books books],
                           %w[Clothing clothing]],
              blank: 'All Categories',
              label: 'Category',
              value: category.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
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
              collection: [%w[Active active], %w[Inactive inactive], %w[Pending pending]],
              blank: 'All Statuses',
              label: 'Status',
              default: 'active',
              value: nil
            },
            {
              attribute: :priority,
              collection: [%w[High high], %w[Medium medium], %w[Low low]],
              blank: 'All Priorities',
              label: 'Priority',
              default: nil,
              value: nil
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
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
              collection: [%w[Active active], %w[Inactive inactive], %w[Pending pending]],
              blank: 'All',
              label: 'Status',
              value: status.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: status.present?
          )
        end

        # @label With Search
        # Combines a text search input with dropdown filters.
        # The search input renders before the dropdowns and submits together
        # in a single GET request.
        #
        # @param search_text text
        # @param status select { choices: ["", active, inactive] }
        # @param category select { choices: ["", electronics, books, clothing] }
        def with_search(search_text: '', status: '', category: '')
          filters = [
            {
              attribute: :status,
              collection: [%w[Active active], %w[Inactive inactive]],
              blank: 'All Statuses',
              label: 'Status',
              value: status.presence
            },
            {
              attribute: :category,
              collection: [%w[Electronics electronics], %w[Books books],
                           %w[Clothing clothing]],
              blank: 'All Categories',
              label: 'Category',
              value: category.presence
            }
          ]

          search = {
            field_name: 'q[name_cont]',
            value: search_text.presence,
            placeholder: 'Search by name...'
          }

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: search_text.present? || status.present? || category.present?,
            search: search
          )
        end

        # @label Search Only
        # SimpleFilters can render with just a search input and no dropdowns.
        #
        # @param search_text text
        def search_only(search_text: '')
          search = {
            field_name: 'q[name_cont]',
            value: search_text.presence,
            placeholder: 'Search records...'
          }

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: [],
            search: search
          )
        end

        # @label Toggle Group
        # Segmented button groups for filters with a small number of choices.
        # Supports both single select (radio) and multi select (checkbox).
        #
        # @param kind select { choices: ["", public, private] }
        # @param categories select { choices: [electronics, books, clothing], multi: true }
        def toggle_group(kind: '', categories: [])
          filters = [
            {
              attribute: :kind,
              collection: [%w[Public public], %w[Private private]],
              blank: 'All',
              label: 'Kind',
              type: :toggle_group,
              value: kind.presence
            },
            {
              attribute: :category,
              collection: [%w[Electronics electronics], %w[Books books],
                           %w[Clothing clothing]],
              label: 'Categories',
              type: :toggle_group_multi,
              predicate: :in,
              value: categories.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: kind.present? || categories.present?
          )
        end
      end
    end
  end
end
