# frozen_string_literal: true

module Bali
  module DataTable
    class Preview < ApplicationViewComponentPreview
      HEADERS = [
        { name: "Name", sortable: true, sort_key: "name" },
        { name: "Status" },
        { name: "Amount", sortable: true, sort_key: "amount" },
        { name: "Created At", sortable: true, sort_key: "created_at" }
      ].freeze

      RECORDS = [
        { name: "Product A", status: "active", amount: 1500, created_at: "2024-01-15" },
        { name: "Product B", status: "inactive", amount: 2300, created_at: "2024-02-20" },
        { name: "Product C", status: "active", amount: 800, created_at: "2024-03-10" },
        { name: "Product D", status: "pending", amount: 3200, created_at: "2024-04-05" },
        { name: "Product E", status: "active", amount: 950, created_at: "2024-05-12" }
      ].freeze

      FILTER_ATTRIBUTES = [
        { key: :name, label: "Name", type: :text },
        { key: :status, label: "Status", type: :select,
          options: [ %w[Active active], %w[Inactive inactive], %w[Pending pending] ] },
        { key: :amount, label: "Amount", type: :number },
        { key: :created_at, label: "Created At", type: :date }
      ].freeze

      MOVIE_FILTER_ATTRIBUTES = [
        { key: :name, label: "Name", type: :text },
        { key: :genre, label: "Genre", type: :select,
          options: [ %w[Action Action], %w[Drama Drama], %w[Sci-Fi Sci-Fi],
                    %w[Comedy Comedy], %w[Horror Horror], %w[Animation Animation],
                    %w[Adventure Adventure] ] },
        { key: :status, label: "Status", type: :select,
          options: [ %w[Done done], %w[Draft draft] ] },
        { key: :indie, label: "Indie", type: :boolean },
        { key: :created_at, label: "Created At", type: :date }
      ].freeze

      # Store en memoria para el preview de vistas guardadas (B2): cumple el contrato de
      # SavedViewsConfiguration sin tocar storage real.
      PreviewSavedView = Struct.new(:id, :name, :payload, keyword_init: true)
      class PreviewSavedViewsStore
        VIEWS = [
          PreviewSavedView.new(id: 1, name: "Solo activos",
                               payload: { "attributes" => { "status_eq" => "active" } }),
          PreviewSavedView.new(id: 2, name: "Montos altos",
                               payload: { "attributes" => { "amount_gteq" => "1000" }, "columns" => [ 0, 2 ] })
        ].freeze

        def list = VIEWS
        def find(id) = VIEWS.find { |view| view.id.to_s == id.to_s }
      end

      # Fixtures del preview CANÓNICO, compartidas con Bali::IndexPage::Preview: el mismo
      # listado se muestra con y sin la capa de página, y dos copias del setup derivarían
      # igual que derivaron los previews que este spec vino a unificar.
      module CanonicalIndex
        # Declara TODO lo que la toolbar auto-configura: atributos filtrables, búsqueda
        # rápida y agrupación. Es el mismo DSL que documenta el skill filterform-datatable.
        class MovieFilterForm < Bali::FilterForm
          search_fields :name, :genre

          filter_attribute :name, type: :text
          filter_attribute :genre, type: :select,
                                   options: [ %w[Action Action], %w[Drama Drama], %w[Sci-Fi Sci-Fi],
                                             %w[Comedy Comedy], %w[Horror Horror],
                                             %w[Animation Animation], %w[Adventure Adventure] ]
          filter_attribute :status, type: :select, options: [ %w[Done done], %w[Draft draft] ]
          filter_attribute :indie, type: :boolean

          # Las tres formas que agrupan desde #1102: columnas, un `ransacker` (una expresión
          # SQL — el GROUP BY sale de su propio Arel) y un camino de asociación, que lleva
          # `value:` porque no hay `movie.studio_name` del que leer la banda de una fila.
          group_by_attribute :genre, label: "Genre"
          group_by_attribute :status, label: "Status"
          group_by_attribute :budget_band, label: "Budget"
          group_by_attribute :studio_name, label: "Studio", value: ->(movie) { movie.studio&.name }

          attribute :name_cont
          attribute :genre_eq
          attribute :status_eq
          attribute :indie_true
        end

        class SavedViewsStore
          VIEWS = [
            PreviewSavedView.new(id: 1, name: "Indie only",
                                 payload: { "attributes" => { "indie_true" => "1" } }),
            PreviewSavedView.new(id: 2, name: "Drafts by status",
                                 payload: { "attributes" => { "status_eq" => "draft" },
                                            "group_by" => "status" })
          ].freeze

          def list = VIEWS
          def find(id) = VIEWS.find { |view| view.id.to_s == id.to_s }
        end

        # `view` llega por dos caminos y son el MISMO param: el control del panel Params de
        # Lookbook y los links del view switch dentro del iframe. Lookbook solo reenvía los
        # query params cuyo nombre coincide con un kwarg del método del preview, así que
        # declararlos es lo que hace que el switch, el "agrupar por" y las vistas guardadas
        # sobrevivan al round-trip.
        def canonical_index_locals(view:, q:, page:, group_by:, saved_view:)
          # `view` va TAMBIÉN adentro de los params del form: el FilterForm suspende la
          # agrupación fuera de la tabla leyéndolo de ahí. Pasándolo solo como local
          # `display_mode:` el form nunca ve el modo y la preview seguiría agrupando en
          # tarjetas — o sea, dejaría de reproducir lo que hace un host real.
          filter_params = ActionController::Parameters.new(
            q: ActionController::Parameters.new(q),
            page: page,
            view: view.presence,
            group_by: group_by.presence,
            saved_view: saved_view.presence
          )
          filter_form = MovieFilterForm.new(
            Movie.all, filter_params,
            storage_id: "lookbook_movies",
            saved_views_store: SavedViewsStore.new
          )
          pagy, movies = pagy(filter_form.result.includes(:studio), limit: 8, page: page)

          { filter_form: filter_form, pagy: pagy, movies: movies, display_mode: view.to_sym }
        end
      end

      include CanonicalIndex

      # @label Default
      def default
        render_with_template(
          template: "bali/data_table/previews/default",
          locals: {
            headers: HEADERS,
            records: RECORDS,
            filter_attributes: FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Saved Views
      # Dropdown "Vistas" (B2): aplicar una vista navega con ?saved_view=<id>; guardar la
      # actual postea a la URL de la app (aquí un endpoint ficticio). Prueba también los
      # atajos estáticos de `default_views`.
      def with_saved_views(saved_view: nil)
        filter_form = Bali::FilterForm.new(
          Movie.all,
          ActionController::Parameters.new(saved_view: saved_view),
          saved_views_store: PreviewSavedViewsStore.new
        )
        render_with_template(
          template: "bali/data_table/previews/with_saved_views",
          locals: { headers: HEADERS, records: RECORDS,
                    filter_attributes: FILTER_ATTRIBUTES, filter_form: filter_form }
        )
      end

      # @label With Search
      def with_search
        render_with_template(
          template: "bali/data_table/previews/with_search",
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
          template: "bali/data_table/previews/with_toolbar_buttons",
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
          template: "bali/data_table/previews/with_summary",
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
          template: "bali/data_table/previews/minimal",
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
          template: "bali/data_table/previews/with_sorting",
          locals: {
            filter_form: filter_form,
            movies: filter_form.result.includes(:studio).limit(10),
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
        pagy, movies = pagy(filter_form.result.includes(:studio), limit: 5, page: page)

        render_with_template(
          template: "bali/data_table/previews/with_pagination",
          locals: {
            filter_form: filter_form,
            pagy: pagy,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES
          }
        )
      end

      # @label Complete Example (Live DB)
      # The canonical index composition, without the page layer. The seven toolbar control
      # families in one bare row (search + filters, group by, column selector, saved views,
      # the persistence bookmark, view switch, host buttons), row selection and pagination.
      #
      # - The surface belongs to the content slot: no `Bali::Card` around the DataTable
      # - `?view=` picks the content band; `dt.display_mode` is the value already validated
      #   against the declared views
      # - Below `sm` the secondary controls fold into the `⋯` menu
      # - Export is not a toolbar control: it lives in the page's `⋯` (`page.with_export`),
      #   which is why it only shows up in `bali/index_page/complete`
      # - In the filters panel, a second condition added to a group NARROWS the listing:
      #   «genre = Drama» then «status = released» returns the intersection. The seed was
      #   OR and the second condition widened the result (#1121); the AND/OR toggle on
      #   the row is how a user asks for the union
      #
      # `bali/index_page/complete` renders this same body inside a page.
      # @param view select { choices: [table, grid, calendar] }
      # @param group_by select { choices: ["", genre, status, budget_band, studio_name] }
      def complete(view: :table, q: {}, page: 1, group_by: nil, saved_view: nil)
        render_with_template(
          template: "bali/data_table/previews/complete",
          locals: canonical_index_locals(view: view, q: q, page: page,
                                         group_by: group_by, saved_view: saved_view)
        )
      end

      # @label With Bulk Actions (Live DB)
      # Row selection with a contextual action row.
      #
      # - `Bali::Table(selectable: true)` renders the checkbox column and the select-all
      #   header; every row needs `record_id:`
      # - `with_bulk_actions` puts the contextual row in the toolbar's slot: it shows up
      #   while a selection exists and the toolbar comes back when it is cleared
      # - The `bulk-actions` Stimulus controller lives on the DataTable container, so the
      #   bar and the rows share one scope
      def with_bulk_actions(q: {}, page: 1)
        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q), page: page)
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)
        pagy, movies = pagy(filter_form.result.includes(:studio), limit: 5, page: page)

        render_with_template(
          template: "bali/data_table/previews/with_bulk_actions",
          locals: {
            filter_form: filter_form,
            pagy: pagy,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES
          }
        )
      end

      # @label With Simple Filters (Studios)
      # Simple inline dropdown filters - a lightweight alternative to the full Filters component.
      # Shows all available filter types:
      # - **Country**: `type: :slim_select` — searchable dropdown
      # - **Status**: `type: :toggle_group` — multi-select segmented buttons
      # - **Size**: `type: :radio_group` — single-select segmented buttons
      # - **Indie**: `type: :boolean` — toggle switch
      # - **Founded**: `type: :number_range` — min/max number inputs
      # - **Created between**: `type: :date_range` — date range picker
      #
      # @param search text
      # @param country select { choices: ["", USA, UK, France, Germany, Japan, India, Australia, Canada] }
      # @param status select { choices: ["", active, inactive, pending] }
      # @param size select { choices: ["", small, medium, large, enterprise] }
      def with_simple_filters(q: {}, page: 1, search: "", country: "", status: "", size: "")
        q_with_filters = q.to_h.dup
        q_with_filters["country_eq"] = country if country.present?
        q_with_filters["status_eq"] = status if status.present?
        q_with_filters["size_eq"] = size if size.present?
        q_with_filters["name_cont"] = search if search.present?

        filter_params = ActionController::Parameters.new(
          q: ActionController::Parameters.new(q_with_filters),
          page: page
        )

        filter_form = Bali::FilterForm.new(
          Studio.all, filter_params,
          simple_filters: Studio.filter_options,
          search_fields: %i[name],
          search_icon: "search"
        )
        pagy, studios = pagy(filter_form.result.order(:name), limit: 10, page: page)

        render_with_template(
          template: "bali/data_table/previews/with_simple_filters",
          locals: {
            filter_form: filter_form,
            pagy: pagy,
            studios: studios
          }
        )
      end

      # @label With Grouping (Live DB)
      # Query-aware row grouping. Pick a field in the "Agrupar por" control (or the
      # `group_by` param below): the query is ordered by that field FIRST — so
      # groups cohere and any user column sort becomes secondary (sort-within-groups)
      # — and each group header shows the GLOBAL count over the full filtered set,
      # e.g. "Action (14)". When Pagy splits a group across pages the header appends
      # a partial hint: "Action (14) — showing 6".
      #
      # Requires a `Bali::FilterForm` that declares grouping attributes (here via the
      # `group_by_attributes:` constructor option; the DSL is `group_by_attribute`).
      # group_by is a whitelisted top-level param — undeclared values are ignored.
      #
      # Grouping accepts the SAME three shapes sorting does (#1102): a real column
      # (`genre`, `status`), a `ransacker` (`budget_band`, a SQL CASE — the GROUP BY runs
      # on the ransacker's own Arel) and an association path (`studio_name`, grouped over
      # the joined column). A path has no `movie.studio_name` to read a row's band from,
      # so its declaration carries `value:`.
      # @param group_by select { choices: [none, genre, status, budget_band, studio_name] }
      # @param page number
      def with_grouping(group_by: "genre", page: 1)
        raw_group_by = group_by.to_s == "none" ? nil : group_by

        filter_params = ActionController::Parameters.new(
          q: ActionController::Parameters.new({}),
          group_by: raw_group_by,
          page: page
        )
        filter_form = Bali::FilterForm.new(
          Movie.all, filter_params,
          group_by_attributes: [
            :genre,
            :status,
            { attribute: :budget_band, label: "Budget" },
            { attribute: :studio_name, label: "Studio", value: ->(movie) { movie.studio&.name } }
          ]
        )
        pagy, movies = pagy(filter_form.result.includes(:studio), limit: 8, page: page)

        render_with_template(
          template: "bali/data_table/previews/with_grouping",
          locals: { filter_form: filter_form, pagy: pagy, movies: movies }
        )
      end

      # @label With Grid Mode (Live DB)
      # Toggle between table and card-based grid layouts.
      #
      # - There is ONE content slot: the host picks `with_table` or `with_grid`
      #   with an `if` on `display_mode` (declaring both raises `DuplicateContent`)
      # - `with_table` brings a surface + horizontal scroll; `with_grid` brings none
      # - The switch is `with_view_switch`: each view declares `value:` and the
      #   DataTable builds the href, preserving the query string
      # @param display_mode select { choices: [table, grid] }
      def with_grid_mode(q: {}, page: 1, display_mode: :table, view: nil)
        # `view` is what the switch links carry; the Lookbook param is the fallback.
        # Lookbook only forwards query params whose name matches a kwarg of this method,
        # so declaring `view:` is what makes the switch round-trip inside the iframe.
        actual_display_mode = (view || display_mode).to_sym

        filter_params = ActionController::Parameters.new(q: ActionController::Parameters.new(q), page: page)
        filter_form = Bali::FilterForm.new(Movie.all, filter_params)
        pagy, movies = pagy(filter_form.result.includes(:studio), limit: 6, page: page)

        render_with_template(
          template: "bali/data_table/previews/with_grid_mode",
          locals: {
            filter_form: filter_form,
            pagy: pagy,
            movies: movies,
            filter_attributes: MOVIE_FILTER_ATTRIBUTES,
            display_mode: actual_display_mode
          }
        )
      end
    end
  end
end
