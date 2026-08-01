# frozen_string_literal: true

module Bali
  module Table
    module Row
      class Component < ApplicationViewComponent
        class IncompatibleOptions < StandardError; end

        # La fila seleccionada se marca con fondo, no con ring: un ring se superpone a la
        # fila de al lado y el zebra de la tabla ya ocupa el fondo.
        SELECTABLE_CLASSES = "[&.selected]:bg-primary/10"

        attr_reader :group

        # @param select_label [String] Nombre del registro para el checkbox de selección. Sin
        #   él, N filas dan N controles con el MISMO nombre accesible ("Seleccionar fila") y
        #   en el rotor de formularios del lector de pantalla son indistinguibles.
        def initialize(record_id: nil, skip_tr: false, selectable: false,
                       group: nil, select_label: nil, **options)
          raise ArgumentError, Table::Component::REMOVED_BULK_ACTIONS if options.key?(:bulk_actions)

          @record_id = record_id
          @skip_tr = skip_tr
          @selectable = selectable
          @group = group
          @select_label = select_label
          @options = hyphenize_keys(options)

          return unless @selectable

          raise IncompatibleOptions, "record_id is required when the row is selectable" if @record_id.blank?
          raise IncompatibleOptions, "skip_tr and row selection are mutually exclusive" if @skip_tr
        end

        def select_label
          @select_label.present? ? t(".select_row_named", name: @select_label) : t(".select_row")
        end

        private

        # El `<tr>` ES el item del controlador: lleva el record id y la clase `selected`.
        # El checkbox de la celda solo dispara la acción; el estado vive en la fila.
        def tr_options
          return @options unless @selectable

          data = (@options[:data] || {}).merge(record_id: @record_id, bulk_actions_target: "item")
          @options.merge(data: data, class: class_names(@options[:class], SELECTABLE_CLASSES))
        end
      end
    end
  end
end
