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

        def initialize(record_id: nil, skip_tr: false, bulk_actions: false, selectable: false,
                       group: nil, **options)
          @record_id = record_id
          @skip_tr = skip_tr
          @bulk_actions = bulk_actions
          @selectable = selectable
          @group = group
          @options = hyphenize_keys(options)

          if (@bulk_actions || @selectable) && @record_id.blank?
            raise IncompatibleOptions, "record_id is required when the row is selectable"
          end

          return unless @skip_tr && (@bulk_actions || @selectable)

          raise IncompatibleOptions, "skip_tr and row selection are mutually exclusive"
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
