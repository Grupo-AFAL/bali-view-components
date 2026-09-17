# frozen_string_literal: true

module Bali
  module Table
    module Row
      class Component < ApplicationViewComponent
        class IncompatibleOptions < StandardError; end

        # La fila seleccionada se marca con fondo, no con ring: un ring se superpone a la
        # fila de al lado y el zebra de la tabla ya ocupa el fondo.
        SELECTABLE_CLASSES = "[&.selected]:bg-primary/10"

        # Se sigue exigiendo en vez de degradar la fila sola: un `record_id` que llegó nil por
        # accidente daría una fila que nadie puede marcar y nada lo diría.
        MISSING_RECORD_ID = "record_id is required when the row is selectable — pass " \
                            "`selectable: false` for a row that must stay out of the selection"

        attr_reader :group

        # @param select_label [String] Nombre del registro para el checkbox de selección. Sin
        #   él, N filas dan N controles con el MISMO nombre accesible ("Seleccionar fila") y
        #   en el rotor de formularios del lector de pantalla son indistinguibles.
        # @param select_column [Boolean, nil] Si la TABLA pinta la columna de selección. Una
        #   fila no seleccionable dentro de una tabla que sí lo es tiene que pintar la celda
        #   igual, vacía, o sus columnas se corren una posición. Por default sigue a
        #   `selectable:`, que es lo que corresponde cuando la fila se renderiza suelta.
        # @param select_groups [Array<String>, Proc] Ids de grupo del seleccionar-todo que
        #   alcanza a esta fila. Lo arma la tabla; un Proc porque `grouped?` no se sabe
        #   todavía cuando la fila se declara.
        # @param collapse [Hash, Proc, nil] `{ token:, id: }` cuando la tabla pliega sus
        #   grupos: el token con el que el controlador `table-groups` encuentra la fila y el
        #   id que la banda lista en `aria-controls`. Un Proc por la misma razón que
        #   `select_groups`. `nil` deja la fila como siempre.
        def initialize(record_id: nil, skip_tr: false, selectable: false, select_column: nil,
                       select_groups: [], collapse: nil, group: nil, select_label: nil, **options)
          raise ArgumentError, Table::Component::REMOVED_BULK_ACTIONS if options.key?(:bulk_actions)

          @record_id = record_id
          @skip_tr = skip_tr
          @selectable = selectable
          @select_column = select_column.nil? ? selectable : select_column
          @select_groups = select_groups
          @collapse = collapse
          @group = group
          @select_label = select_label
          @options = hyphenize_keys(options)

          return unless @selectable

          raise IncompatibleOptions, MISSING_RECORD_ID if @record_id.blank?
          raise IncompatibleOptions, "skip_tr and row selection are mutually exclusive" if @skip_tr
        end

        def select_label
          @select_label.present? ? t(".select_row_named", name: @select_label) : t(".select_row")
        end

        # La tabla lo pregunta para no pintar el seleccionar-todo de un grupo cuyas filas
        # están todas fuera de la selección: sería un control que no hace nada.
        def selectable?
          @selectable
        end

        # El id del `<tr>` que pinta esta fila: el del anfitrión si lo dio, el que asignó la
        # tabla para plegarla si no. `nil` con `skip_tr`: el `<tr>` es del anfitrión.
        def tr_id
          return if @skip_tr

          @options[:id] || collapse_attributes[:id]
        end

        private

        # El `<tr>` ES el item del controlador: lleva el record id y la clase `selected`.
        # El checkbox de la celda solo dispara la acción; el estado vive en la fila.
        def tr_options
          return @options unless @selectable || collapse_attributes.any?

          options = @options.merge(data: (@options[:data] || {}).merge(collapse_data, selection_data))
          options[:id] ||= collapse_attributes[:id] if collapse_attributes[:id]
          options[:class] = class_names(options[:class], SELECTABLE_CLASSES) if @selectable
          options
        end

        def selection_data
          return {} unless @selectable

          { record_id: @record_id, bulk_actions_target: "item",
            bulk_actions_group: select_groups.presence&.join(" ") }
        end

        # El token va en la fila y no solo en el botón: es lo que el controlador usa para
        # encontrar las filas de un grupo, sin depender de que sean hermanas contiguas.
        def collapse_data
          return {} if collapse_attributes.empty?

          { table_groups_target: "row", group_token: collapse_attributes[:token] }
        end

        def select_groups
          @select_groups.respond_to?(:call) ? Array(@select_groups.call) : Array(@select_groups)
        end

        def collapse_attributes
          @collapse_attributes ||= (@collapse.respond_to?(:call) ? @collapse.call : @collapse) || {}
        end
      end
    end
  end
end
