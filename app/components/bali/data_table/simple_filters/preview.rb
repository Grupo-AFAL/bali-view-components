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
            fields: [:name],
            value: search_text.presence,
            placeholder: 'Search by name...',
            icon: 'search'
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
        # Use the `width` option to control how wide the search input is.
        # Default is `w-48 sm:w-96`. Use `flex-1` for full available width.
        #
        # @param search_text text
        # @param width select { choices: ["w-48 sm:w-96", "w-64 sm:w-full", "flex-1"] }
        def search_only(search_text: '', width: 'w-48 sm:w-96')
          search = {
            fields: [:name],
            value: search_text.presence,
            placeholder: 'Search records...',
            width: width
          }

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: [],
            search: search
          )
        end

        # @label Toggle Group
        # Segmented button groups for filters with a small number of choices.
        #
        # @param kind select { choices: [public, private], multi: true }
        # @param categories select { choices: [electronics, books, clothing], multi: true }
        def toggle_group(kind: [], categories: [])
          filters = [
            {
              attribute: :kind,
              collection: [%w[Public public], %w[Private private]],
              label: 'Kind',
              type: :toggle_group,
              predicate: :in,
              value: kind.presence
            },
            {
              attribute: :category,
              collection: [%w[Electronics electronics], %w[Books books],
                           %w[Clothing clothing]],
              label: 'Categories',
              type: :toggle_group,
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

        STATUS_CHOICES = [%w[Draft draft], %w[Published published], %w[Archived archived]].freeze
        KIND_CHOICES = [%w[Public public], %w[Private private]].freeze
        GENRE_CHOICES = [%w[Action action], %w[Comedy comedy], %w[Drama drama]].freeze

        # @label Auto Submit
        # Pills and selects that filter on change. `auto_submit: true` per filter
        # mounts `submit-on-change` on the row and wires that filter's controls to
        # it, so there is nothing left to press — the Filter button stays for the
        # filters that did not opt in (#996 added the native select: its change
        # fires when the menu closes on a selection, a completed choice).
        #
        # The form GETs this same URL and the template reads the values back out of the
        # `q` params, so the row really round-trips: the query string below is what the
        # last click sent, and the pills come back showing it. No Lookbook `@param`s
        # here for that reason — the state of this preview is the query string.
        def auto_submit
          render_with_template(
            template: 'bali/data_table/simple_filters/previews/auto_submit',
            locals: {
              status_choices: Bali::DataTable::SimpleFilters::Preview::STATUS_CHOICES,
              kind_choices: Bali::DataTable::SimpleFilters::Preview::KIND_CHOICES,
              genre_choices: Bali::DataTable::SimpleFilters::Preview::GENRE_CHOICES
            }
          )
        end

        # @label Date Range
        # Single date picker that selects a range of dates.
        #
        # @param created_at text
        def date_range(created_at: '')
          filters = [
            {
              attribute: :created_at,
              label: 'Created between',
              type: :date_range,
              value: created_at.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: created_at.present?
          )
        end

        # @label Date Range Presets
        # `presets:` turns the range picker into a period select — "This month" instead of
        # two dates — with the picker behind its "Custom…" option.
        #
        # The chosen token travels in the SAME param the explicit range does
        # (`q[created_at]=this_month`) and `Bali::Types::DateRangeValue` resolves it against
        # `Time.zone` on every query. That is why a saved view built on one still means
        # "this month" next month, which a stored pair of dates cannot.
        #
        # Pass `presets: true` for every token in `Bali::DateRangePresets::TOKENS`, or an
        # array to pick and order them. Only `date_range` takes them: "this week" is not a
        # value a single date can hold.
        #
        # @param created_at select { choices: ["", today, this_week, this_month, last_7_days, last_30_days, "2026-01-01 to 2026-03-31"] }
        def date_range_presets(created_at: '')
          filters = [
            {
              attribute: :created_at,
              label: 'Created between',
              type: :date_range,
              icon: 'calendar',
              presets: %i[today this_week this_month last_7_days last_30_days],
              value: created_at.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: created_at.present?
          )
        end

        # @label Boolean Toggle
        # On/off toggle for boolean columns like "active", "published", or "featured".
        #
        # @param featured toggle
        # @param published toggle
        def boolean_toggle(featured: false, published: false)
          filters = [
            {
              attribute: :featured,
              label: 'Featured',
              type: :boolean,
              value: featured ? 'true' : nil
            },
            {
              attribute: :published,
              label: 'Published',
              type: :boolean,
              value: published ? 'true' : nil
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: featured || published
          )
        end

        # @label Radio Group
        # Single-select segmented buttons — like toggle group but only one choice at a time.
        #
        # @param status select { choices: ["", draft, published, archived] }
        def radio_group(status: '')
          filters = [
            {
              attribute: :status,
              collection: [%w[Draft draft], %w[Published published], %w[Archived archived]],
              label: 'Status',
              type: :radio_group,
              value: status.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: status.present?
          )
        end

        # @label Number Range
        # Min/max inputs for numeric columns like price, quantity, or age.
        #
        # @param min number
        # @param max number
        def number_range(min: nil, max: nil)
          filters = [
            {
              attribute: :amount,
              label: 'Amount',
              type: :number_range,
              icon: 'dollar-sign',
              step: 1,
              placeholder_min: 'Min',
              placeholder_max: 'Max',
              value: { min: min, max: max }
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: min.present? || max.present?
          )
        end

        # @label With Icons
        # Filters can have icons to save space and provide visual context.
        #
        # @param status select { choices: [0, 1, 2] }
        # @param country select { choices: ["", USA, UK, France, Germany] }
        def with_icons(status: nil, country: '')
          filters = [
            {
              attribute: :country,
              collection: [%w[USA USA], %w[UK UK], %w[France France], %w[Germany Germany]],
              blank: 'All Countries',
              label: 'Country',
              icon: 'globe',
              value: country.presence
            },
            {
              attribute: :status,
              collection: [['Active', 0], ['Inactive', 1], ['Pending', 2]],
              label: 'Status',
              type: :toggle_group,
              predicate: :in,
              value: status.presence
            }
          ]

          search = {
            fields: [:name],
            value: nil,
            placeholder: 'Search...',
            icon: 'search'
          }

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            search: search,
            show_clear: status.present? || country.present?
          )
        end

        # @label With Persistence
        # A bookmark toggle appears next to the actions when `storage_id` is set,
        # letting users opt into persisting their filters across visits. The
        # preference is stored in localStorage + a cookie by the
        # `filter-persistence` controller (mirrors Bali::Filters).
        #
        # @param status select { choices: ["", active, inactive] }
        # @param persist_enabled toggle
        def with_persistence(status: '', persist_enabled: false)
          filters = [
            {
              attribute: :status,
              collection: [%w[Active active], %w[Inactive inactive]],
              blank: 'All Statuses',
              label: 'Status',
              value: status.presence
            }
          ]

          render Bali::DataTable::SimpleFilters::Component.new(
            url: '/lookbook',
            filters: filters,
            show_clear: status.present?,
            storage_id: 'lookbook_simple_filters',
            persist_enabled: persist_enabled
          )
        end
      end
    end
  end
end
