# frozen_string_literal: true

module Bali
  module Table
    module Row
      class Component < ApplicationViewComponent
        class IncompatibleOptions < StandardError; end

        # The selected row is marked with a background, not with a ring: a ring overlaps the
        # row next to it, and the table's zebra already occupies the background.
        SELECTABLE_CLASSES = "[&.selected]:bg-primary/10"

        # Still required instead of quietly degrading the row on its own: a `record_id` that
        # arrived nil by accident would give a row nobody can check and nothing would say so.
        MISSING_RECORD_ID = "record_id is required when the row is selectable — pass " \
                            "`selectable: false` for a row that must stay out of the selection"

        attr_reader :group

        # @param select_label [String] Name of the record for the selection checkbox. Without
        #   it, N rows give N controls with the SAME accessible name ("Select row") and they
        #   are indistinguishable in the screen reader's forms rotor.
        # @param select_column [Boolean, nil] Whether the TABLE paints the selection column. A
        #   non-selectable row inside a table that is selectable still has to paint the cell,
        #   empty, or its columns shift one position. It defaults to following `selectable:`,
        #   which is what fits when the row is rendered on its own.
        # @param select_groups [Array<String>, Proc] Group ids of the select-all that reaches
        #   this row. The table builds it; a Proc because `grouped?` is not known yet when the
        #   row is declared.
        # @param collapse [Hash, Proc, nil] `{ token:, id: }` when the table folds its groups:
        #   the token the `table-groups` controller finds the row by, and the id the band
        #   lists in `aria-controls`. A Proc for the same reason as `select_groups`. `nil`
        #   leaves the row as it always was.
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

        # The table asks this so it does not paint the select-all of a group whose rows are
        # all outside the selection: it would be a control that does nothing.
        def selectable?
          @selectable
        end

        # The id of the `<tr>` this row paints: the host's if it gave one, otherwise the one
        # the table assigned to fold it. `nil` with `skip_tr`: the `<tr>` is the host's.
        def tr_id
          return if @skip_tr

          @options[:id] || collapse_attributes[:id]
        end

        private

        # The `<tr>` IS the controller's item: it carries the record id and the `selected`
        # class. The cell's checkbox only fires the action; the state lives on the row.
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

        # The token goes on the row and not only on the button: it is what the controller
        # uses to find a group's rows, without depending on them being contiguous siblings.
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
