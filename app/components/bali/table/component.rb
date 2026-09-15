# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      TABLE_CLASSES = "table table-zebra min-w-full"
      CONTAINER_CLASSES = "overflow-x-auto table-component"
      STICKY_CLASSES = "overflow-visible [&_table]:overflow-x-auto " \
                       "[&_thead_tr]:sticky [&_thead_tr]:bg-base-100 [&_thead_tr]:top-[3.75rem]"

      class MissingFilterForm < StandardError; end

      # `bulk_actions:` era el array de la selección legada, borrada en v3. Sin este guardia
      # caería en `**options` y saldría como atributo HTML del `<table>`: la tabla se vería
      # bien, sin columna de checkbox y sin barra, y nada lo delataría.
      REMOVED_BULK_ACTIONS = "Bali::Table(bulk_actions:) was removed in v3. Turn on " \
                             "`selectable: true` and declare the actions on a " \
                             "`Bali::BulkActions::Component` ancestor — inside a DataTable " \
                             "that is `with_bulk_actions`, standalone it is the default " \
                             "`variant: :floating` bar."

      GROUP_LABEL_NOT_CALLABLE = "Bali::Table(group_label:) takes something that responds " \
                                 "to `call` and returns the band's label — a lambda over " \
                                 "the raw group value. For a plain key-per-value lookup, " \
                                 "`group_i18n_scope:` is the shorter spelling."

      ROW_SELECTABLE_WITHOUT_TABLE = "with_row(selectable: true) needs the table to be " \
                                     "`selectable: true`: the checkbox column and the " \
                                     "select-all header are the table's, not the row's. A " \
                                     "row can only opt OUT, with `selectable: false`."

      # Un grupo que nace plegado necesita el botón que lo despliega, y sin la opción no lo
      # hay: quedarían filas escondidas sin forma de verlas.
      COLLAPSED_WITHOUT_COLLAPSIBLE = "Bali::Table(collapsed_groups:) needs " \
                                      "`collapsible_groups: true`: a group born folded needs " \
                                      "the trigger that unfolds it, and without the option " \
                                      "there is none."

      # `group_header:` caería en `**options` como atributo del `<table>` (#1081). El
      # encabezado enriquecido es un bloque porque recibe CADA grupo al pintar, y un slot de
      # ViewComponent se captura una sola vez.
      GROUP_HEADER_IS_A_BLOCK = "Bali::Table(group_header:) is not an option. Declare it as " \
                                "a block — `table.with_group_header { |group| ... }` — it " \
                                "is called once per band with the group's `value`, `rows`, " \
                                "`label` and `count`."

      # El botón de la banda es UN disclosure (WAI-ARIA): `aria-expanded` lleva el estado y
      # `aria-controls` las filas que pliega. `group/table-group` es un grupo NOMBRADO para
      # que el chevron gire con el `aria-expanded` de este botón y no con el de cualquier
      # `.group` ancestro (un `Bali::Reveal` alrededor de la tabla, por ejemplo).
      GROUP_TRIGGER_CLASSES = "group/table-group flex w-full items-center gap-2 text-left " \
                              "cursor-pointer"
      GROUP_CHEVRON_CLASSES = "shrink-0 transition-transform -rotate-90 " \
                              "group-aria-expanded/table-group:rotate-0"

      # `label` y `count` van resueltos para que un `with_group_header` no tenga que rehacer
      # la traducción ni la búsqueda en `group_counts`: `count` es el total global cuando se
      # conoce y el tamaño de la corrida cuando no, lo mismo que muestra el texto por default.
      RowGroup = Struct.new(:value, :rows, :label, :count)

      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      # `selectable:` en la fila GANA sobre el de la tabla: `false` deja la fila fuera del
      # universo del seleccionar-todo y pinta la celda vacía, para que las columnas sigan
      # alineadas. Es el caso "propuestos, aprobados y retirados en la misma página, y solo
      # los propuestos se aprueban en masa".
      #
      # Los grupos de selección se resuelven al RENDERIZAR, no acá: `grouped?` depende de
      # TODAS las filas y cuando este lambda corre solo existen las anteriores.
      renders_many :rows, ->(skip_tr: false, selectable: nil, group: nil, **options) do
        sequence = next_row_sequence

        Row::Component.new(
          skip_tr: skip_tr,
          selectable: row_selectable(selectable),
          select_column: selectable?,
          select_groups: -> { selection_groups_for(group) },
          collapse: -> { collapse_attributes_for(group, sequence) },
          group: group,
          **options
        )
      end

      renders_many :footers, Footer::Component

      renders_one :new_record_link, ->(name:, href:, modal: true, **options) do
        Bali::Link::Component.new(name: name, href: href, variant: :success, modal: modal, **options)
      end

      renders_one :no_records_notification
      renders_one :no_results_notification

      attr_reader :options, :tbody_options

      # @param selectable [Boolean] Columna de checkbox + seleccionar-todo cableada al
      #   controlador `bulk-actions`, que debe vivir en algún ancestro (el DataTable lo
      #   pone solo cuando se declara `with_bulk_actions`). Cada fila necesita `record_id:`,
      #   salvo las que se declaren `with_row(selectable: false)`.
      # @param select_group [String, nil] Acota el seleccionar-todo de ESTA tabla a sus
      #   propias filas. Es lo que permite N tablas —una por departamento, por sucursal—
      #   bajo un solo `Bali::BulkActions`: cada cabecera marca lo suyo y el contador sigue
      #   siendo uno, el total. Sin él, la cabecera marca todo lo que el controlador vea,
      #   que con una sola tabla es exactamente lo mismo de siempre.
      # @param group_i18n_scope [String, nil] Traduce el rótulo de cada banda de grupo como
      #   `"#{scope}.#{value}"` — la misma convención de `Bali::Tag.for(i18n_scope:)`, para
      #   el caso que es casi siempre: agrupar por un enum. `group_counts` sigue con sus
      #   llaves crudas y `with_row(group:)` sigue llevando el valor crudo.
      # @param group_label [Proc, nil] La escapatoria, cuando el rótulo no sale de una clave
      #   por valor (una fecha, un rango, un id que hay que resolver). Recibe el valor crudo
      #   y devuelve el rótulo. Gana sobre `group_i18n_scope:`.
      # @param collapsible_groups [Boolean] Cada banda de grupo pasa a ser un botón que
      #   pliega y despliega sus filas (controlador `table-groups`). Sin JS todo queda
      #   visible: el servidor nunca esconde una fila, solo marca el estado en el botón.
      # @param collapsed_groups [Array, Proc, true, nil] Qué grupos nacen plegados: una lista
      #   de valores crudos (con la misma tolerancia string/símbolo de `group_counts`), un
      #   callable sobre el valor crudo, o `true` para todos. Exige `collapsible_groups:`.
      def initialize(form: nil, selectable: false, select_group: nil, sticky_headers: false,
                     group_counts: {}, group_i18n_scope: nil, group_label: nil,
                     collapsible_groups: false, collapsed_groups: nil, **options)
        raise ArgumentError, REMOVED_BULK_ACTIONS if options.key?(:bulk_actions)
        raise ArgumentError, GROUP_HEADER_IS_A_BLOCK if options.key?(:group_header)
        raise ArgumentError, GROUP_LABEL_NOT_CALLABLE if group_label && !group_label.respond_to?(:call)
        raise ArgumentError, COLLAPSED_WITHOUT_COLLAPSIBLE if collapsed_groups.present? && !collapsible_groups

        @form = form
        @selectable = selectable
        @select_group = select_group.presence
        @sticky_headers = sticky_headers
        @group_counts = group_counts || {}
        @group_i18n_scope = group_i18n_scope.presence
        @group_label = group_label
        @collapsible_groups = collapsible_groups
        @collapsed_groups = collapsed_groups
        @row_sequence = 0
        @tbody_options = hyphenize_keys(options.delete(:tbody) || {})
        @table_container_options = build_container_options(options.delete(:table_container) || {})
        @options = prepend_class_name(hyphenize_keys(options), TABLE_CLASSES)
      end

      # Encabezado de grupo enriquecido: el bloque recibe cada `RowGroup` al pintar la banda
      # —`value`, `rows`, `label`, `count`— y lo que devuelve reemplaza al texto de
      # `group_header_text`. Es para pintar un punto de color, el rótulo, el conteo y un
      # resumen; NO para meter controles: con `collapsible_groups:` el contenido vive dentro
      # del botón de plegado, y un botón dentro de otro es HTML inválido.
      def with_group_header(&block)
        @group_header_block = block
        self
      end

      def group_header?
        !@group_header_block.nil?
      end

      def container_id
        @options[:id] || @form&.id
      end

      # El controlador de plegado se emite solo cuando hay algo que plegar: una tabla que
      # pidió `collapsible_groups:` y al final no agrupa es una tabla plana, y sale como tal.
      # `detach_data` porque `prepend_controller` escribe en `options[:data]` en el lugar.
      def table_container_options
        return @table_container_options unless collapsible_groups? && grouped?

        prepend_controller(detach_data(@table_container_options), "table-groups")
      end

      def selectable?
        @selectable
      end

      def collapsible_groups?
        @collapsible_groups
      end

      def visible_headers
        headers.reject(&:hidden)
      end

      def grouped?
        rows.any? { |row| !row.group.nil? }
      end

      # Consecutive rows sharing the same `group:` value collapse into one
      # RowGroup. The same value reappearing later starts a fresh group — the
      # caller owns the ordering (see docs), the component never re-sorts.
      def row_groups
        rows
          .chunk_while { |previous, current| previous.group == current.group }
          .map { |run| build_row_group(run.first.group, run) }
      end

      def group_colspan
        visible_headers.count + (selectable? ? 1 : 0)
      end

      attr_reader :select_group

      # Los ids de grupo que lleva una fila, en el mismo formato de lista que las clases: el
      # de la tabla y —si la tabla agrupa— el de su grupo visual. Con los dos, la cabecera de
      # la tabla y el encabezado del grupo marcan cada uno su universo sin estorbarse.
      def selection_groups_for(group_value)
        return [] unless selectable?

        [ select_group, (group_token(group_value) if grouped?) ].compact
      end

      # Derivado del VALOR del grupo y no de su posición: la fila lo calcula sola, sin
      # depender de en qué corrida cayó. Un valor que reaparece más abajo es el mismo grupo
      # —y su seleccionar-todo marca las dos corridas, que es lo que dice la etiqueta—.
      # El digest desempata dos valores distintos que se aplanan al mismo slug ("Norte/Sur"
      # y "norte sur"); el slug está para que el DOM se pueda leer.
      def group_token(group_value)
        slug = group_value.to_s.parameterize.presence || "ungrouped"
        digest = Digest::SHA256.hexdigest(group_value.inspect)[0, 6]

        [ select_group, "group", slug, digest ].compact.join("-")
      end

      # El rótulo de la banda de grupo, resuelto AL PINTAR y no en `with_row(group:)`.
      #
      # Es lo que permite traducir un enum sin perder el conteo global (#1086): las llaves
      # de `group_counts` son las que devolvió el `GROUP BY` —crudas—, así que el valor que
      # lleva la fila tiene que seguir siendo el crudo para que `global_group_count` lo
      # encuentre. Pasar la etiqueta traducida como `group:` hacía fallar esa búsqueda y el
      # encabezado caía al conteo de la PÁGINA, que es justo lo que `group_counts` existe
      # para evitar. Con el rótulo acá, `group_token` (el seleccionar-todo del grupo)
      # también sigue derivándose del valor y no de su traducción.
      #
      # `nil` es la banda del NULL de SQL y no pasa por ninguno de los dos: ya tiene su
      # propia clave traducible, `.ungrouped`.
      def group_label(value)
        return t(".ungrouped") if value.nil?
        return @group_label.call(value).to_s if @group_label
        return I18n.t("#{@group_i18n_scope}.#{value}") if @group_i18n_scope

        value.to_s
      end

      def group_selectable?(group)
        group.rows.any?(&:selectable?)
      end

      # Group-header text. When a global count exists for the group value (from
      # `group_counts:`, typically FilterForm#group_counts), it shows the global
      # total — "Norte (30)" — and appends a partial hint when the visible run is
      # smaller than that total because pagination split the group:
      # "Norte (30) — mostrando 25". Without a global count it falls back to the
      # page-local run size (v1 behavior).
      def group_header_text(group)
        total = global_group_count(group.value)

        return t(".group_count", group: group.label, count: group.rows.size) if total.nil?

        text = t(".group_count", group: group.label, count: total)
        text += " — #{t('.group_partial', shown: group.rows.size)}" if group.rows.size < total
        text
      end

      # Lo que va en la celda de la banda: el bloque de `with_group_header` si lo hay, el
      # texto de siempre si no. `view_context.capture` y no `capture` a secas, que es como
      # ViewComponent evalúa su propio `content`: el bloque se escribió en la plantilla del
      # anfitrión y escribe en el buffer de ESA vista.
      def group_header_content(group)
        return group_header_text(group) unless group_header?

        view_context.capture(group, &@group_header_block)
      end

      def group_header_cell_options
        {
          colspan: visible_headers.count,
          class: class_names("bg-base-300 font-semibold text-sm text-base-content",
                             "border-l-4 border-l-primary" => !selectable?)
        }
      end

      # El estado inicial lo lleva el botón, no las filas: el controlador lo lee al conectar y
      # esconde las filas él. Un `hidden` puesto por el servidor sería definitivo sin JS.
      def group_collapsed?(group)
        return false unless collapsible_groups?
        return @collapsed_groups.call(group.value) if @collapsed_groups.respond_to?(:call)
        return @collapsed_groups if [ true, false, nil ].include?(@collapsed_groups)

        collapsed_values_include?(group.value)
      end

      def group_trigger_options(group)
        {
          type: "button",
          class: GROUP_TRIGGER_CLASSES,
          aria: { expanded: !group_collapsed?(group), controls: group_row_ids(group).join(" ").presence }.compact,
          data: { action: "click->table-groups#toggle", table_groups_target: "trigger",
                  group_token: group_token(group.value) }
        }
      end

      # Las filas que el botón declara controlar. Una fila `skip_tr: true` pinta su propio
      # `<tr>` y queda fuera: ni id ni plegado, el anfitrión es dueño de ese markup.
      def group_row_ids(group)
        group.rows.filter_map(&:tr_id)
      end

      # Free-form content given by the caller for the current empty situation
      # (filtered vs. truly empty), or nil to render the default EmptyState.
      def custom_empty_state_content
        @form&.active_filters? ? no_results_notification : no_records_notification
      end

      def empty_state_title
        @form&.active_filters? ? t(".no_results") : t(".no_records")
      end

      def empty_state_cta
        return if @form&.active_filters?

        new_record_link
      end

      private

      # Una fila solo puede SALIRSE de la selección. Entrar no: la columna y el
      # seleccionar-todo los pinta la tabla, así que una fila seleccionable en una tabla que
      # no lo es sería una casilla suelta con sus columnas corridas una posición.
      def row_selectable(row_option)
        return selectable? if row_option.nil?
        raise ArgumentError, ROW_SELECTABLE_WITHOUT_TABLE if row_option && !selectable?

        row_option
      end

      def build_row_group(value, run)
        RowGroup.new(value, run, group_label(value), global_group_count(value) || run.size)
      end

      def next_row_sequence
        @row_sequence += 1
      end

      # Lo que la fila necesita para plegarse —su token de grupo y el id que el botón de la
      # banda lista en `aria-controls`—, resuelto AL PINTAR como `select_groups`: `grouped?`
      # depende de todas las filas. `nil` cuando la tabla no pliega o no agrupa, y la fila
      # sale como salía.
      def collapse_attributes_for(group_value, sequence)
        return unless collapsible_groups? && grouped?

        token = group_token(group_value)
        { token: token, id: "#{row_id_prefix}-#{token}-row-#{sequence}" }
      end

      # Los ids de fila cuelgan del id del contenedor cuando lo hay, para que dos tablas
      # plegables en la misma página no se pisen. Sin él, un sufijo aleatorio —el mismo
      # recurso de `Bali::Reveal`—: un id duplicado es HTML inválido y `aria-controls`
      # apuntaría a la tabla equivocada. Con `id:` los ids son deterministas.
      def row_id_prefix
        @row_id_prefix ||= container_id || "table-#{SecureRandom.hex(3)}"
      end

      # La misma tolerancia string/símbolo de `global_group_count`: la lista la escribe el
      # anfitrión y el valor lo trae la fila, y no siempre coinciden en tipo.
      def collapsed_values_include?(value)
        values = Array(@collapsed_groups)

        values.include?(value) || (!value.nil? && values.map(&:to_s).include?(value.to_s))
      end

      # Tolerant lookup of the global total for a group value. SQL group keys are
      # often strings while record attributes may be symbols/enums, so we try the
      # raw value then its string form. nil (SQL NULL group) is looked up as-is.
      # Returns nil on a miss so the header falls back to the page-local count.
      def global_group_count(value)
        return nil if @group_counts.blank?

        if @group_counts.key?(value)
          @group_counts[value]
        elsif !value.nil? && @group_counts.key?(value.to_s)
          @group_counts[value.to_s]
        end
      end

      def build_container_options(options)
        prepend_class_name(options, container_classes)
      end

      def container_classes
        class_names(CONTAINER_CLASSES, @sticky_headers && STICKY_CLASSES)
      end

      def empty_table_row_id
        [ container_id, "empty-table-row" ].compact.join("-")
      end
    end
  end
end
