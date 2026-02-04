# frozen_string_literal: true

module Bali
  module DataTable
    class Preview < ApplicationViewComponentPreview
      # Pagy 43.x Pagy::Method requires a request object which previews don't have
      # Use Pagy::Offset.new directly instead

      HEADERS = [
        { name: 'Name', sortable: true, sort_key: 'name' },
        { name: 'Status' },
        { name: 'Amount', sortable: true, sort_key: 'amount' },
        { name: 'Created At', sortable: true, sort_key: 'created_at' }
      ].freeze

      RECORDS = [
        { name: 'Product A', status: 'active', amount: 1500, created_at: '2024-01-15' },
        { name: 'Product B', status: 'inactive', amount: 2300, created_at: '2024-02-20' },
        { name: 'Product C', status: 'active', amount: 800, created_at: '2024-03-10' },
        { name: 'Product D', status: 'pending', amount: 3200, created_at: '2024-04-05' },
        { name: 'Product E', status: 'active', amount: 950, created_at: '2024-05-12' }
      ].freeze

      FILTER_ATTRIBUTES = [
        { key: :name, label: 'Name', type: :text },
        { key: :status, label: 'Status', type: :select,
          options: [%w[Active active], %w[Inactive inactive], %w[Pending pending]] },
        { key: :amount, label: 'Amount', type: :number },
        { key: :created_at, label: 'Created At', type: :date }
      ].freeze

      MOVIE_FILTER_ATTRIBUTES = [
        { key: :name, label: 'Name', type: :text },
        { key: :genre, label: 'Genre', type: :select,
          options: [%w[Action Action], %w[Drama Drama], %w[Sci-Fi Sci-Fi],
                    %w[Comedy Comedy], %w[Horror Horror], %w[Animation Animation],
                    %w[Adventure Adventure]] },
        { key: :status, label: 'Status', type: :select,
          options: [%w[Done done], %w[Draft draft]] },
        { key: :indie, label: 'Indie', type: :boolean },
        { key: :created_at, label: 'Created At', type: :date }
      ].freeze

      # @label Default
      def default
        render_with_template(
          template: 'bali/data_table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            filter_attributes: FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Search
      def with_search
        render_with_template(
          template: 'bali/data_table/previews/with_search',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            filter_attributes: FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Toolbar Buttons
      def with_toolbar_buttons
        render_with_template(
          template: 'bali/data_table/previews/with_toolbar_buttons',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            filter_attributes: FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Summary
      def with_summary
        render_with_template(
          template: 'bali/data_table/previews/with_summary',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            filter_attributes: FILTER_ATTRIBUTES,
            summary: "Showing #{RECORDS.size} products • Total: $#{RECORDS.sum { |r| r[:amount] }}"
          }
        )
      end

      # @label Minimal (No Filters)
      def minimal
        render_with_template(
          template: 'bali/data_table/previews/minimal',
          locals: {
            headers: HEADERS.map { |h| { name: h[:name] } },
            records: RECORDS
          }
        )
      end

      # @label With Sorting (Live DB)
      # Sorting requires a `Bali::FilterForm` instance:
      # ```ruby
      # filter_form = Bali::FilterForm.new(Movie.all, params)
      # ```
      # Add `sort: :column_name` to `with_header` to make columns sortable.
      def with_sorting(q: {})
        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q))
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)

        render_with_template(
          template: 'bali/data_table/previews/with_sorting',
          locals: {
            filter_form: filter_form,
            movies: filter_form.result.includes(:tenant).limit(10),
            filter_attributes: MOVIE_FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Pagination (Live DB)
      # Requires **Pagy (>= 43.0)**:
      # - Include `Pagy::Method` in your controller
      #
      # Pass the `pagy` object to DataTable:
      # ```ruby
      # pagy, records = pagy(:offset, scope, limit: 10)
      # Bali::DataTable::Component.new(pagy: pagy, ...)
      # ```
      def with_pagination(q: {}, page: 1)
        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q), page: page)
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)
        collection = filter_form.result.includes(:tenant)
        count = collection.count
        limit = 5
        pagy_obj = Pagy::Offset.new(count: count, page: page.to_i, limit: limit)
        movies = collection.offset(pagy_obj.offset).limit(limit)

        render_with_template(
          template: 'bali/data_table/previews/with_pagination',
          locals: {
            filter_form: filter_form,
            pagy: pagy_obj,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES
          }
        )
      end

      # @label Complete Example (Live DB)
      # Full DataTable with filters, sorting, pagination, and toolbar buttons.
      def complete(q: {}, page: 1)
        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q), page: page)
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)
        collection = filter_form.result.includes(:tenant)
        count = collection.count
        limit = 5
        pagy_obj = Pagy::Offset.new(count: count, page: page.to_i, limit: limit)
        movies = collection.offset(pagy_obj.offset).limit(limit)

        render_with_template(
          template: 'bali/data_table/previews/complete',
          locals: {
            filter_form: filter_form,
            pagy: pagy_obj,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Simple Filters (Studios)
      # Simple inline dropdown filters - a lightweight alternative to the full Filters component.
      # Use for CRUD views that only need 2-4 dropdown filters without AND/OR groupings.
      #
      # This example shows Studios filtered by country, status, and size.
      #
      # Configure via FilterForm:
      # ```ruby
      # filter_form = Bali::FilterForm.new(Studio.all, params, simple_filters: [
      #   { attribute: :country, collection: [...], blank: "All Countries" },
      #   { attribute: :status, collection: [...], blank: "All Statuses" }
      # ])
      # ```
      # @param country select { choices: ["", USA, UK, France, Germany, Japan, India, Australia, Canada] }
      # @param status select { choices: ["", active, inactive, pending] }
      # @param size select { choices: ["", small, medium, large, enterprise] }
      def with_simple_filters(q: {}, page: 1, country: '', status: '', size: '')
        # Merge simple filter values into q params
        q_with_filters = q.to_h.dup
        q_with_filters['country_eq'] = country if country.present?
        q_with_filters['status_eq'] = status if status.present?
        q_with_filters['size_eq'] = size if size.present?

        filter_params = ActionController::Parameters.new(
          q: ActionController::Parameters.new(q_with_filters),
          page: page
        )

        simple_filters_config = [
          {
            attribute: :country,
            collection: Studio::COUNTRIES.map { |c| [c, c] },
            blank: 'All Countries',
            label: 'Country'
          },
          {
            attribute: :status,
            collection: Studio.statuses.keys.map { |s| [s.humanize, s] },
            blank: 'All Statuses',
            label: 'Status'
          },
          {
            attribute: :size,
            collection: Studio::SIZES.map { |s| [s.humanize, s] },
            blank: 'All Sizes',
            label: 'Size'
          }
        ]

        filter_form = Bali::FilterForm.new(Studio.all, filter_params, simple_filters: simple_filters_config)
        pagy, studios = pagy(filter_form.result.order(:name), items: 10, page: page)

        render_with_template(
          template: 'bali/data_table/previews/with_simple_filters',
          locals: {
            filter_form: filter_form,
            pagy: pagy,
            studios: studios
          }
        )
      end

      # @label With Grid Mode (Live DB)
      # Toggle between table and card-based grid layouts.
      #
      # - Use `display_mode: :grid` to show the grid slot
      # - Provide both `with_table` and `with_grid` slots
      # - Enable toggle: `with_actions_panel(grid_display_mode_enabled: true)`
      # @param display_mode select { choices: [table, grid] }
      def with_grid_mode(q: {}, page: 1, display_mode: :table, data_display_mode: nil)
        # Use URL param if present (from toggle clicks), otherwise use Lookbook param
        actual_display_mode = (data_display_mode || display_mode).to_sym

        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q), page: page)
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)
        collection = filter_form.result.includes(:tenant)
        count = collection.count
        limit = 6
        pagy_obj = Pagy::Offset.new(count: count, page: page.to_i, limit: limit)
        movies = collection.offset(pagy_obj.offset).limit(limit)

        render_with_template(
          template: 'bali/data_table/previews/with_grid_mode',
          locals: {
            filter_form: filter_form,
            pagy: pagy_obj,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES,
            display_mode: actual_display_mode
          }
        )
      end
    end
  end
end
