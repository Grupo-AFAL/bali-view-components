# frozen_string_literal: true

module Bali
  class FilterForm
    # Does NOT inherit from `ActiveRecord::StatementInvalid` on purpose: a generic
    # `rescue_from` over database errors would swallow the message this class exists to
    # deliver. The adapter's own error stays reachable as `#cause`.
    class GroupByOrderingError < StandardError; end

    # GroupByConfiguration provides DSL and methods for query-aware row grouping.
    #
    # Grouping is driven by a whitelisted top-level `group_by` param (NOT a
    # `q[...]` Ransack predicate). When APPLIED (see {#group_by_applied}) it:
    #   1. orders the query by the group field FIRST (user column sorts become
    #      secondary, giving sort-within-groups), and
    #   2. exposes GLOBAL per-group counts over the full filtered (unpaginated)
    #      result via {#group_counts}.
    #
    # Three different questions, three predicates — confusing them is THE bug of this module:
    #   * STATE       — {#group_by} / {#group_by_active?}: is there a chosen grouping?
    #     Drives PRESERVATION (hidden fields, cache, saved view payloads).
    #   * MODE        — {#group_by_applies?}: does this display mode apply grouping?
    #     Drives the VISIBILITY of the control.
    #   * APPLICATION — {#group_by_applied} / {#group_by_applied?}: is it applying right now?
    #     Drives ordering, counts and group bands.
    #
    # And an ORIGIN, which is not a fourth state but where the current one came from:
    #   * ORIGIN      — {#group_by_from_default?}: a default is DERIVED. It is never written
    #     to the URL, the filter cache or a saved view payload, so only what the user chose
    #     is preserved.
    #
    # Precedence, top to bottom (resolved in {Bali::FilterForm#initialize}):
    #   1. `?group_by=` in the URL, empty included — it has to beat the default or the user
    #      cannot ungroup;
    #   2. an applied saved view payload (`?saved_view=`): the `group_by` key PRESENT is the
    #      view speaking, even valued {GroupByConfiguration::NO_GROUPING_VALUE}; the key
    #      ABSENT is silence and lets the default speak;
    #   3. the choice stored in the persistence cache (`group_by_chosen` tells an explicit
    #      "no grouping" apart from "nobody said anything");
    #   4. the `default: true` declaration;
    #   5. no grouping.
    #
    # Security boundary: the raw param NEVER reaches `.group()`/`.order()`.
    # {#resolve_group_by} returns the declared symbol only when the raw value
    # matches a declared attribute; anything else resolves to nil. Ransack does
    # not authorize `.group`, so this whitelist is the only gate.
    #
    # @example Class-level DSL
    #   class MoviesFilterForm < Bali::FilterForm
    #     group_by_attribute :genre, label: "Género"
    #     group_by_attribute :status
    #   end
    #
    # @example Instance-level configuration
    #   FilterForm.new(Movie.all, params, group_by_attributes: [:genre, :status])
    #
    # Grouping accepts the SAME thing sorting does —a column, a `ransacker` or an association
    # path—, because the `GROUP BY` comes out of the same Arel as the `ORDER BY` (see
    # {#group_by_expression}). Reading a row's band is the other half, and it is a Ruby
    # question, not a SQL one: {#group_value_for}.
    #
    module GroupByConfiguration
      extend ActiveSupport::Concern

      # Display modes where grouping is APPLIED. A table is the only surface of contiguous
      # rows where a group band means something: over cards or a timeline the same ordering
      # acts INVISIBLY, rearranging the content with nothing on screen to explain it.
      DEFAULT_GROUP_BY_MODES = %i[table].freeze

      # How "no grouping" travels once the listing declares a `default:` (#1156). An empty
      # `?group_by=` cannot carry it: Ransack's `sort_link` DROPS empty params while composing
      # the href (measured: `group_by=genre` survives it, `group_by=` disappears), and so do
      # the hidden fields of both filter forms. A saved view payload has no way to store a nil
      # either. Any undeclared value already means "no grouping" ({#resolve_group_by}); this
      # only gives it a spelling that survives transport.
      NO_GROUPING_VALUE = "none"

      class_methods do
        # Storage for group_by attribute definitions
        def defined_group_by_attributes
          @defined_group_by_attributes ||= []
        end

        # Declare an attribute users can group rows by.
        #
        # Accepts the SAME thing sorting does: a real column, a `ransacker` or an association
        # path (`worker_legal_entity_name`). The `GROUP BY` comes out of the same Arel Ransack
        # gives the `ORDER BY`, so the two halves of a grouping —the order that brings the rows
        # together and the count that counts them— cannot fall out of sync (#1102).
        #
        # @param attribute [Symbol] Column, ransacker or association path
        # @param label [String, nil] Human-readable label (defaults to inferred)
        # @param sql [String, Arel::Nodes::Node, Proc, nil] Explicit expression for the
        #   GROUP BY, for what neither a column nor a ransacker can say. A String goes through
        #   `Arel.sql`: it is the developer's SQL, never the user's. When declared it ALSO
        #   rules the ORDER BY (see {#apply_group_by_sql_order}), because a grouping ordered by
        #   an expression other than the one it groups by brings nothing together.
        # @param value [Proc, nil] How to read ONE row's band (see {#group_value_for}).
        #   Defaults to `record.public_send(attribute)`, which for an association path
        #   (`worker_legal_entity_id`) is a NoMethodError — hence this hook. It has to return
        #   the SAME value the GROUP BY returned: the global count lookup is by value (see
        #   {#group_counts} and Bali::Table#global_group_count).
        # @param default [Boolean] Open the listing grouped by this attribute when nobody
        #   said anything (#1156). Only one declaration may carry it. A boolean and not a
        #   callable: the default is resolved while the form is built, with no instance to
        #   evaluate against — the same limitation {DefaultFilters} documents. It is DERIVED,
        #   never written to the filter cache or a saved view payload, so changing it here
        #   changes what users who already visited the listing see.
        def group_by_attribute(attribute, label: nil, sql: nil, value: nil, default: false)
          defined_group_by_attributes << {
            attribute: attribute.to_sym, label: label, sql: sql, value: value, default: default
          }
        end

        # Inherit group_by attributes from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_group_by_attributes, defined_group_by_attributes.dup)
        end
      end

      # Normalized group_by definitions ({attribute:, label:, sql:, value:, default:}).
      # Prefers instance-level configuration over the class DSL. Validating here and not in
      # `group_by_attribute` is the only thing possible: the model comes in with the scope,
      # that is, only when the form is built.
      #
      # @return [Array<Hash>]
      def group_by_definitions
        @group_by_definitions ||= begin
          definitions = normalize_group_by_attributes(
            @instance_group_by_attributes.presence || self.class.defined_group_by_attributes
          )
          validate_single_group_by_default!(definitions)
          definitions
        end
      end

      # Declared group_by attribute names (the whitelist).
      #
      # @return [Array<Symbol>]
      def group_by_attributes
        group_by_definitions.map { |definition| definition[:attribute] }
      end

      # Whether grouping is available (any attribute declared).
      #
      # @return [Boolean]
      def group_by_enabled?
        group_by_definitions.present?
      end

      # The active group_by attribute (declared symbol) or nil.
      #
      # @return [Symbol, nil]
      def group_by
        @group_by
      end

      # Whether a valid group_by is currently active (STATE).
      #
      # @return [Boolean]
      def group_by_active?
        !@group_by.nil?
      end

      # @return [Symbol, nil] the attribute declared `default: true` (#1156)
      def default_group_by
        return @default_group_by if defined?(@default_group_by)

        @default_group_by = group_by_definitions.find { |definition| definition[:default] }
                                                &.fetch(:attribute)
      end

      # Gates PRESERVATION: writing a re-derived default to the URL, the cache or a view
      # payload would turn it into the choice it is not.
      #
      # @return [Boolean]
      def group_by_from_default?
        @group_by_from_default == true
      end

      # How THIS listing spells "no grouping": empty while there is no default (what the
      # control has emitted since #634), {NO_GROUPING_VALUE} once there is one.
      #
      # @return [String]
      def no_grouping_value
        default_group_by ? NO_GROUPING_VALUE : ""
      end

      # What the user chose, spelled so it survives transport, or nil when there is nothing
      # to preserve. Both surfaces that carry the choice outside the form — a GET submit's
      # hidden field and a saved view payload — must use this same value, or the link and the
      # submit would say different things.
      #
      # @return [String, nil]
      def group_by_preserved_value
        return @group_by.to_s if group_by_active? && !group_by_from_default?
        return no_grouping_value if !group_by_active? && default_group_by

        nil
      end

      # Does grouping APPLY in the current display mode? It asks about the MODE, not about the
      # state: it is true on the table even when nobody chose to group. With no mode (a listing
      # with no view switch, or one that does not yet know which one it renders) it applies,
      # which is the case for the vast majority; a listing whose default view is NOT the table
      # has to pass that mode to the form (see FilterForm#initialize's `display_mode:`).
      #
      # `[]` short-circuits first: it is the way to say "no mode applies it", and the "with no
      # mode it applies" escape would have turned it back on for every URL without `?view=`.
      #
      # @return [Boolean]
      def group_by_applies?
        return false if group_by_modes.empty?

        @display_mode.nil? || group_by_modes.include?(@display_mode)
      end

      # The grouping that is being APPLIED (or nil): it rules ordering, counts and bands.
      # Outside a mode that applies it, it is nil EVEN THOUGH {#group_by} is still chosen —
      # that is the suspension. Derived and not `@group_by = nil` on purpose: the state has to
      # survive in the URL, in the filter cache and in a saved view's payload.
      #
      # @return [Symbol, nil]
      def group_by_applied
        group_by_applies? ? @group_by : nil
      end

      # @return [Boolean]
      def group_by_applied?
        !group_by_applied.nil?
      end

      # There is a chosen grouping but this mode does not apply it. Sugar so that the host can
      # explain it ("Grouped by Genre — applies in the table view").
      #
      # @return [Boolean]
      def group_by_suspended?
        group_by_active? && !group_by_applies?
      end

      # Display modes that apply the grouping, normalized to symbols.
      #
      # `nil` and `[]` are NOT the same, so `.presence` cannot be used: `[]` is a host saying
      # "no mode applies it" (it wants the param in saved views but never applied) and
      # collapsing it to the default gave it exactly the opposite, in silence.
      #
      # @return [Array<Symbol>]
      def group_by_modes
        @group_by_modes ||= begin
          declared = @instance_group_by_modes.nil? ? DEFAULT_GROUP_BY_MODES : @instance_group_by_modes
          Array(declared).map(&:to_sym)
        end
      end

      # Options for the "Group by" UI control, labels resolved.
      #
      # @return [Array<Hash>] each {attribute:, label:}
      def group_by_options
        group_by_definitions.map do |definition|
          {
            attribute: definition[:attribute],
            label: definition[:label] || infer_group_by_label(definition[:attribute])
          }
        end
      end

      # Global per-group counts over the FULL filtered (unpaginated) result.
      # Independent of Pagy — the controller paginates the relation, this counts
      # the whole query. `unscope(:order)` is required because ORDER BY conflicts
      # with GROUP BY under strict SQL modes.
      #
      # Keys are whatever SQL returns (strings, enum labels, nil). Returns {}
      # when grouping is inactive OR suspended (see {#group_by_applied}).
      #
      # @return [Hash] value => Integer count
      def group_counts
        return {} unless group_by_applied?

        @group_counts ||= begin
          relation = result.unscope(:order)
          relation.group(group_by_expression).count
        end
      end

      # The expression the `GROUP BY` runs over, or nil when no grouping is applied. Three
      # origins, in order:
      #
      #   1. the declared `sql:`, when there is one;
      #   2. the Arel Ransack gives the ORDER BY — which is what makes a `ransacker` or an
      #      association path group, and not just sort (#1102). The join is already in the
      #      relation: the grouping is prepended as a sort BEFORE `result` is evaluated, so by
      #      the time this runs Ransack has already built it and the bind is memoized;
      #   3. the bare symbol, which is what v3.1 did: a real column the host did not put in
      #      `ransackable_attributes` keeps grouping as always.
      #
      # @return [Arel::Nodes::Node, Arel::Attributes::Attribute, Symbol, nil]
      def group_by_expression
        return nil unless group_by_applied?

        @group_by_expression ||=
          explicit_group_by_sql(group_by_applied) ||
          ransack_group_by_expression(group_by_applied) ||
          group_by_applied
      end

      # The band ONE row belongs to under the applied grouping, or nil when there is none (off
      # or suspended) — that is, exactly what goes in `with_row(group:)`.
      #
      # The default is `record.public_send(attribute)`, which is enough for a column and for a
      # ransacker with a twin in Ruby. For an association path NO such method exists and that
      # is why the declaration can carry a `value:`; the validation does not let through the
      # case where there is neither, so the NoMethodError does not show up only while painting.
      #
      # @param record [Object] the row's record
      # @return [Object, nil] the group's RAW value (the same as the group_counts key)
      def group_value_for(record)
        applied = group_by_applied
        return nil if applied.nil?

        reader = group_by_definition_for(applied)[:value]
        return reader.call(record) if reader.respond_to?(:call)

        record.public_send(applied)
      end

      private

      # Resolve the raw param to a declared attribute symbol, or nil.
      # This is the security boundary: the returned symbol always comes from the
      # whitelist, never from the raw param.
      #
      # Touches `group_by_definitions` BEFORE the `blank?`, and on purpose: that is where the
      # declarations are validated, and this runs on initialize whether the param comes or not.
      # The other way around, a broken declaration was only discovered when somebody picked
      # that grouping on screen — the boot-time contract `input:` and `auto_submit:` already
      # have (#1102).
      def resolve_group_by(raw_value)
        return nil if group_by_definitions.empty?
        return nil if raw_value.blank?

        group_by_attributes.find { |attribute| attribute.to_s == raw_value.to_s }
      end

      # The question is `@group_by_chosen` and not `@group_by.nil?`: "no grouping" is a
      # choice that leaves the state nil and has to survive the default. Runs AFTER
      # persistence, or the default would enter `fetch_stored_filter_state` as if the user
      # had picked it and be written to the cache on the first filter submit (#1156).
      def apply_default_group_by
        return if @group_by_chosen
        return unless @group_by.nil?

        default = default_group_by
        return if default.nil?

        @group_by = default
        @group_by_from_default = true
      end

      # Prepend the group field as the primary sort so rows cohere into groups,
      # keeping any user column sort as the secondary sort (sort-within-groups).
      # Ransack whitelists sort columns, so building the `s` array is safe.
      #
      # Gated by APPLICATION and not by state: over cards this ordering would rearrange the
      # content with no group band to explain it.
      def apply_group_by_ordering(params)
        applied = group_by_applied
        return params if applied.nil?
        return params if group_by_definition_for(applied)[:sql]

        existing_sort = Array(params["s"]).compact_blank
        params["s"] = [ "#{applied} asc", *existing_sort ]
        params
      end

      # The ORDER BY of a grouping with an explicit `sql:`, which Ransack cannot build: its `s`
      # param only speaks of names, and an expression has no name. It is applied over the
      # already-evaluated relation, prepending the SAME expression that groups and keeping the
      # user's order behind it (sort-within-groups, just like the other half).
      def apply_group_by_sql_order(relation)
        return relation unless group_by_applied?
        return relation unless group_by_definition_for(group_by_applied)[:sql]

        relation.reorder(Arel::Nodes::Ascending.new(group_by_expression), *relation.order_values)
      end

      # Grouping ORDERS BY the group expression, and over a scope with `SELECT DISTINCT`
      # Postgres requires every ORDER BY expression to appear in the select list (#1156).
      # Three of the four ways to group do not — measured in the dummy:
      #
      #   genre       -> ORDER BY "movies"."genre" ASC                  (in movies.*)
      #   studio_name -> ORDER BY "tenants"."name" ASC                  (absent)
      #   budget_band -> ORDER BY CASE WHEN "movies"."budget" ... END   (absent)
      #   budgeted    -> ORDER BY CASE WHEN movies.budget IS NULL ...   (absent)
      #
      # It cannot be detected up front without false positives: a host that already wrote
      # `.select("movies.*", "tenants.name")` runs fine, and sqlite and MySQL without
      # ONLY_FULL_GROUP_BY accept all four. The module goes on the relation and not around a
      # call because Bali does not materialize it — the host writes `pagy(form.result)` — and
      # `extending` survives the spawns pagy chains.
      def apply_group_by_diagnostics(relation)
        return relation unless group_by_applied?
        return relation unless relation.respond_to?(:extending)

        relation.extending(group_by_diagnostics_module)
      end

      def group_by_diagnostics_module
        form = self

        @group_by_diagnostics_module ||= Module.new do
          define_method(:exec_queries) do |&block|
            super(&block)
          rescue ActiveRecord::StatementInvalid => e
            translated = form.send(:translate_group_by_ordering_error, e)
            raise translated if translated

            raise
          end
        end
      end

      # PostgreSQL and MySQL say the same thing in different words.
      DISTINCT_ORDER_CONFLICT = /
        for\ SELECT\ DISTINCT,\ ORDER\ BY\ expressions\ must\ appear\ in\ select\ list
        | incompatible\ with\ DISTINCT
      /xi

      def translate_group_by_ordering_error(error)
        return nil unless group_by_applied?
        return nil unless error.message.match?(DISTINCT_ORDER_CONFLICT)

        GroupByOrderingError.new(group_by_ordering_error_message)
      end

      def group_by_ordering_error_message
        listing = [ self.class.name, storage_id.presence && %(listing "#{storage_id}") ]
                  .compact.join(", ")

        "#{listing}: the database rejected the ORDER BY that grouping by " \
          ":#{group_by_applied} adds over a scope with SELECT DISTINCT " \
          "(ORDER BY #{group_by_ordering_expression_sql}). A SELECT DISTINCT only accepts " \
          "ORDER BY expressions that appear in its select list, and an association path, a " \
          "ransacker or a `sql:` expression never does. Three ways out: drop the `.distinct` " \
          "from the scope this form filters (deduplicate the join with a subquery — " \
          "`where(id: inner.select(:id))` — instead); add the expression to the select list " \
          "yourself (`scope.select(\"movies.*\", \"tenants.name\")`), knowing it changes WHAT " \
          "gets deduplicated; or group by a column of the base table, the only shape always " \
          "present in `SELECT DISTINCT movies.*`. The adapter's own error is this one's cause."
      end

      # Wrapping in `Arel::Nodes::Ascending` is both what makes this byte-identical to the
      # fragment the adapter rejected and the only thing that compiles: two of the four
      # grouping shapes return an `Arel::Attributes::Attribute`, which does NOT respond to
      # `to_sql`, and falling back to `to_s` printed a Struct's inspect of the whole model
      # into the message (1726 characters for `genre`). For the message, never for the query.
      def group_by_ordering_expression_sql
        expression = group_by_expression
        return expression.to_s if expression.nil? || expression.is_a?(Symbol)

        Arel::Nodes::Ascending.new(expression).to_sql(group_by_model || Arel::Table.engine)
      rescue StandardError
        group_by_applied.to_s
      end

      # The declared `sql:`, resolved. A String is wrapped in `Arel.sql` — it comes from the
      # developer's declaration, never from the URL (the raw param does not reach here: see
      # {#resolve_group_by}).
      def explicit_group_by_sql(attribute)
        sql = group_by_definition_for(attribute)[:sql]
        return nil if sql.nil?

        expression = resolve_definition_value(sql)
        expression.is_a?(String) ? Arel.sql(expression) : expression
      end

      # The Arel Ransack uses to SORT by this name. It is literally the sort node the grouping
      # already prepends, rebuilt against the SAME context: the binds are memoized, so it adds
      # neither an extra join nor a different alias. nil when the name is not sortable by
      # Ransack (a column outside `ransackable_attributes`), which is when it falls back to the
      # bare symbol of always.
      def ransack_group_by_expression(attribute)
        sort = Ransack::Nodes::Sort.extract(ransack_search.context, attribute.to_s)
        sort&.valid? ? sort.attr : nil
      end

      def group_by_definition_for(attribute)
        group_by_definitions.find { |definition| definition[:attribute] == attribute } || {}
      end

      def normalize_group_by_attributes(attributes)
        attributes.map do |attribute|
          definition =
            if attribute.is_a?(Hash)
              { attribute: attribute[:attribute].to_sym, label: attribute[:label],
                sql: attribute[:sql], value: attribute[:value], default: attribute[:default] }
            else
              { attribute: attribute.to_sym, label: nil, sql: nil, value: nil, default: false }
            end

          validate_group_by_default!(definition)
          validate_group_by_definition!(definition)
          definition
        end
      end

      # A callable here would be TRUTHY and become the default without anyone evaluating it.
      def validate_group_by_default!(definition)
        default = definition[:default]
        return if default.nil? || default == true || default == false

        raise ArgumentError,
              "group_by_attribute :#{definition[:attribute]}: `default:` takes true or false, " \
              "not #{default.class}. The grouping default is resolved while the form is built, " \
              "so there is no instance to evaluate a callable against — pick the band the " \
              "listing opens on in the declaration, or set `@group_by` yourself after `super`."
      end

      # The `uniq`: the SAME attribute declared twice — a subclass repeating its parent's —
      # is still one default, and not the contradiction this raises on.
      def validate_single_group_by_default!(definitions)
        defaults = definitions.select { |definition| definition[:default] }
                              .map { |definition| definition[:attribute] }.uniq
        return if defaults.size <= 1

        raise ArgumentError,
              "group_by_attribute: #{defaults.map { |a| ":#{a}" }.join(' and ')} are both " \
              "declared `default: true`, so the listing would have two bands to open on. " \
              "A listing opens on ONE question: keep the default on a single declaration."
      end

      # Blows up when the form is BUILT, not when somebody picks the grouping on screen. Up to
      # v3.1 `group_by_attribute :lo_que_sea` was accepted without complaint and the symbol
      # reached the SQL raw: `PG::UndefinedColumn` in production, over a screen that had loaded
      # fine a thousand times (#1102).
      #
      # The two halves are checked separately because they fail separately: a grouping can have
      # a perfect GROUP BY and have no way to read a row's band.
      def validate_group_by_definition!(definition)
        model = group_by_model
        return if model.nil?

        attribute = definition[:attribute]
        validate_group_by_expression!(model, definition, attribute)
        validate_group_by_reader!(model, definition, attribute)
      end

      def validate_group_by_expression!(model, definition, attribute)
        return if definition[:sql]
        return if group_by_resolvable?(model, attribute)

        raise ArgumentError,
              "group_by_attribute :#{attribute}: #{model.name} has no column, ransacker or " \
              "reachable association path by that name, so the GROUP BY would reach the " \
              "database as a bare identifier and fail there. Declare a ransacker on the " \
              "model, use the association path Ransack already sorts by, or pass `sql:`."
      end

      def validate_group_by_reader!(model, definition, attribute)
        return if definition[:value]
        return if model.column_names.include?(attribute.to_s)
        return if model.method_defined?(attribute)

        raise ArgumentError,
              "group_by_attribute :#{attribute}: the GROUP BY resolves but a row cannot be " \
              "read — #{model.name} answers no `##{attribute}`, so each row's band would " \
              "raise NoMethodError while painting. Pass `value:` (e.g. " \
              "`value: ->(record) { record.worker&.legal_entity_id }`)."
      end

      # A real column first: it is what v3.1 accepted and still holds even when the host leaves
      # it out of `ransackable_attributes` (it groups; what it does not do is sort). Then,
      # whatever Ransack can resolve — ransackers and association paths —, with the SAME
      # authorization that applies when sorting.
      def group_by_resolvable?(model, attribute)
        return true if model.column_names.include?(attribute.to_s)

        group_by_probe_context.attribute_method?(attribute.to_s)
      end

      # Read-only context for validating names. Deliberately NOT `ransack_search`'s: that one
      # does not exist yet when the form is built (it depends on the attributes initialize
      # assigns at the end) and binding against it would add joins for a mere check.
      # `attribute_method?` walks associations without building any.
      def group_by_probe_context
        @group_by_probe_context ||= Ransack::Context.for(scope)
      end

      # The model the declarations are validated against, or nil when the scope is not an
      # ActiveRecord relation: with no model there is nothing to check and the validation is
      # skipped entirely.
      def group_by_model
        return scope.model if scope.respond_to?(:model)
        return scope if scope.is_a?(Class) && scope.respond_to?(:ransack)

        nil
      end

      # Infer a label from the attribute name using I18n or humanization,
      # mirroring SimpleFiltersConfiguration#infer_simple_filter_label.
      def infer_group_by_label(attribute)
        if respond_to?(:scope) && scope.respond_to?(:model)
          model_name = scope.model.model_name.i18n_key
          translated = I18n.t("activerecord.attributes.#{model_name}.#{attribute}", default: nil)
          return translated if translated
        end

        attribute.to_s.humanize
      end
    end
  end
end
