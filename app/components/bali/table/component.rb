# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      TABLE_CLASSES = "table table-zebra min-w-full"
      CONTAINER_CLASSES = "overflow-x-auto table-component"
      STICKY_CLASSES = "overflow-visible [&_table]:overflow-x-auto " \
                       "[&_thead_tr]:sticky [&_thead_tr]:bg-base-100 [&_thead_tr]:top-[3.75rem]"

      class MissingFilterForm < StandardError; end

      # `bulk_actions:` was the array of the legacy selection, removed in v3. Without this
      # guard it would fall into `**options` and come out as an HTML attribute of the
      # `<table>`: the table would look fine, with no checkbox column and no bar, and nothing
      # would give it away.
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

      COLLAPSED_WITHOUT_COLLAPSIBLE = "Bali::Table(collapsed_groups:) needs " \
                                      "`collapsible_groups: true`: a group born folded needs " \
                                      "the trigger that unfolds it, and without the option " \
                                      "there is none."

      # `group_header:` would fall into `**options` as an attribute of the `<table>` (#1081).
      # The rich header is a block because it receives EVERY group as it paints, and a
      # ViewComponent slot is captured only once.
      GROUP_HEADER_IS_A_BLOCK = "Bali::Table(group_header:) is not an option. Declare it as " \
                                "a block — `table.with_group_header { |group| ... }` — it " \
                                "is called once per band with the group's `value`, `rows`, " \
                                "`label` and `count`."

      # The band's button is A disclosure (WAI-ARIA): `aria-expanded` carries the state and
      # `aria-controls` the rows it folds. `group/table-group` is a NAMED group so that the
      # chevron turns with this button's `aria-expanded` and not with that of any ancestor
      # `.group` (a `Bali::Reveal` around the table, for example).
      GROUP_TRIGGER_CLASSES = "group/table-group flex w-full items-center gap-2 text-left " \
                              "cursor-pointer"
      GROUP_CHEVRON_CLASSES = "shrink-0 transition-transform -rotate-90 " \
                              "group-aria-expanded/table-group:rotate-0"

      # `label` and `count` come resolved so that a `with_group_header` does not have to redo
      # the translation nor the lookup in `group_counts`: `count` is the global total when it
      # is known and the size of the run when it is not, the same as the default text shows.
      RowGroup = Struct.new(:value, :rows, :label, :count)

      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      # `selectable:` on the row WINS over the table's: `false` leaves the row out of the
      # select-all universe and paints the cell empty, so the columns stay aligned. It is the
      # "proposed, approved and withdrawn on the same page, and only the proposed ones get
      # approved in bulk" case.
      #
      # The selection groups are resolved when RENDERING, not here: `grouped?` depends on ALL
      # the rows and when this lambda runs only the previous ones exist.
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

      # @param selectable [Boolean] Checkbox + select-all column wired to the `bulk-actions`
      #   controller, which must live on some ancestor (the DataTable only adds it when
      #   `with_bulk_actions` is declared). Every row needs `record_id:`, except the ones
      #   declared `with_row(selectable: false)`.
      # @param select_group [String, nil] Narrows THIS table's select-all down to its own
      #   rows. It is what allows N tables —one per department, per branch— under a single
      #   `Bali::BulkActions`: each header checks its own and the counter stays one, the
      #   total. Without it, the header checks everything the controller can see, which with
      #   a single table is exactly the same as always.
      # @param group_i18n_scope [String, nil] Translates each group band's label as
      #   `"#{scope}.#{value}"` — the same convention as `Bali::Tag.for(i18n_scope:)`, for
      #   the case that is almost always: grouping by an enum. `group_counts` keeps its raw
      #   keys and `with_row(group:)` keeps carrying the raw value.
      # @param group_label [Proc, nil] The escape hatch, for when the label does not come from
      #   a key per value (a date, a range, an id that has to be resolved). It receives the
      #   raw value and returns the label. Wins over `group_i18n_scope:`.
      # @param collapsible_groups [Boolean] Each group band becomes a button that folds and
      #   unfolds its rows (`table-groups` controller). Without JS everything stays visible:
      #   the server never hides a row, it only marks the state on the button.
      # @param collapsed_groups [Array, Proc, true, nil] Which groups are born folded: a list
      #   of raw values (with the same string/symbol tolerance as `group_counts`), a callable
      #   over the raw value, or `true` for all of them. Requires `collapsible_groups:`.
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
        @container_id = options.delete(:id)
        @tbody_options = hyphenize_keys(options.delete(:tbody) || {})
        @table_container_options = build_container_options(options.delete(:table_container) || {})
        @options = prepend_class_name(hyphenize_keys(options), TABLE_CLASSES)
      end

      # Rich group header: the block receives each `RowGroup` as the band is painted
      # —`value`, `rows`, `label`, `count`— and what it returns replaces the
      # `group_header_text` text. It is for painting a colour dot, the label, the count and a
      # summary; NOT for putting controls in: with `collapsible_groups:` the content lives
      # inside the folding button, and a button inside another is invalid HTML.
      def with_group_header(&block)
        @group_header_block = block
        self
      end

      def group_header?
        !@group_header_block.nil?
      end

      # The id identifies the COMPONENT, and the component's root is the `<div class="table-component">`
      # that wraps the `<table>` — the `**options` convention of
      # docs/reference/component-patterns.md. That is why `initialize` TAKES it out of `options`: it
      # is the only key that does not go down to the `<table>`. Emitting it on both elements was
      # invalid HTML and `getElementById` returned the `<div>` anyway, the first one in document
      # order (#1157).
      # `row_id_prefix` and `empty_table_row_id` also hang off this id, and it is what a
      # `turbo_stream.replace` has to replace: the `<table>` on its own would leave out the
      # `overflow-x-auto` and the collapsible groups' `data-controller`. The container's own
      # attributes go in `table_container:` —classes and data, not the identity: an `id:` there wins
      # the `<div>`'s attribute but does not reach here, so the derived ids do not change—;
      # with `form:` this already worked this way.
      def container_id
        @container_id || @form&.id
      end

      # The folding controller is emitted only when there is something to fold: a table that
      # asked for `collapsible_groups:` and ends up not grouping is a flat table, and comes out
      # as one. `detach_data` because `prepend_controller` writes into `options[:data]` in
      # place.
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

      # The group ids a row carries, in the same list format as the classes: the table's and
      # —if the table groups— that of its visual group. With both, the table header and the
      # group header each check their own universe without getting in each other's way.
      def selection_groups_for(group_value)
        return [] unless selectable?

        [ select_group, (group_token(group_value) if grouped?) ].compact
      end

      # Derived from the group's VALUE and not from its position: the row computes it on its
      # own, without depending on which run it fell into. A value that reappears further down
      # is the same group —and its select-all checks both runs, which is what the label says—.
      # The digest breaks the tie between two different values that flatten to the same slug
      # ("Norte/Sur" and "norte sur"); the slug is there so the DOM can be read.
      def group_token(group_value)
        slug = group_value.to_s.parameterize.presence || "ungrouped"
        digest = Digest::SHA256.hexdigest(group_value.inspect)[0, 6]

        [ select_group, "group", slug, digest ].compact.join("-")
      end

      # The group band's label, resolved WHEN PAINTING and not in `with_row(group:)`.
      #
      # It is what allows translating an enum without losing the global count (#1086): the keys
      # of `group_counts` are the ones the `GROUP BY` returned —raw—, so the value the row
      # carries has to stay the raw one for `global_group_count` to find it. Passing the
      # translated label as `group:` made that lookup fail and the header fell back to the
      # PAGE count, which is exactly what `group_counts` exists to avoid. With the label here,
      # `group_token` (the group's select-all) also keeps being derived from the value and not
      # from its translation.
      #
      # `nil` is SQL NULL's band and goes through neither of the two: it already has its own
      # translatable key, `.ungrouped`.
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

      # What goes in the band's cell: the `with_group_header` block if there is one, the usual
      # text if not. `view_context.capture` and not bare `capture`, which is how ViewComponent
      # evaluates its own `content`: the block was written in the host's template and writes
      # into THAT view's buffer.
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

      # The initial state is carried by the button, not the rows: the controller reads it on
      # connect and hides the rows itself. A `hidden` put there by the server would be final
      # without JS.
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

      # The rows the button declares it controls. A `skip_tr: true` row paints its own `<tr>`
      # and stays out: no id and no folding, the host owns that markup.
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

      # A row can only OPT OUT of the selection. Not in: the column and the select-all are
      # painted by the table, so a selectable row in a table that is not selectable would be a
      # stray checkbox with its columns shifted one position.
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

      # What the row needs in order to fold —its group token and the id the band's button
      # lists in `aria-controls`—, resolved WHEN PAINTING like `select_groups`: `grouped?`
      # depends on all the rows. `nil` when the table does not fold or does not group, and the
      # row comes out as it used to.
      def collapse_attributes_for(group_value, sequence)
        return unless collapsible_groups? && grouped?

        token = group_token(group_value)
        { token: token, id: "#{row_id_prefix}-#{token}-row-#{sequence}" }
      end

      # Row ids hang off the container id when there is one, so that two collapsible tables on
      # the same page do not clash. Without it, a random suffix —the same device as
      # `Bali::Reveal`—: a duplicate id is invalid HTML and `aria-controls` would point at the
      # wrong table. With `id:` the ids are deterministic.
      def row_id_prefix
        @row_id_prefix ||= container_id || "table-#{SecureRandom.hex(3)}"
      end

      # The same string/symbol tolerance as `global_group_count`: the list is written by the
      # host and the value comes from the row, and they do not always match in type.
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
