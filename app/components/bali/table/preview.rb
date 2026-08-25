# frozen_string_literal: true

module Bali
  module Table
    class Preview < ApplicationViewComponentPreview
      HEADERS = [
        { name: 'Name' },
        { name: 'Amount' }
      ].freeze

      RECORDS = [
        { id: 1, name: 'Name 1', amount: 1 },
        { id: 2, name: 'Name 2', amount: 2 },
        { id: 3, name: 'Name 3', amount: 3 }
      ].freeze

      BULK_ACTION_HEADERS = [
        { name: 'Product' },
        { name: 'SKU' },
        { name: 'Price' },
        { name: 'Stock' },
        { name: 'Status' }
      ].freeze

      GROUPING_HEADERS = [
        { name: 'Leader' },
        { name: 'Role' },
        { name: 'Members' }
      ].freeze

      # Pre-sorted by area — grouping assumes caller-controlled row order.
      GROUPING_RECORDS = [
        { id: 1, area: 'Norte', leader: 'Ana Torres', role: 'Coordinator', members: 12 },
        { id: 2, area: 'Norte', leader: 'Bruno Díaz', role: 'Volunteer', members: 4 },
        { id: 3, area: 'Norte', leader: 'Carla Ruiz', role: 'Volunteer', members: 6 },
        { id: 4, area: 'Norte', leader: 'Diego Sosa', role: 'Volunteer', members: 3 },
        { id: 5, area: 'Centro', leader: 'Elena Vidal', role: 'Coordinator', members: 15 },
        { id: 6, area: 'Centro', leader: 'Fabián Mora', role: 'Volunteer', members: 5 },
        { id: 7, area: 'Centro', leader: 'Gabriela León', role: 'Volunteer', members: 8 },
        { id: 8, area: 'Centro', leader: 'Hugo Peña', role: 'Volunteer', members: 2 },
        { id: 9, area: 'Sur', leader: 'Irene Campos', role: 'Coordinator', members: 10 },
        { id: 10, area: 'Sur', leader: 'Julián Rojas', role: 'Volunteer', members: 7 },
        { id: 11, area: 'Sur', leader: 'Karina Vega', role: 'Volunteer', members: 9 },
        { id: 12, area: 'Sur', leader: 'Lucas Ibarra', role: 'Volunteer', members: 1 }
      ].freeze

      # Agrupado por un enum: el valor que llega es el de la base, y es lo que tienen que
      # seguir llevando `with_row(group:)` y las llaves de `group_counts`.
      GROUPING_ENUM_HEADERS = [
        { name: 'Asset' },
        { name: 'Owner' },
        { name: 'Rows' }
      ].freeze

      GROUPING_ENUM_RECORDS = [
        { id: 1, kind: 'table', asset: 'fact_sales', owner: 'Ana Torres', rows: '1.2M' },
        { id: 2, kind: 'table', asset: 'dim_customer', owner: 'Bruno Díaz', rows: '84K' },
        { id: 3, kind: 'view', asset: 'v_active_customers', owner: 'Carla Ruiz', rows: '61K' },
        { id: 4, kind: 'view', asset: 'v_monthly_revenue', owner: 'Diego Sosa', rows: '36' },
        { id: 5, kind: 'restricted', asset: 'employee_payroll', owner: 'Elena Vidal', rows: '412' }
      ].freeze

      # Totales del GROUP BY: llaves CRUDAS, que es la razón por la que el rótulo se traduce
      # al pintar y no metiéndole la traducción a `with_row(group:)`.
      GROUPING_ENUM_COUNTS = { 'table' => 96, 'view' => 41, 'restricted' => 7 }.freeze

      BULK_ACTION_RECORDS = [
        { id: 1, product: 'MacBook Pro 14"', sku: 'MBP-14-M3', price: '$1,999', stock: 45, status: 'active' },
        { id: 2, product: 'iPhone 15 Pro', sku: 'IP15-PRO-256', price: '$999', stock: 120, status: 'active' },
        { id: 3, product: 'iPad Air', sku: 'IPAD-AIR-M2', price: '$599', stock: 0, status: 'out_of_stock' },
        { id: 4, product: 'AirPods Pro', sku: 'APP-2ND-GEN', price: '$249', stock: 200, status: 'active' },
        { id: 5, product: 'Apple Watch Ultra', sku: 'AW-ULTRA-49', price: '$799', stock: 15, status: 'low_stock' },
        { id: 6, product: 'Mac Mini M2', sku: 'MM-M2-512', price: '$799', stock: 30, status: 'active' },
        { id: 7, product: 'Studio Display', sku: 'SD-27-5K', price: '$1,599', stock: 8, status: 'low_stock' }
      ].freeze

      SELECT_GROUP_HEADERS = [
        { name: 'Branch' },
        { name: 'Manager' },
        { name: 'Headcount' }
      ].freeze

      # Dos formas del mismo caso en una pantalla: la primera tabla es un grupo de selección
      # entero, la segunda además agrupa por dentro — sus filas caben en los dos.
      SELECT_GROUP_REGIONS = [
        {
          id: 1, name: 'Región Norte', grouped: false,
          branches: [
            { id: 101, branch: 'Tijuana Centro', manager: 'Ana Torres', headcount: 24 },
            { id: 102, branch: 'Mexicali', manager: 'Bruno Díaz', headcount: 18 },
            { id: 103, branch: 'Ensenada', manager: 'Carla Ruiz', headcount: 11 }
          ]
        },
        {
          id: 2, name: 'Región Sur', grouped: true,
          branches: [
            { id: 201, branch: 'Mérida Norte', manager: 'Diego Sosa', headcount: 31, zone: 'Yucatán' },
            { id: 202, branch: 'Progreso', manager: 'Elena Vidal', headcount: 9, zone: 'Yucatán' },
            { id: 203, branch: 'Cancún', manager: 'Fabián Mora', headcount: 27, zone: 'Quintana Roo' },
            { id: 204, branch: 'Playa del Carmen', manager: 'Gabriela León', headcount: 14, zone: 'Quintana Roo' }
          ]
        }
      ].freeze

      CATALOG_HEADERS = [
        { name: 'Code' },
        { name: 'Description' },
        { name: 'State' }
      ].freeze

      # Solo los propuestos se aprueban en masa; aprobados y retirados están en la misma
      # página porque el listado es uno solo, y no participan de la selección.
      CATALOG_RECORDS = [
        { id: 1, code: 'MAT-0091', description: 'Acero inoxidable 304', state: 'proposed' },
        { id: 2, code: 'MAT-0104', description: 'Aluminio 6061', state: 'proposed' },
        { id: 3, code: 'MAT-0042', description: 'Cobre electrolítico', state: 'approved' },
        { id: 4, code: 'MAT-0117', description: 'Polietileno de alta densidad', state: 'proposed' },
        { id: 5, code: 'MAT-0008', description: 'Latón naval', state: 'retired' }
      ].freeze

      def default
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS
          }
        )
      end

      def empty_table
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: []
          }
        )
      end

      def with_custom_no_records_notification
        render_with_template(
          template: 'bali/table/previews/with_custom_no_records_notification',
          locals: {
            headers: HEADERS,
            records: []
          }
        )
      end

      # @label With Grouping
      # Pass `group:` to `with_row` to render a group-header row whenever the
      # value changes between consecutive rows. The header shows the group value
      # and the count of rows in that run (e.g. "Norte (4)").
      #
      # The collection must arrive **pre-sorted by the group field** — the
      # component never re-orders rows. The same value reappearing later starts a
      # new group. Grouping is therefore incompatible with user-driven column
      # sorting, and a group may continue across Pagy page boundaries.
      def with_grouping
        render_with_template(
          template: 'bali/table/previews/with_grouping',
          locals: {
            headers: GROUPING_HEADERS,
            records: GROUPING_RECORDS
          }
        )
      end

      # @label Translated group bands
      # La banda rotula con el valor crudo de la columna, que en un enum es el de la base
      # (`table`, `view`). `group_i18n_scope:` lo resuelve como `"scope.valor"` y
      # `group_label:` es la escapatoria para lo que no sale de una clave por valor.
      #
      # Los dos resuelven el rótulo AL PINTAR, así que `with_row(group:)` sigue llevando el
      # valor crudo y `group_counts:` conserva sus llaves: los conteos de abajo son los
      # globales (96, 41, 7), no los de la página.
      def with_translated_groups
        render_with_template(
          template: 'bali/table/previews/with_translated_groups',
          locals: {
            headers: GROUPING_ENUM_HEADERS,
            records: GROUPING_ENUM_RECORDS,
            counts: GROUPING_ENUM_COUNTS
          }
        )
      end

      # @label Selectable
      # `selectable: true` renders the checkbox column plus a select-all header, wired to
      # the `bulk-actions` Stimulus controller. Every row needs a `record_id:`.
      #
      # The controller must live on an ancestor element — a `DataTable` with
      # `with_bulk_actions` puts it there for you; standalone, wrap the table in a
      # `Bali::BulkActions::Component` (its default `variant: :floating` bar is the
      # replacement for the removed `bulk_actions:` array), as this preview does.
      def selectable
        render_with_template(
          template: 'bali/table/previews/selectable',
          locals: {
            headers: BULK_ACTION_HEADERS,
            records: BULK_ACTION_RECORDS
          }
        )
      end

      # @label Selectable by group
      # `select_group:` narrows a table's select-all to its own rows, so N listings can live
      # under ONE `Bali::BulkActions` — one bar, one counter, one total to confirm against —
      # instead of one instance per listing, which would give N counters and no total.
      #
      # Nesting works because the ids are a space-separated list, like classes: a row in a
      # grouped table carries its table's id AND its group's, so the header select-all covers
      # the whole table while each group header covers only its run. Group ids are derived
      # from the group VALUE, so the same value reappearing further down is the same group.
      #
      # Two instances of `Bali::BulkActions` nested inside each other would NOT work: Stimulus
      # assigns every target to its closest controller ancestor, so the outer bar would never
      # see the rows and its counter would sit at 0 in silence.
      def selectable_by_group
        render_with_template(
          template: 'bali/table/previews/selectable_by_group',
          locals: {
            headers: SELECT_GROUP_HEADERS,
            regions: SELECT_GROUP_REGIONS
          }
        )
      end

      # @label Rows outside the selection
      # `with_row(selectable: false)` keeps a row out of the selection: no checkbox, an empty
      # cell in its place so the columns stay aligned, and the select-all never reaches it.
      # This is the listing that shows every state on one page and only lets you act on some
      # of them — here, only proposed records can be approved in bulk.
      #
      # A row that is *meant* to be selectable and simply lost its `record_id:` still raises:
      # degrading it silently would leave a row nobody can check and nothing would say so.
      def partially_selectable
        render_with_template(
          template: 'bali/table/previews/partially_selectable',
          locals: {
            headers: CATALOG_HEADERS,
            records: CATALOG_RECORDS
          }
        )
      end
    end
  end
end
